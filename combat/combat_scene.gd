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
const CARD_BACK_TEXTURE = preload("res://art/ui/CardBack.png")
const BOSS_CARD_TEXTURE = preload("res://art/cards/Gravebound Warden.png")
const EMPTY_BOARD_SLOT_SIZE = Vector2(220, 300)
const HUD_TEXT = Color("f1e7d6")
const HUD_MUTED = Color("c4b59a")
const SUCCESS_TEXT = Color("d5c074")
const ERROR_TEXT = Color("d38a80")
const VALID_DROP_TINT = Color(0.45, 0.72, 1.0, 0.58)
const INVALID_DROP_TINT = Color(1.0, 0.36, 0.36, 0.58)
const PANEL_FILL = Color("130f0d")
const PANEL_BORDER = Color("6a5542")
const DISCARD_BORDER = Color("9d6b55")
const CARD_ART_TEXTURES := {
	"crypt_hound": preload("res://art/cards/Crypt Hound.png"),
	"grave_thrall": preload("res://art/cards/Grave Thrall.png"),
	"large_health_potion": preload("res://art/cards/Large Healing Potion.png"),
	"gold_10": preload("res://art/cards/Coins.png"),
	"gravebound_warden": preload("res://art/cards/Gravebound Warden.png"),
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
@onready var boss_drop_zone = $RootLayout/StageCenter/Stage/BossCenter/BossDropZone
@onready var boss_art_texture = $RootLayout/StageCenter/Stage/BossCenter/BossDropZone/BossCanvas/BossArt
@onready var boss_title_label = $RootLayout/StageCenter/Stage/BossCenter/BossDropZone/BossCanvas/TitleLabel
@onready var boss_life_bar = $RootLayout/StageCenter/Stage/BossCenter/BossDropZone/BossCanvas/LifeBar
@onready var boss_life_label = $RootLayout/StageCenter/Stage/BossCenter/BossDropZone/BossCanvas/LifeBar/LifeLabel

@onready var board_card_list = $RootLayout/StageCenter/Stage/PlayArea/BoardCenter/BoardSection/BoardLane/BoardCardList
@onready var board_title = $RootLayout/StageCenter/Stage/PlayArea/BoardCenter/BoardSection/BoardTitle
@onready var deck_card_texture = $RootLayout/StageCenter/Stage/PlayArea/BoardCenter/BoardSection/BoardLane/DeckCenter/DeckColumn/DeckCard
@onready var deck_count_label = $RootLayout/StageCenter/Stage/PlayArea/BoardCenter/BoardSection/BoardLane/DeckCenter/DeckColumn/DeckCountLabel
@onready var discard_texture = $RootLayout/StageCenter/Stage/PlayArea/BoardCenter/BoardSection/BoardLane/DiscardCenter/DiscardColumn/DiscardDropZone/DiscardTexture
@onready var background_texture = $Background
@onready var battle_music_player = $BattleMusic

@onready var left_hand_texture = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/LeftHandDropZone/CardCanvas/PlacementTexture
@onready var player_avatar_texture = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/PlayerAvatarDropZone/PlayerCanvas/AvatarTexture
@onready var right_hand_texture = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/RightHandDropZone/CardCanvas/PlacementTexture
@onready var backpack_texture = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/BackpackDropZone/CardCanvas/PlacementTexture
@onready var left_hand_drop_zone = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/LeftHandDropZone
@onready var player_avatar_drop_zone = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/PlayerAvatarDropZone
@onready var right_hand_drop_zone = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/RightHandDropZone
@onready var backpack_drop_zone = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/BackpackDropZone
@onready var discard_drop_zone = $RootLayout/StageCenter/Stage/PlayArea/BoardCenter/BoardSection/BoardLane/DiscardCenter/DiscardColumn/DiscardDropZone
@onready var player_life_bar = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/PlayerAvatarDropZone/PlayerCanvas/PlayerLifeBar
@onready var player_life_label = $RootLayout/StageCenter/Stage/PlayArea/LoadoutCenter/LoadoutGroup/DropZoneRow/PlayerAvatarDropZone/PlayerCanvas/PlayerLifeBar/PlayerLifeLabel
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

var match_state: MatchCombatState
var resolution_controller: ResolutionController
var outcome_controller: OutcomeController
var combat_controller: CombatController
var restart_pending := false
var left_hand_visual_card_id := ""
var right_hand_visual_card_id := ""
var backpack_visual_card_id := ""
var last_board_card_ids: Array[String] = []
var board_visuals_initialized := false


func _ready() -> void:
    add_to_group("combat_scene")
    _build_test_match_state()
    _apply_visual_theme()
    _start_battle_music()
    set_status("Ready.")

    _refresh_ui()


func _start_battle_music() -> void:
    if battle_music_player == null or battle_music_player.stream == null:
        return

    if battle_music_player.stream is AudioStreamOggVorbis:
        battle_music_player.stream.loop = true

    if not battle_music_player.playing:
        battle_music_player.play()



func _build_test_match_state() -> void:
    left_hand_visual_card_id = ""
    right_hand_visual_card_id = ""
    backpack_visual_card_id = ""
    last_board_card_ids.clear()
    board_visuals_initialized = false

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
    if deck_card_texture != null:
        deck_card_texture.texture = CARD_BACK_TEXTURE

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
    deck_count_label.text = "Deck: %d" % match_state.shared_deck_state.remaining_count()
    player_life_label.text = "%d/%d" % [
        match_state.player_state.current_health,
        match_state.player_state.max_health
    ]

    _refresh_boss_panel()
    _refresh_board_cards()
    _refresh_drop_zone_textures()
    _refresh_equipment_labels()
    _refresh_slot_state_visuals()
    _queue_restart_if_finished()


func _refresh_boss_panel() -> void:
    boss_art_texture.texture = BOSS_CARD_TEXTURE
    boss_title_label.text = match_state.boss_state.boss_name
    boss_life_label.text = "%d/%d" % [
        match_state.boss_state.current_health,
        match_state.boss_state.max_health
    ]


func _refresh_board_cards() -> void:
 for child in board_card_list.get_children():
  child.queue_free()

 var active_cards = match_state.board_state.get_active_cards()
 var next_board_card_ids: Array[String] = []
 var changed_slots: Array[int] = []

 for i in range(active_cards.size()):
  var card = active_cards[i]
  if card == null:
   next_board_card_ids.append("")
   var spacer = Control.new()
   spacer.custom_minimum_size = EMPTY_BOARD_SLOT_SIZE
   spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
   board_card_list.add_child(spacer)
   continue
  var card_key := _get_card_unique_key(card)
  next_board_card_ids.append(card_key)
  if board_visuals_initialized:
   var previous_key := ""
   if i < last_board_card_ids.size():
    previous_key = last_board_card_ids[i]
   if previous_key != card_key:
    changed_slots.append(i)
  var card_view = CARD_VIEW_SCENE.instantiate()
  board_card_list.add_child(card_view)
  card_view.setup(card, i)
  if board_visuals_initialized and i in changed_slots:
   if card_view.has_method("set_content_visible"):
    card_view.set_content_visible(false)
   card_view.modulate.a = 0.0

 last_board_card_ids = next_board_card_ids
 if board_visuals_initialized and changed_slots.size() > 0:
  call_deferred("_animate_new_board_cards", changed_slots)
 board_visuals_initialized = true


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


func _animate_new_board_cards(slot_indices: Array[int]) -> void:
 await get_tree().process_frame
 await get_tree().process_frame

 if deck_card_texture == null or not is_instance_valid(deck_card_texture):
  return

 var source_rect: Rect2 = deck_card_texture.get_global_rect()
 var scene_origin := global_position
 var tweens: Array = []

 for board_index in slot_indices:
  var card_view = _get_board_card_view(board_index)
  if card_view == null or not is_instance_valid(card_view):
   continue

  if card_view is Control:
   if card_view.has_method("set_content_visible"):
    card_view.set_content_visible(false)
   card_view.modulate.a = 0.0

  var temp_card := TextureRect.new()
  temp_card.texture = CARD_BACK_TEXTURE
  temp_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  temp_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  temp_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
  temp_card.z_index = 100
  temp_card.position = source_rect.position - scene_origin
  temp_card.size = source_rect.size
  add_child(temp_card)

  var target_rect: Rect2 = card_view.get_global_rect()
  var tween = create_tween()
  tween.set_parallel(true)
  tween.tween_property(temp_card, "position", target_rect.position - scene_origin, 0.9)
  tween.tween_property(temp_card, "size", target_rect.size, 0.9)
  tween.finished.connect(func():
   if is_instance_valid(temp_card):
    temp_card.queue_free()
   if is_instance_valid(card_view):
    if card_view.has_method("set_content_visible"):
     card_view.set_content_visible(true)
    card_view.modulate.a = 1.0
  )
  tweens.append(tween)


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


func can_resolve_monster_into_shield(slot_name: String) -> bool:
    if restart_pending:
        return false

    var card = get_slot_card(slot_name)
    if card == null or _get_card_family(card) != "shield":
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
            if family == "monster":
                return can_resolve_monster_into_shield("left_hand")
            if match_state.player_state.left_hand_card != null or match_state.player_state.left_hand_exhausted:
                return false
            return family in ["weapon", "shield", "potion", "spell", "artifact", "coin", "chest"]
        elif target_slot == "right_hand":
            if family == "monster":
                return can_resolve_monster_into_shield("right_hand")
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

    if source == "backpack" and target_slot == "discard":
        return family in ["weapon", "shield", "potion", "spell", "artifact", "coin", "chest"]

    if source in ["left_hand", "right_hand"] and target_slot == "boss":
        return family == "weapon" and can_use_slot_weapon_on_monster(source)

    if source in ["left_hand", "right_hand"] and target_slot == "backpack":
        if family == "":
            return false
        return match_state.player_state.backpack_cards.size() < match_state.player_state.backpack_capacity

    if source in ["left_hand", "right_hand"] and target_slot == "discard":
        return family in ["weapon", "shield", "potion", "spell", "artifact", "coin", "chest"]

    return false


func handle_slot_to_slot_drop(source_slot: String, target_slot: String) -> void:
    if restart_pending or source_slot == target_slot:
        return

    var moved := false
    if source_slot == "backpack" and target_slot == "left_hand":
        moved = _move_backpack_to_hand(true)
    elif source_slot == "backpack" and target_slot == "right_hand":
        moved = _move_backpack_to_hand(false)
    elif source_slot == "backpack" and target_slot == "discard":
        moved = _discard_backpack_card()
    elif source_slot == "left_hand" and target_slot == "backpack":
        moved = _move_hand_to_backpack(true)
    elif source_slot == "right_hand" and target_slot == "backpack":
        moved = _move_hand_to_backpack(false)
    elif source_slot == "left_hand" and target_slot == "discard":
        moved = _discard_hand_card(true)
    elif source_slot == "right_hand" and target_slot == "discard":
        moved = _discard_hand_card(false)

    if moved:
        set_status("Moved card from %s to %s." % [source_slot.replace("_", " "), target_slot.replace("_", " ")])
    else:
        set_status("Could not move card from %s to %s." % [source_slot.replace("_", " "), target_slot.replace("_", " ")])

    _refresh_ui()


func _discard_backpack_card() -> bool:
    if match_state.player_state.backpack_cards.is_empty():
        return false

    var card = match_state.player_state.remove_backpack_card_at(0)
    if card == null:
        return false

    _mark_runtime_card_resolved(card)
    _mark_runtime_card_destroyed(card)
    return true


func _discard_hand_card(is_left_hand: bool) -> bool:
    var card = match_state.player_state.left_hand_card if is_left_hand else match_state.player_state.right_hand_card
    if card == null:
        return false

    if is_left_hand:
        match_state.player_state.clear_left_hand_card()
        match_state.player_state.exhaust_left_hand()
    else:
        match_state.player_state.clear_right_hand_card()
        match_state.player_state.exhaust_right_hand()

    _mark_runtime_card_resolved(card)
    _mark_runtime_card_exhausted(card)
    _mark_runtime_card_destroyed(card)
    return true


func _move_backpack_to_hand(is_left_hand: bool) -> bool:
    if match_state.player_state.backpack_cards.is_empty():
        return false

    var card = match_state.player_state.remove_backpack_card_at(0)
    if card == null:
        return false

    var family := _get_card_family(card)
    if is_left_hand:
        if match_state.player_state.left_hand_exhausted or match_state.player_state.left_hand_card != null:
            match_state.player_state.backpack_cards.insert(0, card)
            if card is CardRuntimeState:
                card.set_zone("backpack")
            elif card is Dictionary:
                card["zone"] = "backpack"
            return false
        if family == "coin":
            match_state.player_state.add_temporary_gold(_get_card_runtime_value(card))
            _mark_runtime_card_resolved(card)
            _mark_runtime_card_exhausted(card)
            _mark_runtime_card_destroyed(card)
            match_state.player_state.exhaust_left_hand()
            return true
        if family == "potion":
            match_state.player_state.heal(_get_card_runtime_value(card))
            _mark_runtime_card_resolved(card)
            _mark_runtime_card_exhausted(card)
            _mark_runtime_card_destroyed(card)
            match_state.player_state.exhaust_left_hand()
            return true
    else:
        if match_state.player_state.right_hand_exhausted or match_state.player_state.right_hand_card != null:
            match_state.player_state.backpack_cards.insert(0, card)
            if card is CardRuntimeState:
                card.set_zone("backpack")
            elif card is Dictionary:
                card["zone"] = "backpack"
            return false
        if family == "coin":
            match_state.player_state.add_temporary_gold(_get_card_runtime_value(card))
            _mark_runtime_card_resolved(card)
            _mark_runtime_card_exhausted(card)
            _mark_runtime_card_destroyed(card)
            match_state.player_state.exhaust_right_hand()
            return true
        if family == "potion":
            match_state.player_state.heal(_get_card_runtime_value(card))
            _mark_runtime_card_resolved(card)
            _mark_runtime_card_exhausted(card)
            _mark_runtime_card_destroyed(card)
            match_state.player_state.exhaust_right_hand()
            return true

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


func _mark_runtime_card_resolved(card) -> void:
    if card is CardRuntimeState:
        card.mark_resolved()
    elif card is Dictionary:
        card["is_resolved"] = true


func _mark_runtime_card_exhausted(card) -> void:
    if card is CardRuntimeState:
        card.mark_exhausted()
    elif card is Dictionary:
        card["is_exhausted"] = true


func _mark_runtime_card_destroyed(card) -> void:
    if card is CardRuntimeState:
        card.mark_destroyed()
    elif card is Dictionary:
        card["is_destroyed"] = true


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


func _handle_monster_to_shield(board_index: int, is_left_hand: bool) -> void:
    var shield_before = get_slot_card("left_hand" if is_left_hand else "right_hand")
    var shield_before_value := _get_card_runtime_value(shield_before)
    var monster_before = null
    var active_cards = match_state.board_state.get_active_cards()
    if board_index >= 0 and board_index < active_cards.size():
        monster_before = active_cards[board_index]
    var monster_value := _get_card_runtime_value(monster_before)
    var health_before := match_state.player_state.current_health

    var success := false
    if is_left_hand:
        success = combat_controller.resolve_monster_into_left_hand_shield(board_index)
    else:
        success = combat_controller.resolve_monster_into_right_hand_shield(board_index)

    if not success:
        set_status("Could not resolve monster into shield.")
        _refresh_ui()
        return

    await _animate_board_card_resolution(board_index)

    var shield_after = get_slot_card("left_hand" if is_left_hand else "right_hand")
    var damage_taken := health_before - match_state.player_state.current_health
    if shield_after != null:
        set_status("Shield blocked %d and remains at %d." % [monster_value, _get_card_runtime_value(shield_after)])
    elif damage_taken > 0:
        set_status("Shield broke. Player took %d damage." % damage_taken)
    else:
        set_status("Shield broke after blocking %d." % shield_before_value)

    _refresh_ui()


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


func handle_weapon_drop_on_boss(source_hand: String) -> void:
    if restart_pending:
        return

    var before_health := match_state.boss_state.current_health
    var success := false
    if source_hand == "left_hand":
        success = combat_controller.use_left_hand_weapon_on_boss()
    elif source_hand == "right_hand":
        success = combat_controller.use_right_hand_weapon_on_boss()

    if not success:
        set_status("Could not use weapon on boss.")
        _refresh_ui()
        return

    var after_health := match_state.boss_state.current_health
    if after_health <= 0:
        set_status("Gravebound Warden defeated.")
    else:
        set_status("Weapon hit the boss. %d to %d." % [before_health, after_health])

    _refresh_ui()


func _apply_visual_theme() -> void:
    player_health_label.add_theme_color_override("font_color", HUD_TEXT)
    boss_health_label.add_theme_color_override("font_color", HUD_TEXT)
    round_label.add_theme_color_override("font_color", HUD_TEXT)
    gold_label.add_theme_color_override("font_color", SUCCESS_TEXT)
    board_title.add_theme_color_override("font_color", HUD_MUTED)
    board_title.add_theme_font_size_override("font_size", 15)
    deck_count_label.add_theme_color_override("font_color", HUD_MUTED)
    deck_count_label.add_theme_font_size_override("font_size", 14)
    player_label.add_theme_color_override("font_color", HUD_MUTED)

    _style_zone(left_hand_drop_zone, PANEL_BORDER, Color(0, 0, 0, 0), 0)
    _style_zone(boss_drop_zone, Color("8a6651"), Color(0, 0, 0, 0), 0)
    _style_zone(player_avatar_drop_zone, Color("8d7867"), Color(0, 0, 0, 0), 0)
    _style_zone(right_hand_drop_zone, PANEL_BORDER, Color(0, 0, 0, 0), 0)
    _style_zone(backpack_drop_zone, Color("6e7e66"), Color(0, 0, 0, 0), 0)
    _style_zone(discard_drop_zone, DISCARD_BORDER, Color(0, 0, 0, 0), 0)

    _style_loadout_label(left_hand_label)
    _style_loadout_label(player_label)
    _style_loadout_label(right_hand_label)
    _style_loadout_label(backpack_label)
    _style_slot_text(left_hand_name_label, left_hand_type_label, left_hand_value_label)
    _style_slot_text(right_hand_name_label, right_hand_type_label, right_hand_value_label)
    _style_slot_text(backpack_name_label, backpack_type_label, backpack_value_label)
    boss_title_label.add_theme_color_override("font_color", Color("f7ead7"))
    boss_title_label.add_theme_font_size_override("font_size", 19)
    var boss_life_style := StyleBoxFlat.new()
    boss_life_style.bg_color = Color("5e2726")
    boss_life_style.border_color = Color("d7b17a")
    boss_life_style.border_width_left = 2
    boss_life_style.border_width_top = 2
    boss_life_style.border_width_right = 2
    boss_life_style.border_width_bottom = 2
    boss_life_style.corner_radius_top_left = 10
    boss_life_style.corner_radius_top_right = 10
    boss_life_style.corner_radius_bottom_right = 10
    boss_life_style.corner_radius_bottom_left = 10
    boss_life_bar.add_theme_stylebox_override("panel", boss_life_style)
    boss_life_label.add_theme_color_override("font_color", Color("ffffff"))
    boss_life_label.add_theme_font_size_override("font_size", 18)
    var player_life_style := StyleBoxFlat.new()
    player_life_style.bg_color = Color("5e2726")
    player_life_style.border_color = Color("d7b17a")
    player_life_style.border_width_left = 2
    player_life_style.border_width_top = 2
    player_life_style.border_width_right = 2
    player_life_style.border_width_bottom = 2
    player_life_style.corner_radius_top_left = 10
    player_life_style.corner_radius_top_right = 10
    player_life_style.corner_radius_bottom_right = 10
    player_life_style.corner_radius_bottom_left = 10
    player_life_bar.add_theme_stylebox_override("panel", player_life_style)
    player_life_label.add_theme_color_override("font_color", Color("ffffff"))
    player_life_label.add_theme_font_size_override("font_size", 18)

    status_label.add_theme_font_size_override("font_size", 15)


func _style_zone(panel: PanelContainer, border_color: Color, fill_color: Color = PANEL_FILL, border_width: int = 2) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = fill_color
    style.border_color = border_color
    style.border_width_left = border_width
    style.border_width_top = border_width
    style.border_width_right = border_width
    style.border_width_bottom = border_width
    style.corner_radius_top_left = 18
    style.corner_radius_top_right = 18
    style.corner_radius_bottom_right = 18
    style.corner_radius_bottom_left = 18
    style.shadow_color = Color(0, 0, 0, 0)
    style.shadow_size = 0
    panel.add_theme_stylebox_override("panel", style)


func _refresh_slot_state_visuals() -> void:
    _reset_slot_visual_state(left_hand_drop_zone, left_hand_texture, PANEL_BORDER)
    _reset_slot_visual_state(right_hand_drop_zone, right_hand_texture, PANEL_BORDER)
    _reset_slot_visual_state(backpack_drop_zone, backpack_texture, Color("6e7e66"))
    _style_zone(player_avatar_drop_zone, Color("8d7867"), Color(0, 0, 0, 0), 0)
    _style_zone(boss_drop_zone, Color("8a6651"), Color(0, 0, 0, 0), 0)
    _style_zone(discard_drop_zone, DISCARD_BORDER, Color(0, 0, 0, 0), 0)
    player_avatar_texture.modulate = Color(1, 1, 1, 1)
    boss_art_texture.modulate = Color(1, 1, 1, 1)
    discard_texture.modulate = Color(1, 1, 1, 1)

    if match_state.player_state.left_hand_exhausted:
        _apply_exhausted_slot_visual(left_hand_drop_zone, left_hand_texture)

    if match_state.player_state.right_hand_exhausted:
        _apply_exhausted_slot_visual(right_hand_drop_zone, right_hand_texture)


func _reset_slot_visual_state(panel: PanelContainer, texture_rect: TextureRect, border_color: Color) -> void:
    _style_zone(panel, border_color, Color(0, 0, 0, 0), 0)
    panel.modulate = Color(1, 1, 1, 1)
    texture_rect.modulate = Color(1, 1, 1, 1)


func _apply_exhausted_slot_visual(panel: PanelContainer, texture_rect: TextureRect) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0, 0, 0, 0)
    style.border_color = Color("d15b5b")
    style.border_width_left = 0
    style.border_width_top = 0
    style.border_width_right = 0
    style.border_width_bottom = 0
    style.corner_radius_top_left = 18
    style.corner_radius_top_right = 18
    style.corner_radius_bottom_right = 18
    style.corner_radius_bottom_left = 18
    style.shadow_color = Color(0, 0, 0, 0)
    style.shadow_size = 0
    panel.add_theme_stylebox_override("panel", style)
    texture_rect.modulate = Color(0.62, 0.3, 0.3, 1.0)


func preview_drop_zone_state(target_slot: String, is_valid: bool) -> void:
    var tint := VALID_DROP_TINT if is_valid else INVALID_DROP_TINT
    match target_slot:
        "left_hand":
            left_hand_texture.modulate = tint
        "right_hand":
            right_hand_texture.modulate = tint
        "backpack":
            backpack_texture.modulate = tint
        "player_avatar":
            player_avatar_texture.modulate = tint
        "boss":
            boss_art_texture.modulate = tint
        "discard":
            discard_texture.modulate = tint


func clear_all_drop_zone_previews() -> void:
    _refresh_slot_state_visuals()


func _style_loadout_label(label: Label) -> void:
    label.add_theme_color_override("font_color", HUD_TEXT)
    label.add_theme_font_size_override("font_size", 13)


func _style_slot_text(name_label: Label, type_label: Label, value_label: Label) -> void:
    name_label.add_theme_color_override("font_color", Color("f7ead7"))
    name_label.add_theme_font_size_override("font_size", 17)
    type_label.add_theme_color_override("font_color", Color("ddd0bb"))
    type_label.add_theme_font_size_override("font_size", 12)
    value_label.add_theme_color_override("font_color", Color("ffffff"))
    value_label.add_theme_font_size_override("font_size", 18)


func _queue_restart_if_finished() -> void:
    if restart_pending:
        return

    if outcome_controller == null or match_state == null:
        return

    var outcome := outcome_controller.check_outcome(match_state)
    if outcome not in ["failure", "victory"]:
        return

    restart_pending = true
    call_deferred("_begin_combat_reset", outcome)


func _begin_combat_reset(outcome: String) -> void:
    _run_combat_reset(outcome)


func _run_combat_reset(outcome: String) -> void:
    if outcome == "victory":
        set_status("Boss defeated. Restarting combat...")
    else:
        set_status("You died. Restarting...")
    await get_tree().create_timer(0.9).timeout
    _build_test_match_state()
    restart_pending = false
    set_status("Fresh restart.")
    _refresh_ui()

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

 var active_cards = match_state.board_state.get_active_cards()
 if board_index >= 0 and board_index < active_cards.size():
  var board_card = active_cards[board_index]
  if _get_card_family(board_card) == "monster" and can_resolve_monster_into_shield("left_hand"):
   await _handle_monster_to_shield(board_index, true)
   return

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

 var active_cards = match_state.board_state.get_active_cards()
 if board_index >= 0 and board_index < active_cards.size():
  var board_card = active_cards[board_index]
  if _get_card_family(board_card) == "monster" and can_resolve_monster_into_shield("right_hand"):
   await _handle_monster_to_shield(board_index, false)
   return

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


func _get_card_unique_key(card) -> String:
 if card is CardRuntimeState:
  return card.card_id

 if card is Dictionary:
  return str(card.get("instance_id", card.get("id", "")))

 return ""
