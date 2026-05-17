extends Control

const PLAYER_STARTING_HEALTH := 15
const BOSS_STARTING_HEALTH := 12
const ACTIVE_BOARD_CAP := 4
const STARTING_BACKPACK_CAPACITY := 1
const CARD_VIEW_SCENE = preload("res://cards/card_view.tscn")
const LEFT_HAND_PLACEHOLDER = preload("res://art/ui/LeftHand Placement Card.png")
const RIGHT_HAND_PLACEHOLDER = preload("res://art/ui/RightHand Placement Card.png")
const BACKPACK_PLACEHOLDER = preload("res://art/ui/Backpack Placement Card.png")
const BACKGROUND_TEXTURE = preload("res://art/backgrounds/Ossara-Titled-Arena-blured.png")
const HUD_TEXT = Color("f1e7d6")
const HUD_MUTED = Color("c4b59a")
const SUCCESS_TEXT = Color("d5c074")
const ERROR_TEXT = Color("d38a80")
const PANEL_FILL = Color("130f0d")
const PANEL_BORDER = Color("6a5542")
const DISCARD_BORDER = Color("9d6b55")
const CARD_ART_TEXTURES := {
	"crypt_hound": preload("res://art/cards/Crypt Hound.png"),
	"grave_thrall": preload("res://art/cards/Grave Thrall.png"),
	"large_health_potion": preload("res://art/cards/Large Healing Potion.png"),
	"gold_10": preload("res://art/cards/Coins.png"),
	"risen_bones": preload("res://art/cards/Risen Bones.png"),
	"sepulcher_guard": preload("res://art/cards/Sepulcher Guard.png"),
	"short_sword": preload("res://art/cards/Short Sword.png"),
	"small_chest": preload("res://art/cards/Small Chest.png"),
	"small_health_potion": preload("res://art/cards/Small Healing Potion.png"),
	"small_shield": preload("res://art/cards/Small Shield.png")
}

@onready var player_health_label = $RootLayout/StageCenter/Stage/TopBar/PlayerHealthLabel
@onready var boss_health_label = $RootLayout/StageCenter/Stage/TopBar/BossHealthLabel
@onready var round_label = $RootLayout/StageCenter/Stage/TopBar/RoundLabel
@onready var gold_label = $RootLayout/StageCenter/Stage/TopBar/GoldLabel
@onready var status_label = $RootLayout/StageCenter/Stage/TopBar/StatusLabel

@onready var board_card_list = $RootLayout/StageCenter/Stage/PlayArea/BoardCenter/BoardSection/BoardLane/BoardCardList
@onready var board_title = $RootLayout/StageCenter/Stage/PlayArea/BoardCenter/BoardSection/BoardTitle
@onready var button_bar = $RootLayout/StageCenter/Stage/ButtonBar
@onready var background_texture = $Background

@onready var left_hand_texture = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/LeftHandDropZone/CardCanvas/PlacementTexture
@onready var player_avatar_texture = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/PlayerAvatarDropZone/AvatarTexture
@onready var right_hand_texture = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/RightHandDropZone/CardCanvas/PlacementTexture
@onready var backpack_texture = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/BackpackDropZone/CardCanvas/PlacementTexture
@onready var left_hand_drop_zone = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/LeftHandDropZone
@onready var player_avatar_drop_zone = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/PlayerAvatarDropZone
@onready var right_hand_drop_zone = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/RightHandDropZone
@onready var backpack_drop_zone = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/BackpackDropZone
@onready var discard_drop_zone = $RootLayout/StageCenter/Stage/PlayArea/BoardCenter/BoardSection/BoardLane/DiscardCenter/DiscardColumn/DiscardDropZone
@onready var left_hand_value_label = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/LeftHandDropZone/CardCanvas/ValueLabel
@onready var left_hand_name_label = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/LeftHandDropZone/CardCanvas/BottomText/NameLabel
@onready var left_hand_type_label = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/LeftHandDropZone/CardCanvas/BottomText/TypeLabel
@onready var right_hand_value_label = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/RightHandDropZone/CardCanvas/ValueLabel
@onready var right_hand_name_label = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/RightHandDropZone/CardCanvas/BottomText/NameLabel
@onready var right_hand_type_label = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/RightHandDropZone/CardCanvas/BottomText/TypeLabel
@onready var backpack_value_label = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/BackpackDropZone/CardCanvas/ValueLabel
@onready var backpack_name_label = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/BackpackDropZone/CardCanvas/BottomText/NameLabel
@onready var backpack_type_label = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/BackpackDropZone/CardCanvas/BottomText/TypeLabel

@onready var left_hand_label = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/LabelRow/LeftHandLabel
@onready var player_label = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/LabelRow/PlayerLabel
@onready var right_hand_label = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/LabelRow/RightHandLabel
@onready var backpack_label = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/LabelRow/BackpackLabel
@onready var take_first_monster_button = $RootLayout/StageCenter/Stage/ButtonBar/TakeFirstMonsterButton
@onready var move_first_to_left_hand_button = $RootLayout/StageCenter/Stage/ButtonBar/MoveFirstToLeftHandButton
@onready var move_first_to_backpack_button = $RootLayout/StageCenter/Stage/ButtonBar/MoveFirstToBackpackButton

var match_state: MatchCombatState
var resolution_controller: ResolutionController
var outcome_controller: OutcomeController
var combat_controller: CombatController
var restart_pending := false
var left_hand_visual_card_id := ""
var right_hand_visual_card_id := ""
var backpack_visual_card_id := ""


func _ready() -> void:
    add_to_group("combat_scene")
    _build_test_match_state()
    _apply_visual_theme()

    take_first_monster_button.pressed.connect(_on_take_first_monster_pressed)
    move_first_to_left_hand_button.pressed.connect(_on_move_first_to_left_hand_pressed)
    move_first_to_backpack_button.pressed.connect(_on_move_first_to_backpack_pressed)
    set_status("Ready.")

    _refresh_ui()



func _build_test_match_state() -> void:
    left_hand_visual_card_id = ""
    right_hand_visual_card_id = ""
    backpack_visual_card_id = ""

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
    if background_texture != null:
        background_texture.texture = BACKGROUND_TEXTURE

func set_status(message: String) -> void:
 status_label.text = message
 if "could not" in message.to_lower() or "only " in message.to_lower() or "no " in message.to_lower():
  status_label.add_theme_color_override("font_color", ERROR_TEXT)
 else:
  status_label.add_theme_color_override("font_color", SUCCESS_TEXT)
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
    _refresh_drop_zone_textures()
    _refresh_equipment_labels()
    _refresh_slot_state_visuals()
    _queue_restart_if_failed()


func _refresh_board_cards() -> void:
 for child in board_card_list.get_children():
  child.queue_free()

 var active_cards = match_state.board_state.get_active_cards()

 for i in range(active_cards.size()):
  var card = active_cards[i]
  var card_view = CARD_VIEW_SCENE.instantiate()
  board_card_list.add_child(card_view)
  card_view.setup(card, i)


func _refresh_drop_zone_textures() -> void:
 left_hand_visual_card_id = _update_slot_visual(
  left_hand_texture,
  left_hand_name_label,
  left_hand_type_label,
  left_hand_value_label,
  match_state.player_state.left_hand_card,
  LEFT_HAND_PLACEHOLDER,
  left_hand_visual_card_id
 )
 right_hand_visual_card_id = _update_slot_visual(
  right_hand_texture,
  right_hand_name_label,
  right_hand_type_label,
  right_hand_value_label,
  match_state.player_state.right_hand_card,
  RIGHT_HAND_PLACEHOLDER,
  right_hand_visual_card_id
 )

 var backpack_card = null
 if match_state.player_state.backpack_cards.size() > 0:
  backpack_card = match_state.player_state.backpack_cards[0]

 backpack_visual_card_id = _update_slot_visual(
  backpack_texture,
  backpack_name_label,
  backpack_type_label,
  backpack_value_label,
  backpack_card,
  BACKPACK_PLACEHOLDER,
  backpack_visual_card_id
 )




func _refresh_equipment_labels() -> void:
    var left_hand_status := "ready"
    if match_state.player_state.left_hand_exhausted:
        left_hand_status = "exhausted"

    var right_hand_status := "ready"
    if match_state.player_state.right_hand_exhausted:
        right_hand_status = "exhausted"

    left_hand_label.text = "Left Hand: %s [%s]" % [
        _get_single_card_label(match_state.player_state.left_hand_card),
        left_hand_status
    ]

    right_hand_label.text = "Right Hand: %s [%s]" % [
        _get_single_card_label(match_state.player_state.right_hand_card),
        right_hand_status
    ]

    if match_state.player_state.backpack_cards.size() > 0:
        var backpack_names: Array = []

        for card in match_state.player_state.backpack_cards:
            backpack_names.append(_humanize_card_name(_get_card_name(card)))

        backpack_label.text = "Backpack: %s" % ", ".join(backpack_names)
    else:
        backpack_label.text = "Backpack: [empty]"



func _get_single_card_label(card) -> String:
    if card == null:
        return "[empty]"

    return _humanize_card_name(_get_card_name(card))


func _get_card_name(card) -> String:
    if card is CardRuntimeState:
        return card.card_id

    if card is Dictionary:
        return str(card.get("id", "unknown_card"))

    return "unknown_card"


func _humanize_card_name(card_id: String) -> String:
    var cleaned := card_id.strip_edges().replace("_", " ")
    if cleaned == "":
        return "Unknown Card"

    var words := cleaned.split(" ", false)
    for i in range(words.size()):
        var word := String(words[i])
        if word == "":
            continue
        words[i] = word.substr(0, 1).to_upper() + word.substr(1)

    return " ".join(words)


func _get_card_texture_or_placeholder(card, placeholder):
 var texture = _get_card_texture(card)
 if texture != null:
  return texture
 return placeholder


func _get_card_texture(card):
 if card == null:
  return null

 var card_id = _get_card_name(card)
 return CARD_ART_TEXTURES.get(card_id, null)


func _get_board_card_view(board_index: int):
 if board_index < 0 or board_index >= board_card_list.get_child_count():
  return null

 return board_card_list.get_child(board_index)


func _animate_board_card_resolution(board_index: int) -> void:
 var card_view = _get_board_card_view(board_index)
 if card_view == null:
  return

 card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE

 var tween = create_tween()
 tween.tween_property(card_view, "modulate:a", 0.0, 0.18)
 tween.parallel().tween_property(card_view, "scale", Vector2(0.88, 0.88), 0.18)
 await tween.finished


func _animate_slot_resolution(texture_rect: TextureRect, name_label: Label, type_label: Label, value_label: Label, placeholder) -> void:
 if texture_rect.texture == null:
  texture_rect.texture = placeholder
  texture_rect.modulate.a = 1.0
  _clear_slot_text(name_label, type_label, value_label)
  return

 var tween = create_tween()
 tween.tween_property(texture_rect, "modulate:a", 0.0, 0.18)
 tween.tween_callback(func():
  texture_rect.texture = placeholder
  texture_rect.modulate.a = 1.0
  _clear_slot_text(name_label, type_label, value_label)
 )


func _update_slot_visual(texture_rect: TextureRect, name_label: Label, type_label: Label, value_label: Label, card, placeholder, previous_card_id: String) -> String:
 var next_card_id := ""
 if card != null:
  next_card_id = _get_card_name(card)

 if previous_card_id != "" and next_card_id == "":
  _animate_slot_resolution(texture_rect, name_label, type_label, value_label, placeholder)
  return ""

 texture_rect.modulate.a = 1.0
 texture_rect.texture = _get_card_texture_or_placeholder(card, placeholder)
 _apply_slot_text(name_label, type_label, value_label, card)
 return next_card_id


func _apply_slot_text(name_label: Label, type_label: Label, value_label: Label, card) -> void:
 if card == null:
  _clear_slot_text(name_label, type_label, value_label)
  return

 name_label.text = _humanize_card_name(_get_card_name(card))
 type_label.text = _humanize_card_name(_get_card_family(card))
 value_label.text = str(_get_card_runtime_value(card))


func _clear_slot_text(name_label: Label, type_label: Label, value_label: Label) -> void:
 name_label.text = ""
 type_label.text = ""
 value_label.text = ""


func _get_card_runtime_value(card) -> int:
 if card is CardRuntimeState:
  return card.current_value

 if card is Dictionary:
  if card.has("current_value"):
   return int(card.get("current_value", 0))
  return int(card.get("base_value", 0))

 return 0


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


func get_slot_card(slot_name: String):
    match slot_name:
        "left_hand":
            return match_state.player_state.left_hand_card
        "right_hand":
            return match_state.player_state.right_hand_card
        "backpack":
            if match_state.player_state.backpack_cards.size() > 0:
                return match_state.player_state.backpack_cards[0]
            return null
        _:
            return null


func get_slot_card_family(slot_name: String) -> String:
    return _get_card_family(get_slot_card(slot_name))


func can_drag_slot_card(slot_name: String) -> bool:
    if restart_pending:
        return false

    var card = get_slot_card(slot_name)
    if card == null:
        return false
    return slot_name in ["left_hand", "right_hand", "backpack"]


func can_use_slot_weapon_on_monster(slot_name: String) -> bool:
    if restart_pending:
        return false

    var card = get_slot_card(slot_name)
    if card == null or _get_card_family(card) != "weapon":
        return false

    if slot_name == "left_hand":
        return not match_state.player_state.left_hand_exhausted

    if slot_name == "right_hand":
        return not match_state.player_state.right_hand_exhausted

    return false


func can_drop_on_slot(target_slot: String, data: Dictionary) -> bool:
    if restart_pending:
        return false

    var source := String(data.get("source", "")).strip_edges()
    var family := String(data.get("card_family", "")).strip_edges()

    if source == "board":
        if target_slot == "left_hand":
            if match_state.player_state.left_hand_card != null or match_state.player_state.left_hand_exhausted:
                return false
            return family in ["weapon", "shield", "potion", "spell", "artifact", "coin", "chest"]
        elif target_slot == "right_hand":
            if match_state.player_state.right_hand_card != null or match_state.player_state.right_hand_exhausted:
                return false
            return family in ["weapon", "shield", "potion", "spell", "artifact", "coin", "chest"]
        elif target_slot == "backpack":
            if match_state.player_state.backpack_cards.size() >= match_state.player_state.backpack_capacity:
                return false
            return family in ["weapon", "shield", "potion", "spell", "artifact", "coin", "chest"]
        elif target_slot == "player_avatar":
            return family == "monster"
        elif target_slot == "discard":
            return family in ["weapon", "shield", "potion", "spell", "artifact", "coin", "chest"]
        else:
            return false

    if source == "backpack" and target_slot in ["left_hand", "right_hand"]:
        if family == "":
            return false
        if target_slot == "left_hand":
            return match_state.player_state.left_hand_card == null and not match_state.player_state.left_hand_exhausted
        return match_state.player_state.right_hand_card == null and not match_state.player_state.right_hand_exhausted

    if source in ["left_hand", "right_hand"] and target_slot == "backpack":
        if family == "":
            return false
        return match_state.player_state.backpack_cards.size() < match_state.player_state.backpack_capacity

    return false


func handle_slot_to_slot_drop(source_slot: String, target_slot: String) -> void:
    if restart_pending or source_slot == target_slot:
        return

    var moved := false
    if source_slot == "backpack" and target_slot == "left_hand":
        moved = _move_backpack_to_hand(true)
    elif source_slot == "backpack" and target_slot == "right_hand":
        moved = _move_backpack_to_hand(false)
    elif source_slot == "left_hand" and target_slot == "backpack":
        moved = _move_hand_to_backpack(true)
    elif source_slot == "right_hand" and target_slot == "backpack":
        moved = _move_hand_to_backpack(false)

    if moved:
        set_status("Moved card from %s to %s." % [source_slot.replace("_", " "), target_slot.replace("_", " ")])
    else:
        set_status("Could not move card from %s to %s." % [source_slot.replace("_", " "), target_slot.replace("_", " ")])

    _refresh_ui()


func _move_backpack_to_hand(is_left_hand: bool) -> bool:
    if match_state.player_state.backpack_cards.is_empty():
        return false

    var card = match_state.player_state.remove_backpack_card_at(0)
    if card == null:
        return false

    var success := false
    if is_left_hand:
        success = match_state.player_state.set_left_hand_card(card)
    else:
        success = match_state.player_state.set_right_hand_card(card)

    if not success:
        match_state.player_state.backpack_cards.insert(0, card)
        if card is CardRuntimeState:
            card.set_zone("backpack")
        elif card is Dictionary:
            card["zone"] = "backpack"
        return false

    return true


func _move_hand_to_backpack(is_left_hand: bool) -> bool:
    if match_state.player_state.backpack_cards.size() >= match_state.player_state.backpack_capacity:
        return false

    var card = match_state.player_state.left_hand_card if is_left_hand else match_state.player_state.right_hand_card
    if card == null:
        return false

    if is_left_hand:
        match_state.player_state.clear_left_hand_card()
    else:
        match_state.player_state.clear_right_hand_card()

    if not match_state.player_state.add_to_backpack(card):
        if is_left_hand:
            match_state.player_state.left_hand_card = card
            if card is CardRuntimeState:
                card.set_zone("left_hand")
            elif card is Dictionary:
                card["zone"] = "left_hand"
        else:
            match_state.player_state.right_hand_card = card
            if card is CardRuntimeState:
                card.set_zone("right_hand")
            elif card is Dictionary:
                card["zone"] = "right_hand"
        return false

    return true


func handle_weapon_drop_on_board(source_hand: String, board_index: int) -> void:
    if restart_pending:
        return

    var before_count := match_state.board_state.active_count()
    var before_value := -1
    var before_cards = match_state.board_state.get_active_cards()
    if board_index >= 0 and board_index < before_cards.size():
        before_value = _get_card_runtime_value(before_cards[board_index])

    var success := false
    if source_hand == "left_hand":
        success = combat_controller.use_left_hand_weapon_on_monster(board_index)
    elif source_hand == "right_hand":
        success = combat_controller.use_right_hand_weapon_on_monster(board_index)

    if not success:
        set_status("Could not use weapon on monster.")
        _refresh_ui()
        return

    var after_count := match_state.board_state.active_count()
    if after_count < before_count:
        await _animate_board_card_resolution(board_index)
        set_status("Weapon resolved the monster.")
    else:
        var after_cards = match_state.board_state.get_active_cards()
        var remaining_value := -1
        if board_index >= 0 and board_index < after_cards.size():
            remaining_value = _get_card_runtime_value(after_cards[board_index])
        set_status("Weapon hit. Monster reduced from %d to %d." % [before_value, remaining_value])

    _refresh_ui()


func _apply_visual_theme() -> void:
    player_health_label.add_theme_color_override("font_color", HUD_TEXT)
    boss_health_label.add_theme_color_override("font_color", HUD_TEXT)
    round_label.add_theme_color_override("font_color", HUD_TEXT)
    gold_label.add_theme_color_override("font_color", SUCCESS_TEXT)
    board_title.add_theme_color_override("font_color", HUD_MUTED)
    board_title.add_theme_font_size_override("font_size", 15)
    player_label.add_theme_color_override("font_color", HUD_MUTED)

    button_bar.visible = false
    _style_zone(left_hand_drop_zone, PANEL_BORDER)
    _style_zone(player_avatar_drop_zone, Color("8d7867"))
    _style_zone(right_hand_drop_zone, PANEL_BORDER)
    _style_zone(backpack_drop_zone, Color("6e7e66"))
    _style_zone(discard_drop_zone, DISCARD_BORDER)

    _style_loadout_label(left_hand_label)
    _style_loadout_label(player_label)
    _style_loadout_label(right_hand_label)
    _style_loadout_label(backpack_label)
    _style_slot_text(left_hand_name_label, left_hand_type_label, left_hand_value_label)
    _style_slot_text(right_hand_name_label, right_hand_type_label, right_hand_value_label)
    _style_slot_text(backpack_name_label, backpack_type_label, backpack_value_label)

    _style_debug_button(take_first_monster_button)
    _style_debug_button(move_first_to_left_hand_button)
    _style_debug_button(move_first_to_backpack_button)

    take_first_monster_button.text = "Debug: First Monster"
    move_first_to_left_hand_button.text = "Debug: Left Hand"
    move_first_to_backpack_button.text = "Debug: Backpack"

    status_label.add_theme_font_size_override("font_size", 15)


func _style_zone(panel: PanelContainer, border_color: Color) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = PANEL_FILL
    style.border_color = border_color
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.corner_radius_top_left = 18
    style.corner_radius_top_right = 18
    style.corner_radius_bottom_right = 18
    style.corner_radius_bottom_left = 18
    style.shadow_color = Color(0, 0, 0, 0.28)
    style.shadow_size = 5
    panel.add_theme_stylebox_override("panel", style)


func _refresh_slot_state_visuals() -> void:
    _reset_slot_visual_state(left_hand_drop_zone, left_hand_texture, PANEL_BORDER)
    _reset_slot_visual_state(right_hand_drop_zone, right_hand_texture, PANEL_BORDER)
    _reset_slot_visual_state(backpack_drop_zone, backpack_texture, Color("6e7e66"))

    if match_state.player_state.left_hand_exhausted:
        _apply_exhausted_slot_visual(left_hand_drop_zone)

    if match_state.player_state.right_hand_exhausted:
        _apply_exhausted_slot_visual(right_hand_drop_zone)


func _reset_slot_visual_state(panel: PanelContainer, texture_rect: TextureRect, border_color: Color) -> void:
    _style_zone(panel, border_color)
    panel.modulate = Color(1, 1, 1, 1)
    texture_rect.modulate = Color(1, 1, 1, 1)


func _apply_exhausted_slot_visual(panel: PanelContainer) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("2b1414")
    style.border_color = Color("d15b5b")
    style.border_width_left = 3
    style.border_width_top = 3
    style.border_width_right = 3
    style.border_width_bottom = 3
    style.corner_radius_top_left = 18
    style.corner_radius_top_right = 18
    style.corner_radius_bottom_right = 18
    style.corner_radius_bottom_left = 18
    style.shadow_color = Color(0, 0, 0, 0.28)
    style.shadow_size = 5
    panel.add_theme_stylebox_override("panel", style)


func _style_loadout_label(label: Label) -> void:
    label.add_theme_color_override("font_color", HUD_MUTED)
    label.add_theme_font_size_override("font_size", 13)


func _style_debug_button(button: Button) -> void:
    button.modulate = Color(0.9, 0.86, 0.79, 0.84)
    button.add_theme_font_size_override("font_size", 12)


func _style_slot_text(name_label: Label, type_label: Label, value_label: Label) -> void:
    name_label.add_theme_color_override("font_color", Color("f7ead7"))
    name_label.add_theme_font_size_override("font_size", 17)
    type_label.add_theme_color_override("font_color", Color("ddd0bb"))
    type_label.add_theme_font_size_override("font_size", 12)
    value_label.add_theme_color_override("font_color", Color("ffffff"))
    value_label.add_theme_font_size_override("font_size", 18)


func _queue_restart_if_failed() -> void:
    if restart_pending:
        return

    if outcome_controller == null or match_state == null:
        return

    if outcome_controller.check_outcome(match_state) != "failure":
        return

    restart_pending = true
    _set_debug_controls_enabled(false)
    call_deferred("_begin_failure_reset")


func _begin_failure_reset() -> void:
    _run_failure_reset()


func _run_failure_reset() -> void:
    set_status("You died. Restarting...")
    await get_tree().create_timer(0.9).timeout
    _build_test_match_state()
    restart_pending = false
    _set_debug_controls_enabled(true)
    set_status("Fresh restart.")
    _refresh_ui()


func _set_debug_controls_enabled(is_enabled: bool) -> void:
    take_first_monster_button.disabled = not is_enabled
    move_first_to_left_hand_button.disabled = not is_enabled
    move_first_to_backpack_button.disabled = not is_enabled

func _on_take_first_monster_pressed() -> void:
 if restart_pending:
  return

 var board_cards = match_state.board_state.get_active_cards()

 for i in range(board_cards.size()):
  var card = board_cards[i]
  if _get_card_family(card) == "monster":
   var success := combat_controller.resolve_enemy_to_player(i)
   if success:
    await _animate_board_card_resolution(i)
    set_status("First monster resolved against player.")
   else:
    set_status("Monster could not resolve against player.")
   _refresh_ui()
   return

 set_status("No monster found on board.")


func _on_move_first_to_left_hand_pressed() -> void:
 if restart_pending:
  return

 var board_cards = match_state.board_state.get_active_cards()

 for i in range(board_cards.size()):
  var card = board_cards[i]
  if _is_player_usable_card(card):
   var success := combat_controller.move_player_card_to_left_hand(i)
   if success:
    await _animate_board_card_resolution(i)
    set_status("Moved first usable card to left hand.")
   else:
    set_status("Could not move card to left hand.")
   _refresh_ui()
   return

 set_status("No usable card found for left hand.")



func _on_move_first_to_backpack_pressed() -> void:
 if restart_pending:
  return

 var board_cards = match_state.board_state.get_active_cards()

 for i in range(board_cards.size()):
  var card = board_cards[i]
  if _is_player_usable_card(card):
   var success := combat_controller.move_player_card_to_backpack(i)
   if success:
    await _animate_board_card_resolution(i)
    set_status("Moved first usable card to backpack.")
   else:
    set_status("Could not move card to backpack.")
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
 if restart_pending:
  return

 print("handle_drop_to_left_hand called with index: ", board_index)

 var before_left_hand = match_state.player_state.left_hand_card
 print("before move, left hand: ", before_left_hand)

 var success := combat_controller.move_player_card_to_left_hand(board_index)

 var after_left_hand = match_state.player_state.left_hand_card
 print("after move, left hand: ", after_left_hand)

 if success:
  await _animate_board_card_resolution(board_index)
  set_status("Dropped card into left hand.")
 else:
  set_status("Could not drop card into left hand.")
 _refresh_ui()

func handle_drop_to_right_hand(board_index: int) -> void:
 if restart_pending:
  return

 print("handle_drop_to_right_hand called with index: ", board_index)

 var before_right_hand = match_state.player_state.right_hand_card
 print("before move, right hand: ", before_right_hand)

 var success := combat_controller.move_player_card_to_right_hand(board_index)

 var after_right_hand = match_state.player_state.right_hand_card
 print("after move, right hand: ", after_right_hand)

 if success:
  await _animate_board_card_resolution(board_index)
  set_status("Dropped card into right hand.")
 else:
  set_status("Could not drop card into right hand.")
 _refresh_ui()


func handle_drop_to_backpack(board_index: int) -> void:
 if restart_pending:
  return

 print("handle_drop_to_backpack called with index: ", board_index)

 var before_backpack = match_state.player_state.backpack_cards.size()
 print("before move, backpack size: ", before_backpack)

 var success := combat_controller.move_player_card_to_backpack(board_index)

 var after_backpack = match_state.player_state.backpack_cards.size()
 print("after move, backpack size: ", after_backpack)

 if success:
  await _animate_board_card_resolution(board_index)
  set_status("Dropped card into backpack.")
 else:
  set_status("Could not drop card into backpack.")
 _refresh_ui()


func handle_drop_to_player_avatar(board_index: int) -> void:
 if restart_pending:
  return

 print("handle_drop_to_player_avatar called with index: ", board_index)

 var before_health = match_state.player_state.current_health
 print("before resolve, player health: ", before_health)

 var success := combat_controller.resolve_enemy_to_player(board_index)

 var after_health = match_state.player_state.current_health
 print("after resolve, player health: ", after_health)

 if success:
  await _animate_board_card_resolution(board_index)
  set_status("Dropped monster onto player.")
 else:
  set_status("Only monsters can be dropped onto the player.")

 _refresh_ui()


func handle_drop_to_discard(board_index: int) -> void:
 if restart_pending:
  return

 print("handle_drop_to_discard called with index: ", board_index)

 var success := combat_controller.trash_player_card_from_board(board_index)

 if success:
  await _animate_board_card_resolution(board_index)
  set_status("Discarded card without benefit.")
 else:
  set_status("Only item cards can be discarded.")

 _refresh_ui()
