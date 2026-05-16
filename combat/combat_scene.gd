extends Control

const PLAYER_STARTING_HEALTH := 15
const BOSS_STARTING_HEALTH := 12
const ACTIVE_BOARD_CAP := 4
const STARTING_BACKPACK_CAPACITY := 1
const CARD_VIEW_SCENE = preload("res://cards/card_view.tscn")

@onready var player_health_label = $RootLayout/TopBar/PlayerHealthLabel
@onready var boss_health_label = $RootLayout/TopBar/BossHealthLabel
@onready var round_label = $RootLayout/TopBar/RoundLabel
@onready var gold_label = $RootLayout/TopBar/GoldLabel
@onready var status_label = $RootLayout/TopBar/StatusLabel

@onready var board_card_list = $RootLayout/PlayArea/BoardCenter/BoardSection/BoardCardList

@onready var left_hand_label = $RootLayout/PlayArea/LoadoutCenter/LoadoutGroup/LabelRow/LeftHandLabel
@onready var right_hand_label = $RootLayout/PlayArea/LoadoutCenter/LoadoutGroup/LabelRow/RightHandLabel
@onready var backpack_label = $RootLayout/PlayArea/LoadoutCenter/LoadoutGroup/LabelRow/BackpackLabel
@onready var take_first_monster_button = $RootLayout/ButtonBar/TakeFirstMonsterButton
@onready var move_first_to_left_hand_button = $RootLayout/ButtonBar/MoveFirstToLeftHandButton
@onready var move_first_to_backpack_button = $RootLayout/ButtonBar/MoveFirstToBackpackButton

var match_state: MatchCombatState
var resolution_controller: ResolutionController
var outcome_controller: OutcomeController
var combat_controller: CombatController


func _ready() -> void:
    _build_test_match_state()

    take_first_monster_button.pressed.connect(_on_take_first_monster_pressed)
    move_first_to_left_hand_button.pressed.connect(_on_move_first_to_left_hand_pressed)
    move_first_to_backpack_button.pressed.connect(_on_move_first_to_backpack_pressed)
    set_status("Ready.")

    _refresh_ui()



func _build_test_match_state() -> void:
    var loader = GameDataLoader.new()
    loader.build_card_registry()

    var starter_deck := loader.load_deck("res://data/decks/starter_knight_deck.json")
    var resolved_player_cards := loader.resolve_deck_cards(starter_deck)

    var monster_deck := loader.load_deck("res://data/decks/ossara_baseline_monster_deck.json")
    var resolved_monster_cards := loader.resolve_monster_deck(monster_deck)

    var merged_cards := loader.build_shared_deck(resolved_player_cards, resolved_monster_cards)

    var shared_deck := SharedDeckState.new()
    shared_deck.setup(merged_cards)

    var board_state := BoardState.new()
    board_state.setup(ACTIVE_BOARD_CAP)
    board_state.refill_from_deck(shared_deck)

    var player_state := PlayerCombatState.new()
    player_state.setup(PLAYER_STARTING_HEALTH, STARTING_BACKPACK_CAPACITY)

    var boss_state := BossCombatState.new()
    boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    match_state = MatchCombatState.new()
    match_state.setup(player_state, boss_state, board_state, shared_deck, 1)
    resolution_controller = ResolutionController.new()
    outcome_controller = OutcomeController.new()

    combat_controller = CombatController.new()
    combat_controller.setup(
        match_state,
        resolution_controller,
        outcome_controller
    )

func set_status(message: String) -> void:
 status_label.text = message
 print("[STATUS] ", message)


func _refresh_ui() -> void:
    player_health_label.text = "Player HP: %d/%d" % [
        match_state.player_state.current_health,
        match_state.player_state.max_health
    ]

    boss_health_label.text = "Boss HP: %d/%d" % [
        match_state.boss_state.current_health,
        match_state.boss_state.max_health
    ]

    round_label.text = "Round: %d" % match_state.round_number
    gold_label.text = "Gold: %d" % match_state.player_state.temporary_gold

    _refresh_board_cards()
    _refresh_equipment_labels()


func _refresh_board_cards() -> void:
 for child in board_card_list.get_children():
  child.queue_free()

 var active_cards = match_state.board_state.get_active_cards()

 for i in range(active_cards.size()):
  var card = active_cards[i]
  var card_view = CARD_VIEW_SCENE.instantiate()
  board_card_list.add_child(card_view)
  card_view.setup(card, i)




func _refresh_equipment_labels() -> void:
    var left_hand_status := "ready"
    if match_state.player_state.left_hand_exhausted:
        left_hand_status = "exhausted"

    var right_hand_status := "ready"
    if match_state.player_state.right_hand_exhausted:
        right_hand_status = "exhausted"

    left_hand_label.text = "Left Hand: %s (%s)" % [
        _get_single_card_label(match_state.player_state.left_hand_card),
        left_hand_status
    ]

    right_hand_label.text = "Right Hand: %s (%s)" % [
        _get_single_card_label(match_state.player_state.right_hand_card),
        right_hand_status
    ]

    if match_state.player_state.backpack_cards.size() > 0:
        var backpack_names: Array = []

        for card in match_state.player_state.backpack_cards:
            backpack_names.append(_get_card_name(card))

        backpack_label.text = "Backpack: %s" % ", ".join(backpack_names)
    else:
        backpack_label.text = "Backpack: [empty]"



func _get_single_card_label(card) -> String:
    if card == null:
        return "[empty]"

    if card is CardRuntimeState:
        return "%s | zone: %s" % [card.card_id, card.zone]

    return _get_card_name(card)


func _get_card_name(card) -> String:
    if card is CardRuntimeState:
        return card.card_id

    if card is Dictionary:
        return str(card.get("id", "unknown_card"))

    return "unknown_card"


func _get_card_display_text(card) -> String:
    if card is CardRuntimeState:
        return "%s | %s | value: %d | zone: %s" % [
            card.card_id,
            card.get_family(),
            card.current_value,
            card.zone
        ]

    if card is Dictionary:
        return "%s | %s | value: %s" % [
            str(card.get("id", "unknown")),
            str(card.get("family", "unknown")),
            str(card.get("base_value", "null"))
        ]

    return "unknown card"

func _on_take_first_monster_pressed() -> void:
 var board_cards = match_state.board_state.get_active_cards()

 for i in range(board_cards.size()):
  var card = board_cards[i]
  if _get_card_family(card) == "monster":
   combat_controller.resolve_enemy_to_player(i)
   set_status("First monster resolved against player.")
   _refresh_ui()
   return

 set_status("No monster found on board.")


func _on_move_first_to_left_hand_pressed() -> void:
 var board_cards = match_state.board_state.get_active_cards()

 for i in range(board_cards.size()):
  var card = board_cards[i]
  if _is_player_usable_card(card):
   combat_controller.move_player_card_to_left_hand(i)
   set_status("Moved first usable card to left hand.")
   _refresh_ui()
   return

 set_status("No usable card found for left hand.")



func _on_move_first_to_backpack_pressed() -> void:
 var board_cards = match_state.board_state.get_active_cards()

 for i in range(board_cards.size()):
  var card = board_cards[i]
  if _is_player_usable_card(card):
   combat_controller.move_player_card_to_backpack(i)
   set_status("Moved first usable card to backpack.")
   _refresh_ui()
   return

 set_status("No usable card found for backpack.")


func _get_card_family(card) -> String:
    if card is CardRuntimeState:
        return card.get_family()

    if card is Dictionary:
        return str(card.get("family", ""))

    return ""


func _is_player_usable_card(card) -> bool:
    var family := _get_card_family(card)
    return family in ["weapon", "shield", "potion", "spell", "artifact", "coin", "chest"]

func handle_drop_to_left_hand(board_index: int) -> void:
 print("handle_drop_to_left_hand called with index: ", board_index)

 var before_left_hand = match_state.player_state.left_hand_card
 print("before move, left hand: ", before_left_hand)

 combat_controller.move_player_card_to_left_hand(board_index)

 var after_left_hand = match_state.player_state.left_hand_card
 print("after move, left hand: ", after_left_hand)

 set_status("Dropped card into left hand.")
 _refresh_ui()

func handle_drop_to_right_hand(board_index: int) -> void:
 print("handle_drop_to_right_hand called with index: ", board_index)

 var before_right_hand = match_state.player_state.right_hand_card
 print("before move, right hand: ", before_right_hand)

 combat_controller.move_player_card_to_right_hand(board_index)

 var after_right_hand = match_state.player_state.right_hand_card
 print("after move, right hand: ", after_right_hand)

 set_status("Dropped card into right hand.")
 _refresh_ui()


func handle_drop_to_backpack(board_index: int) -> void:
 print("handle_drop_to_backpack called with index: ", board_index)

 var before_backpack = match_state.player_state.backpack_cards.size()
 print("before move, backpack size: ", before_backpack)

 combat_controller.move_player_card_to_backpack(board_index)

 var after_backpack = match_state.player_state.backpack_cards.size()
 print("after move, backpack size: ", after_backpack)

 set_status("Dropped card into backpack.")
 _refresh_ui()


func handle_drop_to_player_avatar(board_index: int) -> void:
 print("handle_drop_to_player_avatar called with index: ", board_index)

 var before_health = match_state.player_state.current_health
 print("before resolve, player health: ", before_health)

 var success := combat_controller.resolve_enemy_to_player(board_index)

 var after_health = match_state.player_state.current_health
 print("after resolve, player health: ", after_health)

 if success:
  set_status("Dropped monster onto player.")
 else:
  set_status("Only monsters can be dropped onto the player.")

 _refresh_ui()
