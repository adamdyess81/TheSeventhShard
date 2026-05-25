extends Control

const GAME_DATA_LOADER_SCRIPT = preload("res://core/GameDataLoader.gd")
const PROGRESSION_SCRIPT = preload("res://core/Progression.gd")
const CARD_RUNTIME_STATE_SCRIPT = preload("res://cards/CardRuntimeState.gd")
const SHARED_DECK_STATE_SCRIPT = preload("res://combat/SharedDeckState.gd")
const BOARD_STATE_SCRIPT = preload("res://combat/BoardState.gd")
const PLAYER_COMBAT_STATE_SCRIPT = preload("res://combat/PlayerCombatState.gd")
const BOSS_COMBAT_STATE_SCRIPT = preload("res://combat/BossCombatState.gd")
const MATCH_COMBAT_STATE_SCRIPT = preload("res://combat/MatchCombatState.gd")
const RESOLUTION_CONTROLLER_SCRIPT = preload("res://combat/ResolutionController.gd")
const OUTCOME_CONTROLLER_SCRIPT = preload("res://combat/OutcomeController.gd")
const COMBAT_CONTROLLER_SCRIPT = preload("res://combat/CombatController.gd")
const RUN_CONTEXT_SCRIPT = preload("res://core/RunContext.gd")
const HOVEL_SHOP_SCRIPT = preload("res://core/HovelShop.gd")
const SHIFT_FATE_PREVIEW_COUNT := 6
const SHIFT_FATE_SELECTION_COUNT := 3

const DEFAULT_PLAYER_STARTING_HEALTH := 15
const DEFAULT_PLAYER_MAX_DECK_SIZE := 15
const BOSS_STARTING_HEALTH := 12
const ACTIVE_BOARD_CAP := 4
const STARTING_BACKPACK_CAPACITY := 1
const PLAYER_PROFILE_PATH := "res://profiles/player_main.json"
const HOVEL_SCENE_PATH := "res://hovel/hovel_scene.tscn"
const PROFILE_DECK_SCRIPT = preload("res://core/ProfileDeck.gd")
const CARD_VIEW_SCENE = preload("res://cards/card_view.tscn")
const LEFT_HAND_PLACEHOLDER = preload("res://art/ui/LeftHand Placement Card.png")
const RIGHT_HAND_PLACEHOLDER = preload("res://art/ui/RightHand Placement Card.png")
const BACKPACK_PLACEHOLDER = preload("res://art/ui/Backpack Placement Card.png")
const BACKGROUND_TEXTURE = preload("res://art/backgrounds/Ossara-Titled-Arena-blured.png")
const CARD_BACK_TEXTURE = preload("res://art/ui/CardBack.png")
const PLAYER_DAMAGE_SLASH_TEXTURE = preload("res://art/ui/DamageSlash50.png")
const SWORD_DAMAGE_SLASH_TEXTURE = preload("res://art/ui/SwordDamageSlash.png")
const BACKPACK_DROP_SFX_PATH := "res://audio/sound fx/backpack_drop.wav"
const DEAL_CARDS_SFX_PATH := "res://audio/sound fx/deal_cards.wav"
const DISCARD_SFX_PATH := "res://audio/sound fx/discard.wav"
const DRINK_POTION_SFX_PATH := "res://audio/sound fx/drink_potion.wav"
const DROP_CARD_SFX_PATH := "res://audio/sound fx/drop_card.wav"
const GAIN_COINS_SFX_PATH := "res://audio/sound fx/gain_coins.wav"
const GRAVEBOUND_WARDEN_HURT_SFX_PATH := "res://audio/sound fx/gravebound_warden_hurt.wav"
const GRAVEBOUND_WARDEN_SPECIAL_SFX_PATH := "res://audio/sound fx/gravebound_warden_special.wav"
const PLAYER_HURT_SFX_PATHS := [
	"res://audio/sound fx/player_hurt_001_male.wav",
	"res://audio/sound fx/player_hurt_002_male.wav",
	"res://audio/sound fx/player_hurt_003_male.wav",
	"res://audio/sound fx/player_hurt_004_male.wav",
	"res://audio/sound fx/player_hurt_005_male.wav"
]
const SHIELD_DEFEND_SFX_PATH := "res://audio/sound fx/shield_defend.wav"
const SWORD_SWING_SFX_PATH := "res://audio/sound fx/sword_swing.wav"
const TREASURE_CHEST_SFX_PATH := "res://audio/sound fx/treasure_chest.wav"
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
const DEFAULT_MATCH_PATH := "res://data/matches/ossara_baseline_match_01.json"
const HOVEL_SHOP_RULES_PATH := "res://data/rewards/hovel_shop_common.json"
const DEFAULT_BOSS_ID := "ossaran_lich"
const DEFAULT_BOSS_NAME := "Ossaran Lich"
const DEFAULT_MONSTER_DECK_ID := "ossaran_lich_deck"
const BOSS_DIRECTORY_PATH := "res://data/bosses"
const DECK_DIRECTORY_PATH := "res://data/decks"
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
@onready var victory_stinger_player = $VictoryStinger
@onready var defeat_stinger_player = $DefeatStinger
@onready var fade_overlay = $FadeOverlay
@onready var end_modal_overlay = $EndModalOverlay
@onready var end_modal = $EndModalOverlay/EndModalCenter/EndModal
@onready var end_modal_title = $EndModalOverlay/EndModalCenter/EndModal/EndModalContent/EndModalTitle
@onready var end_modal_stats = $EndModalOverlay/EndModalCenter/EndModal/EndModalContent/EndModalStats
@onready var retry_button = $EndModalOverlay/EndModalCenter/EndModal/EndModalContent/EndModalButtons/RetryButton
@onready var quit_button = $EndModalOverlay/EndModalCenter/EndModal/EndModalContent/EndModalButtons/QuitButton
@onready var shift_fate_modal_overlay = $ShiftFateModalOverlay
@onready var shift_fate_modal = $ShiftFateModalOverlay/ShiftFateModalCenter/ShiftFateModal
@onready var shift_fate_title = $ShiftFateModalOverlay/ShiftFateModalCenter/ShiftFateModal/ShiftFateContent/ShiftFateTitle
@onready var shift_fate_subtitle = $ShiftFateModalOverlay/ShiftFateModalCenter/ShiftFateModal/ShiftFateContent/ShiftFateSubtitle
@onready var shift_fate_preview_grid = $ShiftFateModalOverlay/ShiftFateModalCenter/ShiftFateModal/ShiftFateContent/ShiftFatePreviewGrid
@onready var shift_fate_done_button = $ShiftFateModalOverlay/ShiftFateModalCenter/ShiftFateModal/ShiftFateContent/ShiftFateFooter/ShiftFateDoneButton
@onready var root_layout = $RootLayout

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

var match_state = null
var resolution_controller = null
var outcome_controller = null
var combat_controller = null
var restart_pending := false
var left_hand_visual_card_id := ""
var right_hand_visual_card_id := ""
var backpack_visual_card_id := ""
var last_board_card_ids: Array[String] = []
var board_visuals_initialized := false
var escape_was_pressed := false
var root_layout_base_position := Vector2.ZERO
var background_base_position := Vector2.ZERO
var player_profile_data: Dictionary = {}
var current_match_config: Dictionary = {}
var current_boss_data: Dictionary = {}
var current_reward_profile: Dictionary = {}
var current_boss_drop_table: Dictionary = {}
var current_boss_texture: Texture2D = null
var data_loader = GAME_DATA_LOADER_SCRIPT.new()
var card_texture_cache: Dictionary = {}
var card_sfx_cache: Dictionary = {}
var common_sfx_cache: Dictionary = {}
var shift_fate_selected_slot := ""
var shift_fate_preview_cards: Array = []
var shift_fate_selected_cards: Array = []
var shift_fate_preview_entries: Array = []
var shift_fate_required_selection_count := SHIFT_FATE_SELECTION_COUNT


func _ready() -> void:
    randomize()
    add_to_group("combat_scene")
    _build_battle_match_state()
    _apply_visual_theme()
    _start_battle_music()
    root_layout_base_position = root_layout.position
    background_base_position = background_texture.position
    retry_button.pressed.connect(_on_retry_battle_pressed)
    quit_button.pressed.connect(_on_quit_battle_pressed)
    shift_fate_done_button.pressed.connect(_on_shift_fate_done_pressed)
    set_status("Battle ready.")
    _refresh_ui()
    call_deferred("_play_battle_intro")


func _start_battle_music() -> void:
    if battle_music_player == null or battle_music_player.stream == null:
        return

    if victory_stinger_player != null and victory_stinger_player.playing:
        victory_stinger_player.stop()
    if defeat_stinger_player != null and defeat_stinger_player.playing:
        defeat_stinger_player.stop()

    if battle_music_player.stream is AudioStreamOggVorbis:
        battle_music_player.stream.loop = true

    if not battle_music_player.playing:
        battle_music_player.play()


func _resume_battle_music_from_outcome() -> void:
    var active_stinger: AudioStreamPlayer = null
    if defeat_stinger_player != null and defeat_stinger_player.playing:
        active_stinger = defeat_stinger_player
    elif victory_stinger_player != null and victory_stinger_player.playing:
        active_stinger = victory_stinger_player

    if active_stinger != null:
        active_stinger.volume_db = 0.0
        var fade_out := create_tween()
        fade_out.tween_property(active_stinger, "volume_db", -24.0, 0.35)
        await fade_out.finished
        active_stinger.stop()
        active_stinger.volume_db = 0.0

    if battle_music_player == null or battle_music_player.stream == null:
        return

    battle_music_player.stop()
    battle_music_player.volume_db = -24.0
    battle_music_player.play()

    var fade_in := create_tween()
    fade_in.tween_property(battle_music_player, "volume_db", 0.0, 0.45)


func _play_outcome_music(is_victory: bool) -> void:
    if battle_music_player != null and battle_music_player.playing:
        battle_music_player.stop()

    if is_victory:
        if defeat_stinger_player != null and defeat_stinger_player.playing:
            defeat_stinger_player.stop()
        if victory_stinger_player != null:
            victory_stinger_player.play()
    else:
        if victory_stinger_player != null and victory_stinger_player.playing:
            victory_stinger_player.stop()
        if defeat_stinger_player != null:
            defeat_stinger_player.play()


func _play_battle_intro() -> void:
    _hide_end_modal()
    if fade_overlay != null:
        move_child(fade_overlay, get_child_count() - 1)
        fade_overlay.visible = true
        fade_overlay.modulate.a = 1.0

    await get_tree().process_frame

    var fade_tween = create_tween()
    if fade_overlay != null:
        fade_tween.tween_property(fade_overlay, "modulate:a", 0.0, 1.0)

    await get_tree().create_timer(0.2).timeout
    _deal_opening_board()

    await fade_tween.finished
    if fade_overlay != null:
        fade_overlay.visible = false


func _play_damage_screen_shake() -> void:
    if root_layout == null or background_texture == null:
        return

    root_layout.position = root_layout_base_position
    background_texture.position = background_base_position

    var offsets := [
        Vector2(-14, 0),
        Vector2(12, -6),
        Vector2(-10, 8),
        Vector2(7, -4),
        Vector2(0, 0)
    ]

    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_OUT)

    for offset in offsets:
        tween.tween_property(root_layout, "position", root_layout_base_position + offset, 0.04)
        tween.parallel().tween_property(background_texture, "position", background_base_position + (offset * 0.45), 0.04)


func _play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
    if stream == null:
        return

    var player := AudioStreamPlayer.new()
    player.stream = stream
    player.volume_db = volume_db
    add_child(player)
    player.finished.connect(Callable(player, "queue_free"))
    player.play()


func _play_random_player_hurt_sfx() -> void:
    if PLAYER_HURT_SFX_PATHS.is_empty():
        return
    var sound = _load_common_sfx(PLAYER_HURT_SFX_PATHS[randi() % PLAYER_HURT_SFX_PATHS.size()])
    _play_sfx(sound)


func _play_monster_attack_sfx(card) -> void:
    var stream = _get_card_sfx(card)
    if stream != null:
        _play_sfx(stream)


func _play_loot_drop_sfx(card, target_slot: String) -> void:
    if card == null:
        return

    _play_sfx(_load_common_sfx(DROP_CARD_SFX_PATH))

    if target_slot == "backpack":
        _play_sfx(_load_common_sfx(BACKPACK_DROP_SFX_PATH))

    if _get_card_family(card) == "chest" and target_slot in ["left_hand", "right_hand", "backpack"]:
        _play_sfx(_load_common_sfx(TREASURE_CHEST_SFX_PATH))


func _show_damage_slash_at_rect(target_rect: Rect2, texture: Texture2D) -> void:
    if texture == null:
        return

    var slash := TextureRect.new()
    slash.texture = texture
    slash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    slash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    slash.z_index = 150

    var slash_size := Vector2(
        max(target_rect.size.x * 0.72, 96.0),
        max(target_rect.size.y * 0.36, 56.0)
    )
    slash.size = slash_size
    slash.position = target_rect.position - global_position + ((target_rect.size - slash_size) * 0.5)
    add_child(slash)

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(slash, "modulate:a", 0.0, 0.28)
    tween.tween_property(slash, "scale", Vector2(1.08, 1.08), 0.28)
    tween.finished.connect(Callable(slash, "queue_free"))


func _show_player_damage_slash() -> void:
    if player_avatar_drop_zone == null:
        return
    _show_damage_slash_at_rect(player_avatar_drop_zone.get_global_rect(), PLAYER_DAMAGE_SLASH_TEXTURE)


func _show_boss_damage_slash() -> void:
    if boss_drop_zone == null:
        return
    _show_damage_slash_at_rect(boss_drop_zone.get_global_rect(), SWORD_DAMAGE_SLASH_TEXTURE)


func _show_board_card_damage_slash(board_index: int) -> void:
    var card_view = _get_board_card_view(board_index)
    if card_view == null or not is_instance_valid(card_view):
        return
    _show_damage_slash_at_rect(card_view.get_global_rect(), SWORD_DAMAGE_SLASH_TEXTURE)


func _get_adjacent_monster_board_indices(board_index: int) -> Array[int]:
    var adjacent_indices: Array[int] = []
    if match_state == null or match_state.board_state == null:
        return adjacent_indices

    var active_cards = match_state.board_state.get_active_cards()
    var left_index := board_index - 1
    var right_index := board_index + 1

    if left_index >= 0 and left_index < active_cards.size():
        var left_card = active_cards[left_index]
        if left_card != null and _get_card_family(left_card) == "monster":
            adjacent_indices.append(left_index)

    if right_index >= 0 and right_index < active_cards.size():
        var right_card = active_cards[right_index]
        if right_card != null and _get_card_family(right_card) == "monster":
            adjacent_indices.append(right_index)

    return adjacent_indices


func _deal_opening_board() -> void:
    if match_state == null or match_state.board_state == null or match_state.shared_deck_state == null:
        return

    match_state.board_state.refill_from_deck(match_state.shared_deck_state)
    _refresh_ui()



func _build_battle_match_state() -> void:
    left_hand_visual_card_id = ""
    right_hand_visual_card_id = ""
    backpack_visual_card_id = ""
    last_board_card_ids.clear()
    board_visuals_initialized = false

    data_loader.build_card_registry()
    player_profile_data = data_loader.load_json(PLAYER_PROFILE_PATH)
    var player_level := int(player_profile_data.get("player_level", 1))
    var player_starting_health_base := int(player_profile_data.get(
        "starting_health_base",
        DEFAULT_PLAYER_STARTING_HEALTH
    ))
    var player_max_deck_size_base := int(player_profile_data.get(
        "max_deck_size_base",
        DEFAULT_PLAYER_MAX_DECK_SIZE
    ))
    var player_starting_health := PROGRESSION_SCRIPT.get_effective_max_health(
        player_starting_health_base,
        player_level
    )
    var player_max_deck_size := PROGRESSION_SCRIPT.get_effective_max_deck_size(
        player_max_deck_size_base,
        player_level
    )

    var player_deck_counts := PROFILE_DECK_SCRIPT.get_selected_deck_card_counts(player_profile_data)
    var player_deck_entries := PROFILE_DECK_SCRIPT.build_deck_entries(player_deck_counts)
    var player_deck_data := {"cards": player_deck_entries}
    var resolved_player_cards := data_loader.resolve_deck_cards(player_deck_data)

    var match_config := data_loader.load_json(DEFAULT_MATCH_PATH)
    current_match_config = match_config.duplicate(true)
    var selected_battle: Dictionary = RUN_CONTEXT_SCRIPT.get_battle_selection()
    var boss_id := str(selected_battle.get("boss_id", match_config.get("boss_id", DEFAULT_BOSS_ID))).strip_edges()
    var boss_data := _load_boss_data(boss_id)
    current_boss_data = boss_data.duplicate(true)
    current_boss_drop_table = _load_boss_drop_table(boss_id)
    var monster_deck_id := str(selected_battle.get("monster_deck_id", "")).strip_edges()
    if monster_deck_id == "":
        monster_deck_id = str(
            boss_data.get(
                "monster_deck_id",
                match_config.get("monster_deck_id", DEFAULT_MONSTER_DECK_ID)
            )
        ).strip_edges()
    var monster_deck := _load_monster_deck(monster_deck_id)
    var reward_profile_id := str(match_config.get("reward_profile_id", "")).strip_edges()
    current_reward_profile = _load_reward_profile(reward_profile_id)
    var resolved_monster_cards := data_loader.resolve_monster_deck(monster_deck)

    var merged_cards := data_loader.build_shared_deck(resolved_player_cards, resolved_monster_cards)

    var shared_deck = SHARED_DECK_STATE_SCRIPT.new()
    shared_deck.setup(merged_cards)

    var board_state = BOARD_STATE_SCRIPT.new()
    board_state.setup(ACTIVE_BOARD_CAP)

    var player_state = PLAYER_COMBAT_STATE_SCRIPT.new()
    player_state.setup(
        player_starting_health,
        STARTING_BACKPACK_CAPACITY,
        player_max_deck_size
    )

    var boss_rules = boss_data.get("special_rule_ids", [])
    if not (boss_rules is Array):
        boss_rules = []
    var boss_values = boss_data.get("special_values", {})
    if not (boss_values is Dictionary):
        boss_values = {}
    if boss_values.has("reanimation_card_id"):
        var reanimation_card_id := str(boss_values.get("reanimation_card_id", "")).strip_edges()
        if reanimation_card_id != "":
            var reanimation_card_data := data_loader.get_card(reanimation_card_id)
            if not reanimation_card_data.is_empty():
                boss_values["reanimation_card_data"] = reanimation_card_data.duplicate(true)
    if boss_values.has("blight_card_id"):
        var blight_card_id := str(boss_values.get("blight_card_id", "")).strip_edges()
        if blight_card_id != "":
            var blight_card_data := data_loader.get_card(blight_card_id)
            if not blight_card_data.is_empty():
                boss_values["blight_card_data"] = blight_card_data.duplicate(true)

    var boss_state = BOSS_COMBAT_STATE_SCRIPT.new()
    boss_state.setup(
        str(boss_data.get("id", DEFAULT_BOSS_ID)),
        str(boss_data.get("name", DEFAULT_BOSS_NAME)),
        int(boss_data.get("base_health", BOSS_STARTING_HEALTH)),
        boss_rules,
        boss_values
    )

    match_state = MATCH_COMBAT_STATE_SCRIPT.new()
    match_state.setup(player_state, boss_state, board_state, shared_deck, 1)
    resolution_controller = RESOLUTION_CONTROLLER_SCRIPT.new()
    outcome_controller = OUTCOME_CONTROLLER_SCRIPT.new()

    combat_controller = COMBAT_CONTROLLER_SCRIPT.new()
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
    _play_pending_round_events()

    player_health_label.text = _build_player_health_text()
    boss_health_label.text = "Boss HP: %d/%d" % [
        match_state.boss_state.current_health,
        match_state.boss_state.max_health
    ]

    round_label.text = "Round: %d" % match_state.round_number
    gold_label.text = "Gold: %d" % match_state.player_state.temporary_gold
    deck_count_label.text = "Deck: %d" % match_state.shared_deck_state.remaining_count()
    player_life_label.text = _build_player_life_text()

    _refresh_boss_panel()
    _refresh_board_cards()
    _refresh_drop_zone_textures()
    _refresh_equipment_labels()
    _refresh_slot_state_visuals()
    _queue_restart_if_finished()


func _play_pending_round_events() -> void:
    if match_state == null:
        return

    var events = match_state.consume_pending_round_events()
    for event in events:
        var event_type := str(event.get("type", ""))
        if event_type == "boss_reanimation":
            _animate_boss_summon_to_deck(str(event.get("card_id", "")))
            _play_sfx(_load_common_sfx(GRAVEBOUND_WARDEN_SPECIAL_SFX_PATH))
        elif event_type == "boss_blight":
            _animate_boss_summon_to_deck(str(event.get("card_id", "")))
        elif event_type == "boss_retaliation":
            _show_player_damage_slash()
            _play_damage_screen_shake()
            _play_random_player_hurt_sfx()
            _play_sfx(_load_common_sfx(GRAVEBOUND_WARDEN_SPECIAL_SFX_PATH))
        elif event_type == "poison_tick":
            _show_player_damage_slash()
            _play_damage_screen_shake()
            _play_random_player_hurt_sfx()


func _build_player_health_text() -> String:
    var text := "Player HP: %d/%d" % [
        match_state.player_state.current_health,
        match_state.player_state.max_health
    ]
    var conditions: Array[String] = []
    if match_state.player_state.poison_counters > 0:
        conditions.append("Poison %d" % match_state.player_state.poison_counters)
    if match_state.player_state.disease_counters > 0:
        conditions.append("Disease %d" % match_state.player_state.disease_counters)
    if not conditions.is_empty():
        text += " | " + " | ".join(conditions)
    return text


func _build_player_life_text() -> String:
    var text := "%d/%d" % [
        match_state.player_state.current_health,
        match_state.player_state.max_health
    ]
    if match_state.player_state.poison_counters > 0:
        text += " | P:%d" % match_state.player_state.poison_counters
    if match_state.player_state.disease_counters > 0:
        text += " | D:%d" % match_state.player_state.disease_counters
    return text


func _animate_boss_summon_to_deck(card_id: String) -> void:
    if boss_drop_zone == null or deck_card_texture == null:
        return

    var summon_texture = _get_card_texture(data_loader.get_card(card_id))
    if summon_texture == null:
        summon_texture = CARD_BACK_TEXTURE

    var source_rect: Rect2 = boss_drop_zone.get_global_rect()
    var target_rect: Rect2 = deck_card_texture.get_global_rect()

    var summon_card := TextureRect.new()
    summon_card.texture = summon_texture
    summon_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    summon_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    summon_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    summon_card.z_index = 145

    var summon_size := Vector2(
        max(target_rect.size.x * 0.95, 96.0),
        max(target_rect.size.y * 0.95, 132.0)
    )
    summon_card.size = summon_size
    summon_card.position = source_rect.position - global_position + ((source_rect.size - summon_size) * 0.5)
    add_child(summon_card)

    _play_sfx(_load_common_sfx(DEAL_CARDS_SFX_PATH), -2.0)

    var target_position := target_rect.position - global_position + ((target_rect.size - summon_size) * 0.5)
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_parallel(true)
    tween.tween_property(summon_card, "position", target_position, 0.42)
    tween.tween_property(summon_card, "scale", Vector2(0.78, 0.78), 0.42)
    tween.tween_property(summon_card, "modulate:a", 0.0, 0.18).set_delay(0.24)
    tween.finished.connect(Callable(summon_card, "queue_free"))


func _refresh_boss_panel() -> void:
    boss_art_texture.texture = current_boss_texture
    boss_title_label.text = match_state.boss_state.boss_name
    boss_life_label.text = "%d/%d" % [
        match_state.boss_state.current_health,
        match_state.boss_state.max_health
    ]
    var boss_tooltip := _build_boss_tooltip_text()
    boss_drop_zone.tooltip_text = boss_tooltip
    boss_art_texture.tooltip_text = boss_tooltip
    boss_title_label.tooltip_text = boss_tooltip
    boss_life_label.tooltip_text = boss_tooltip


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
    var backpack_status := "ready"
    if match_state.player_state.backpack_exhausted:
        backpack_status = "exhausted"

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

        backpack_label.text = "Backpack: %s [%s]" % [", ".join(backpack_names), backpack_status]
    else:
        backpack_label.text = "Backpack: [empty] [%s]" % backpack_status



func _get_single_card_label(card) -> String:
    if card == null:
        return "[empty]"

    return _get_card_display_name(card)


func _get_card_name(card) -> String:
    if _is_runtime_card(card):
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


func _get_card_meta(card) -> Dictionary:
    if _is_runtime_card(card):
        return card.card_data

    if card is Dictionary:
        return card

    return {}


func _has_special_rule(card, special_rule: String) -> bool:
    var meta := _get_card_meta(card)
    var special_rules = meta.get("special_rules", [])
    if special_rules is Array:
        return special_rule in special_rules
    return false


func _get_special_rule_value(card, special_rule: String, default_value: int = 0) -> int:
    if not _has_special_rule(card, special_rule):
        return default_value

    var meta := _get_card_meta(card)
    var special_values = meta.get("special_values", {})
    if special_values is Dictionary and special_values.has(special_rule):
        return int(special_values.get(special_rule, default_value))
    return default_value


func _get_card_display_name(card) -> String:
    var meta := _get_card_meta(card)
    var display_name := str(meta.get("name", "")).strip_edges()
    if display_name != "":
        return display_name
    return _humanize_card_name(_get_card_name(card))


func _get_card_art_ref(card) -> String:
    return str(_get_card_meta(card).get("art_ref", "")).strip_edges()


func _get_card_sfx_ref(card) -> String:
    return str(_get_card_meta(card).get("sfx_ref", "")).strip_edges()


func _load_cached_texture(path: String):
    if path == "":
        return null

    if card_texture_cache.has(path):
        return card_texture_cache[path]

    var texture = load(path)
    if texture is Texture2D:
        card_texture_cache[path] = texture
        return texture

    return null


func _load_cached_sfx(path: String):
    if path == "":
        return null

    if card_sfx_cache.has(path):
        return card_sfx_cache[path]

    var stream = load(path)
    if stream is AudioStream:
        card_sfx_cache[path] = stream
        return stream

    return null


func _load_common_sfx(path: String):
    if path == "":
        return null

    if common_sfx_cache.has(path):
        return common_sfx_cache[path]

    var stream = load(path)
    if stream is AudioStream:
        common_sfx_cache[path] = stream
        return stream

    return null


func _build_boss_tooltip_text() -> String:
    if match_state == null or match_state.boss_state == null:
        return ""

    var lines: Array[String] = []
    lines.append(match_state.boss_state.boss_name)
    lines.append("")
    lines.append("Life: %d/%d" % [
        match_state.boss_state.current_health,
        match_state.boss_state.max_health
    ])

    var special_lines := _build_boss_special_lines(
        match_state.boss_state.special_rules,
        match_state.boss_state.special_values
    )
    if special_lines.is_empty():
        lines.append("Special: None")
    else:
        lines.append("Special:")
        for special_line in special_lines:
            lines.append("- " + special_line)

    return "\n".join(lines)


func _build_boss_special_lines(special_rules: Array, special_values: Dictionary) -> Array[String]:
    var lines: Array[String] = []
    for rule in special_rules:
        var key := str(rule).strip_edges().to_lower()
        if key == "":
            continue

        var label := _humanize_card_name(key)
        if special_values.has(key):
            label += ": %s" % str(special_values[key])
        lines.append(label)

    return lines


func _load_boss_data(boss_id: String) -> Dictionary:
    var normalized_boss_id := boss_id.strip_edges()
    if normalized_boss_id == "":
        normalized_boss_id = DEFAULT_BOSS_ID

    var boss_path := "%s/%s.json" % [BOSS_DIRECTORY_PATH, normalized_boss_id]
    var boss_data := data_loader.load_json(boss_path)
    if boss_data.is_empty():
        push_warning("Falling back to default boss data for id: " + normalized_boss_id)
        boss_data = data_loader.load_json("%s/%s.json" % [BOSS_DIRECTORY_PATH, DEFAULT_BOSS_ID])

    current_boss_texture = _load_boss_texture(boss_data)
    return boss_data


func _load_monster_deck(deck_id: String) -> Dictionary:
    var normalized_deck_id := deck_id.strip_edges()
    if normalized_deck_id == "":
        normalized_deck_id = DEFAULT_MONSTER_DECK_ID

    var deck_path := "%s/%s.json" % [DECK_DIRECTORY_PATH, normalized_deck_id]
    var deck_data := data_loader.load_deck(deck_path)
    if deck_data.is_empty():
        push_warning("Falling back to default monster deck for id: " + normalized_deck_id)
        deck_data = data_loader.load_deck("%s/%s.json" % [DECK_DIRECTORY_PATH, DEFAULT_MONSTER_DECK_ID])

    return deck_data


func _load_boss_texture(boss_data: Dictionary) -> Texture2D:
    var art_ref := str(boss_data.get("art_ref", "")).strip_edges()
    if art_ref != "":
        var configured_texture := load(art_ref)
        if configured_texture is Texture2D:
            return configured_texture

    var boss_name := str(boss_data.get("name", "")).strip_edges()
    if boss_name != "":
        var fallback_path := "res://art/cards/%s.png" % boss_name
        var fallback_texture := load(fallback_path)
        if fallback_texture is Texture2D:
            return fallback_texture

    return null


func _get_card_texture_or_placeholder(card, placeholder):
 var texture = _get_card_texture(card)
 if texture != null:
  return texture
 return placeholder


func _get_card_texture(card):
 if card == null:
  return null

 return _load_cached_texture(_get_card_art_ref(card))


func _get_card_sfx(card):
 if card == null:
  return null

 return _load_cached_sfx(_get_card_sfx_ref(card))


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

 for slot_offset in range(slot_indices.size()):
  var board_index = slot_indices[slot_offset]
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
  _play_sfx(_load_common_sfx(DEAL_CARDS_SFX_PATH), -3.0)

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

  if slot_offset < slot_indices.size() - 1:
   await get_tree().create_timer(0.14).timeout


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

 name_label.text = _get_card_display_name(card)
 type_label.text = _humanize_card_name(_get_card_family(card))
 value_label.text = str(_get_card_runtime_value(card))


func _clear_slot_text(name_label: Label, type_label: Label, value_label: Label) -> void:
 name_label.text = ""
 type_label.text = ""
 value_label.text = ""


func _get_card_runtime_value(card) -> int:
 if _is_runtime_card(card):
  return card.current_value

 if card is Dictionary:
  if card.has("current_value"):
   return int(card.get("current_value", 0))
  return int(card.get("base_value", 0))

 return 0


func _get_card_display_text(card) -> String:
    if _is_runtime_card(card):
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
    if restart_pending or is_modal_open():
        return false

    if match_state.player_state.is_stunned():
        return false

    var card = get_slot_card(slot_name)
    if card == null:
        return false
    return slot_name in ["left_hand", "right_hand", "backpack"]


func can_use_slot_weapon_on_monster(slot_name: String) -> bool:
    if restart_pending:
        return false

    if match_state.player_state.is_stunned():
        return false

    var card = get_slot_card(slot_name)
    if card == null or _get_card_family(card) != "weapon":
        return false
    if _get_card_runtime_value(card) <= 0:
        return false

    if slot_name == "left_hand":
        return not match_state.player_state.left_hand_exhausted

    if slot_name == "right_hand":
        return not match_state.player_state.right_hand_exhausted

    return false


func can_use_slot_spell_on_monster(slot_name: String) -> bool:
    if restart_pending:
        return false

    if match_state.player_state.is_stunned():
        return false

    var card = get_slot_card(slot_name)
    if card == null or _get_card_family(card) != "spell":
        return false

    return _card_targets(card, "enemy_card") and not _is_slot_exhausted(slot_name)


func can_use_slot_spell_on_boss(slot_name: String) -> bool:
    if restart_pending:
        return false

    if match_state.player_state.is_stunned():
        return false

    var card = get_slot_card(slot_name)
    if card == null or _get_card_family(card) != "spell":
        return false

    return _card_targets(card, "boss") and not _is_slot_exhausted(slot_name)


func can_use_slot_spell_on_player(slot_name: String) -> bool:
    if restart_pending:
        return false

    if match_state.player_state.is_stunned():
        return false

    var card = get_slot_card(slot_name)
    if card == null or _get_card_family(card) != "spell":
        return false

    return _card_targets(card, "player_avatar") and not _is_slot_exhausted(slot_name)


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
    if restart_pending or is_modal_open():
        return false

    var source := String(data.get("source", "")).strip_edges()
    var family := String(data.get("card_family", "")).strip_edges()
    var player_is_stunned = match_state.player_state.is_stunned()

    if source == "board":
        if target_slot == "left_hand":
            if family == "monster":
                return can_resolve_monster_into_shield("left_hand")
            if player_is_stunned:
                return false
            if match_state.player_state.left_hand_card != null or match_state.player_state.left_hand_exhausted:
                return false
            return family in ["weapon", "shield", "potion", "spell", "artifact", "coin", "chest"]
        elif target_slot == "right_hand":
            if family == "monster":
                return can_resolve_monster_into_shield("right_hand")
            if player_is_stunned:
                return false
            if match_state.player_state.right_hand_card != null or match_state.player_state.right_hand_exhausted:
                return false
            return family in ["weapon", "shield", "potion", "spell", "artifact", "coin", "chest"]
        elif target_slot == "backpack":
            if player_is_stunned:
                return false
            if match_state.player_state.backpack_exhausted:
                return false
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
        if player_is_stunned:
            return false
        if match_state.player_state.backpack_exhausted:
            return false
        if family == "":
            return false
        if target_slot == "left_hand":
            return match_state.player_state.left_hand_card == null and not match_state.player_state.left_hand_exhausted
        return match_state.player_state.right_hand_card == null and not match_state.player_state.right_hand_exhausted

    if source == "backpack" and target_slot == "discard":
        if player_is_stunned:
            return false
        if match_state.player_state.backpack_exhausted:
            return false
        return family in ["weapon", "shield", "potion", "spell", "artifact", "coin", "chest"]

    if source in ["left_hand", "right_hand"] and target_slot == "boss":
        if family == "weapon":
            return can_use_slot_weapon_on_monster(source)
        if family == "spell":
            return can_use_slot_spell_on_boss(source)
        return false

    if source in ["left_hand", "right_hand"] and target_slot == "player_avatar":
        return family == "spell" and can_use_slot_spell_on_player(source)

    if source in ["left_hand", "right_hand"] and target_slot == "backpack":
        if player_is_stunned:
            return false
        if match_state.player_state.backpack_exhausted:
            return false
        if family == "":
            return false
        return match_state.player_state.backpack_cards.size() < match_state.player_state.backpack_capacity

    if source in ["left_hand", "right_hand"] and target_slot == "discard":
        if player_is_stunned:
            return false
        return family in ["weapon", "shield", "potion", "spell", "artifact", "coin", "chest"]

    return false


func handle_slot_to_slot_drop(source_slot: String, target_slot: String) -> void:
    if restart_pending or source_slot == target_slot:
        return

    var moved := false
    var moved_card = get_slot_card(source_slot)

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
        if target_slot in ["left_hand", "right_hand"] and await _handle_auto_resolve_hand_spell(target_slot):
            return
        if target_slot == "discard":
            _play_sfx(_load_common_sfx(DISCARD_SFX_PATH))
        elif target_slot == "backpack":
            _play_loot_drop_sfx(moved_card, "backpack")
        elif target_slot in ["left_hand", "right_hand"]:
            _play_loot_drop_sfx(moved_card, target_slot)
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
    if match_state.player_state.backpack_exhausted:
        return false

    var card = match_state.player_state.remove_backpack_card_at(0)
    if card == null:
        return false

    var family := _get_card_family(card)
    if is_left_hand:
        if match_state.player_state.left_hand_exhausted or match_state.player_state.left_hand_card != null:
            match_state.player_state.backpack_cards.insert(0, card)
            if _is_runtime_card(card):
                card.set_zone("backpack")
            elif card is Dictionary:
                card["zone"] = "backpack"
            return false
        if family == "coin":
            match_state.player_state.add_temporary_gold(_get_card_runtime_value(card))
            _play_sfx(_load_common_sfx(GAIN_COINS_SFX_PATH))
            _mark_runtime_card_resolved(card)
            _mark_runtime_card_exhausted(card)
            _mark_runtime_card_destroyed(card)
            match_state.player_state.exhaust_left_hand()
            return true
        if family == "potion":
            _play_sfx(_load_common_sfx(DRINK_POTION_SFX_PATH))
            _apply_runtime_potion_effect(card)
            _mark_runtime_card_resolved(card)
            _mark_runtime_card_exhausted(card)
            _mark_runtime_card_destroyed(card)
            match_state.player_state.exhaust_left_hand()
            return true
    else:
        if match_state.player_state.right_hand_exhausted or match_state.player_state.right_hand_card != null:
            match_state.player_state.backpack_cards.insert(0, card)
            if _is_runtime_card(card):
                card.set_zone("backpack")
            elif card is Dictionary:
                card["zone"] = "backpack"
            return false
        if family == "coin":
            match_state.player_state.add_temporary_gold(_get_card_runtime_value(card))
            _play_sfx(_load_common_sfx(GAIN_COINS_SFX_PATH))
            _mark_runtime_card_resolved(card)
            _mark_runtime_card_exhausted(card)
            _mark_runtime_card_destroyed(card)
            match_state.player_state.exhaust_right_hand()
            return true
        if family == "potion":
            _play_sfx(_load_common_sfx(DRINK_POTION_SFX_PATH))
            _apply_runtime_potion_effect(card)
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
        if _is_runtime_card(card):
            card.set_zone("backpack")
        elif card is Dictionary:
            card["zone"] = "backpack"
        return false

    return true


func _mark_runtime_card_resolved(card) -> void:
    if _is_runtime_card(card):
        card.mark_resolved()
    elif card is Dictionary:
        card["is_resolved"] = true


func _mark_runtime_card_exhausted(card) -> void:
    if _is_runtime_card(card):
        card.mark_exhausted()
    elif card is Dictionary:
        card["is_exhausted"] = true


func _mark_runtime_card_destroyed(card) -> void:
    if _is_runtime_card(card):
        card.mark_destroyed()
    elif card is Dictionary:
        card["is_destroyed"] = true


func _apply_runtime_potion_effect(card) -> void:
    var handled_special := false

    if _has_special_rule(card, "adrenaline"):
        match_state.player_state.boost_max_health(_get_special_rule_value(card, "adrenaline", 1))
        handled_special = true

    if _has_special_rule(card, "defense"):
        match_state.player_state.queue_shield_bonus(_get_special_rule_value(card, "defense", 1))
        handled_special = true

    if _has_special_rule(card, "power"):
        match_state.player_state.queue_weapon_bonus(_get_special_rule_value(card, "power", 1))
        handled_special = true

    if not handled_special:
        var heal_amount := _get_card_runtime_value(card)
        if heal_amount > 0:
            match_state.player_state.heal(heal_amount)

    if _has_special_rule(card, "cure"):
        match_state.player_state.clear_poison()
        match_state.player_state.clear_disease()


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
            if _is_runtime_card(card):
                card.set_zone("left_hand")
            elif card is Dictionary:
                card["zone"] = "left_hand"
        else:
            match_state.player_state.right_hand_card = card
            if _is_runtime_card(card):
                card.set_zone("right_hand")
            elif card is Dictionary:
                card["zone"] = "right_hand"
        return false

    return true


func _handle_monster_to_shield(board_index: int, is_left_hand: bool) -> void:
    var shield_before = get_slot_card("left_hand" if is_left_hand else "right_hand")
    var shield_before_value = _get_card_runtime_value(shield_before)
    var monster_before = null
    var active_cards = match_state.board_state.get_active_cards()
    if board_index >= 0 and board_index < active_cards.size():
        monster_before = active_cards[board_index]
    var monster_value = _get_card_runtime_value(monster_before)
    var health_before = match_state.player_state.current_health
    var left_exhausted_before: bool = match_state.player_state.left_hand_exhausted
    var right_exhausted_before: bool = match_state.player_state.right_hand_exhausted
    var backpack_exhausted_before: bool = match_state.player_state.backpack_exhausted

    var success = false
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
    var damage_taken = health_before - match_state.player_state.current_health
    _play_sfx(_load_common_sfx(DROP_CARD_SFX_PATH))
    _play_sfx(_load_common_sfx(SHIELD_DEFEND_SFX_PATH))
    if shield_after != null:
        var blocked_message := "Shield blocked %d and remains at %d." % [monster_value, _get_card_runtime_value(shield_after)]
        if (not left_exhausted_before and match_state.player_state.left_hand_exhausted and not is_left_hand) or (not right_exhausted_before and match_state.player_state.right_hand_exhausted and is_left_hand) or (not backpack_exhausted_before and match_state.player_state.backpack_exhausted):
            blocked_message += " Entangle exhausted your loadout."
        if damage_taken > 0:
            blocked_message += " Spite dealt %d damage." % damage_taken
        set_status(blocked_message)
    elif damage_taken > 0:
        _show_player_damage_slash()
        _play_damage_screen_shake()
        _play_random_player_hurt_sfx()
        var broken_message := "Shield broke. Player took %d damage." % damage_taken
        if not backpack_exhausted_before and match_state.player_state.backpack_exhausted:
            broken_message += " Entangle exhausted your loadout."
        set_status(broken_message)
    else:
        var exhaust_message := "Shield broke after blocking %d." % shield_before_value
        if not backpack_exhausted_before and match_state.player_state.backpack_exhausted:
            exhaust_message += " Entangle exhausted your loadout."
        set_status(exhaust_message)

    _refresh_ui()


func handle_slot_card_drop_on_board(source_hand: String, board_index: int) -> void:
    if restart_pending:
        return

    var slot_card = get_slot_card(source_hand)
    var family := _get_card_family(slot_card)
    var active_cards: Array = match_state.board_state.get_active_cards()
    var target_before = null
    if board_index >= 0 and board_index < active_cards.size():
        target_before = active_cards[board_index]

    if family == "weapon":
        handle_weapon_drop_on_board(source_hand, board_index)
        return

    if family != "spell":
        set_status("That card cannot target a monster.")
        _refresh_ui()
        return

    var success := false
    if source_hand == "left_hand":
        success = combat_controller.use_left_hand_spell_on_monster(board_index)
    elif source_hand == "right_hand":
        success = combat_controller.use_right_hand_spell_on_monster(board_index)

    if not success:
        set_status("Could not cast spell on monster.")
        _refresh_ui()
        return

    _play_sfx(_load_common_sfx(DROP_CARD_SFX_PATH))
    var target_after = null
    if board_index >= 0 and board_index < active_cards.size():
        target_after = active_cards[board_index]
    if target_before != null and target_after == null:
        _show_board_card_damage_slash(board_index)
        await _animate_board_card_resolution(board_index)
    elif target_before != null and target_after != target_before:
        _show_board_card_damage_slash(board_index)
    set_status("Spell cast on monster.")
    _refresh_ui()


func handle_slot_card_drop_on_player_avatar(source_hand: String) -> void:
    if restart_pending:
        return

    var slot_card = get_slot_card(source_hand)
    if _get_card_family(slot_card) != "spell":
        set_status("Only spells can be cast on the player.")
        _refresh_ui()
        return

    var success := false
    if source_hand == "left_hand":
        success = combat_controller.use_left_hand_spell_on_player()
    elif source_hand == "right_hand":
        success = combat_controller.use_right_hand_spell_on_player()

    if not success:
        set_status("Could not cast spell on player.")
        _refresh_ui()
        return

    _play_sfx(_load_common_sfx(DROP_CARD_SFX_PATH))
    set_status("Spell cast on player.")
    _refresh_ui()


func handle_weapon_drop_on_board(source_hand: String, board_index: int) -> void:
    if restart_pending:
        return

    var before_count = match_state.board_state.active_count()
    var before_deck_count = match_state.shared_deck_state.remaining_count()
    var before_player_health = match_state.player_state.current_health
    var before_value := -1
    var sweep_hit_indices: Array[int] = []
    var before_cards = match_state.board_state.get_active_cards()
    if board_index >= 0 and board_index < before_cards.size():
        before_value = _get_card_runtime_value(before_cards[board_index])
    var source_weapon = get_slot_card(source_hand)
    if _has_special_rule(source_weapon, "sweep") and _get_special_rule_value(source_weapon, "sweep", 0) > 0:
        sweep_hit_indices = _get_adjacent_monster_board_indices(board_index)

    var success = false
    if source_hand == "left_hand":
        success = combat_controller.use_left_hand_weapon_on_monster(board_index)
    elif source_hand == "right_hand":
        success = combat_controller.use_right_hand_weapon_on_monster(board_index)

    if not success:
        set_status("Could not use weapon on monster.")
        _refresh_ui()
        return

    var after_count = match_state.board_state.active_count()
    _play_sfx(_load_common_sfx(DROP_CARD_SFX_PATH))
    _play_sfx(_load_common_sfx(SWORD_SWING_SFX_PATH))
    for sweep_index in sweep_hit_indices:
        _show_board_card_damage_slash(sweep_index)
    if after_count < before_count:
        _show_board_card_damage_slash(board_index)
        await _animate_board_card_resolution(board_index)
        var kill_message := "Weapon resolved the monster."
        var player_damage_taken: int = before_player_health - match_state.player_state.current_health
        if match_state.shared_deck_state.remaining_count() > before_deck_count:
            kill_message += " Boss special triggered."
        if player_damage_taken > 0:
            kill_message += " Player took %d damage." % player_damage_taken
        set_status(kill_message)
    else:
        var after_cards = match_state.board_state.get_active_cards()
        var remaining_value := -1
        if board_index >= 0 and board_index < after_cards.size():
            remaining_value = _get_card_runtime_value(after_cards[board_index])
        _show_board_card_damage_slash(board_index)
        set_status("Weapon hit. Monster reduced from %d to %d." % [before_value, remaining_value])

    _refresh_ui()


func handle_weapon_drop_on_boss(source_hand: String) -> void:
    if restart_pending:
        return

    var before_health = match_state.boss_state.current_health
    var player_health_before = match_state.player_state.current_health
    var success = false
    if source_hand == "left_hand":
        success = combat_controller.use_left_hand_weapon_on_boss()
    elif source_hand == "right_hand":
        success = combat_controller.use_right_hand_weapon_on_boss()

    if not success:
        set_status("Could not use weapon on boss.")
        _refresh_ui()
        return

    var after_health = match_state.boss_state.current_health
    var player_health_after = match_state.player_state.current_health
    var retaliation_damage: int = maxi(player_health_before - player_health_after, 0)
    _play_sfx(_load_common_sfx(DROP_CARD_SFX_PATH))
    _play_sfx(_load_common_sfx(SWORD_SWING_SFX_PATH))
    _play_sfx(_load_common_sfx(GRAVEBOUND_WARDEN_HURT_SFX_PATH))
    var boss_name: String = match_state.boss_state.boss_name
    if after_health <= 0:
        _show_boss_damage_slash()
        if retaliation_damage > 0:
            set_status("%s defeated. Retaliation dealt %d damage." % [boss_name, retaliation_damage])
        else:
            set_status("%s defeated." % [boss_name])
    else:
        _show_boss_damage_slash()
        if retaliation_damage > 0:
            set_status("Weapon hit the boss. %d to %d. Retaliation dealt %d damage." % [before_health, after_health, retaliation_damage])
        else:
            set_status("Weapon hit the boss. %d to %d." % [before_health, after_health])

    _refresh_ui()


func handle_slot_card_drop_on_boss(source_hand: String) -> void:
    var slot_card = get_slot_card(source_hand)
    var family := _get_card_family(slot_card)

    if family == "weapon":
        handle_weapon_drop_on_boss(source_hand)
        return

    if family != "spell":
        set_status("That card cannot target the boss.")
        _refresh_ui()
        return

    var before_health = match_state.boss_state.current_health
    var player_health_before = match_state.player_state.current_health
    var success := false
    if source_hand == "left_hand":
        success = combat_controller.use_left_hand_spell_on_boss()
    elif source_hand == "right_hand":
        success = combat_controller.use_right_hand_spell_on_boss()

    if not success:
        set_status("Could not cast spell on boss.")
        _refresh_ui()
        return

    var after_health = match_state.boss_state.current_health
    var retaliation_damage: int = maxi(player_health_before - match_state.player_state.current_health, 0)
    _play_sfx(_load_common_sfx(DROP_CARD_SFX_PATH))
    _show_boss_damage_slash()
    if retaliation_damage > 0:
        set_status("Spell hit the boss. %d to %d. Retaliation dealt %d damage." % [before_health, after_health, retaliation_damage])
    else:
        set_status("Spell hit the boss. %d to %d." % [before_health, after_health])
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
    _style_end_modal()
    _style_shift_fate_modal()
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
    if match_state.player_state.backpack_exhausted:
        _apply_exhausted_slot_visual(backpack_drop_zone, backpack_texture)


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


func _style_end_modal() -> void:
    if end_modal == null:
        return

    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color("1b1410")
    panel_style.border_color = Color("8a6651")
    panel_style.border_width_left = 2
    panel_style.border_width_top = 2
    panel_style.border_width_right = 2
    panel_style.border_width_bottom = 2
    panel_style.corner_radius_top_left = 18
    panel_style.corner_radius_top_right = 18
    panel_style.corner_radius_bottom_right = 18
    panel_style.corner_radius_bottom_left = 18
    end_modal.add_theme_stylebox_override("panel", panel_style)

    end_modal_title.add_theme_color_override("font_color", Color("f7ead7"))
    end_modal_title.add_theme_font_size_override("font_size", 28)
    end_modal_stats.add_theme_color_override("font_color", HUD_TEXT)
    end_modal_stats.add_theme_font_size_override("font_size", 18)
    end_modal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    end_modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
    end_modal_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    end_modal_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
    retry_button.mouse_filter = Control.MOUSE_FILTER_STOP
    quit_button.mouse_filter = Control.MOUSE_FILTER_STOP
    retry_button.focus_mode = Control.FOCUS_ALL
    quit_button.focus_mode = Control.FOCUS_ALL
    retry_button.add_theme_font_size_override("font_size", 16)
    quit_button.add_theme_font_size_override("font_size", 16)


func _style_shift_fate_modal() -> void:
    if shift_fate_modal == null:
        return

    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color("1b1410")
    panel_style.border_color = Color("8a6651")
    panel_style.border_width_left = 2
    panel_style.border_width_top = 2
    panel_style.border_width_right = 2
    panel_style.border_width_bottom = 2
    panel_style.corner_radius_top_left = 18
    panel_style.corner_radius_top_right = 18
    panel_style.corner_radius_bottom_right = 18
    panel_style.corner_radius_bottom_left = 18
    shift_fate_modal.add_theme_stylebox_override("panel", panel_style)

    shift_fate_title.add_theme_color_override("font_color", Color("f7ead7"))
    shift_fate_title.add_theme_font_size_override("font_size", 26)
    shift_fate_subtitle.add_theme_color_override("font_color", HUD_TEXT)
    shift_fate_subtitle.add_theme_font_size_override("font_size", 16)
    shift_fate_done_button.add_theme_font_size_override("font_size", 16)
    shift_fate_modal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    shift_fate_modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
    shift_fate_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    shift_fate_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    shift_fate_preview_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
    shift_fate_done_button.mouse_filter = Control.MOUSE_FILTER_STOP
    shift_fate_done_button.focus_mode = Control.FOCUS_ALL


func _queue_restart_if_finished() -> void:
    if restart_pending:
        return

    if outcome_controller == null or match_state == null:
        return

    var outcome = outcome_controller.check_outcome(match_state)
    if outcome not in ["failure", "victory", "survival"]:
        return

    restart_pending = true
    call_deferred("_show_battle_end_modal", outcome)

func _show_battle_end_modal(outcome: String) -> void:
    var xp_gained = _apply_battle_xp_rewards(outcome)
    var reward_summary := _apply_phase_one_battle_rewards(outcome)
    var xp_base = match_state.battle_xp_earned
    var xp_multiplier = match_state.battle_xp_multiplier
    var gold_delta = int(reward_summary.get("temporary_gold_collected", match_state.player_state.temporary_gold))
    var persistent_gold_awarded = int(reward_summary.get("persistent_gold_awarded", 0))
    var persistent_gold_after = int(reward_summary.get("persistent_gold_after", int(player_profile_data.get("persistent_gold", 0))))
    var gold_text := "Temporary Gold Collected: %d" % gold_delta
    var banked_gold_text := "Persistent Gold Banked: %d" % persistent_gold_awarded
    var total_gold_text := "Persistent Gold Total: %d" % persistent_gold_after
    var boss_reward_text := _build_boss_reward_text(reward_summary)
    var xp_text := "XP Gained: %d" % xp_gained
    if xp_multiplier > 1:
        xp_text = "XP Gained: %d (%d x%d)" % [xp_gained, xp_base, xp_multiplier]

    if outcome == "victory":
        set_status("Boss defeated.")
        end_modal_title.text = "Victory"
        _play_outcome_music(true)
    elif outcome == "survival":
        set_status("You survived the deck.")
        end_modal_title.text = "Survived"
        _play_outcome_music(true)
    else:
        set_status("You died.")
        end_modal_title.text = "Defeat"
        _play_outcome_music(false)
        banked_gold_text = "Persistent Gold Banked: 0"
        total_gold_text = "Persistent Gold Total: %d" % int(player_profile_data.get("persistent_gold", persistent_gold_after))

    end_modal_stats.text = "Rounds: %d\n%s" % [
        match_state.round_number,
        "%s\n%s\n%s\n%s\n%s\nLevel: %d\nTotal XP: %d" % [
            gold_text,
            banked_gold_text,
            total_gold_text,
            boss_reward_text,
            xp_text,
            int(player_profile_data.get("player_level", 1)),
            int(player_profile_data.get("total_xp", 0))
        ]
    ]
    move_child(end_modal_overlay, get_child_count() - 1)
    end_modal_overlay.visible = true
    retry_button.disabled = false
    quit_button.disabled = false
    quit_button.text = "Return to Hovel"
    retry_button.grab_focus()


func _hide_end_modal() -> void:
    if end_modal_overlay != null:
        end_modal_overlay.visible = false
    escape_was_pressed = false


func _hide_shift_fate_modal() -> void:
    if shift_fate_modal_overlay != null:
        shift_fate_modal_overlay.visible = false
    shift_fate_selected_slot = ""
    shift_fate_preview_cards.clear()
    shift_fate_selected_cards.clear()
    shift_fate_required_selection_count = SHIFT_FATE_SELECTION_COUNT
    for entry in shift_fate_preview_entries:
        var wrapper = entry.get("wrapper", null)
        if wrapper is Node:
            wrapper.queue_free()
    shift_fate_preview_entries.clear()
    if shift_fate_done_button != null:
        shift_fate_done_button.disabled = true


func _apply_battle_xp_rewards(outcome: String) -> int:
    if match_state == null:
        return 0

    var xp_gained = match_state.finalize_battle_xp(outcome)
    if match_state.battle_xp_persisted:
        return xp_gained

    if player_profile_data.is_empty():
        return xp_gained

    var starting_total_xp := int(player_profile_data.get("total_xp", 0))
    var updated_total_xp = starting_total_xp + xp_gained
    player_profile_data["total_xp"] = updated_total_xp
    player_profile_data["player_level"] = PROGRESSION_SCRIPT.calculate_level_from_total_xp(updated_total_xp)
    _save_player_profile()
    match_state.battle_xp_persisted = true
    return xp_gained


func _apply_phase_one_battle_rewards(outcome: String) -> Dictionary:
    if match_state == null:
        return {}

    if match_state.battle_rewards_persisted:
        return match_state.battle_reward_summary.duplicate(true)

    var persistent_gold_before := int(player_profile_data.get("persistent_gold", 0))
    var should_keep_temporary_gold: bool = match_state.should_keep_temporary_gold(outcome, current_reward_profile)
    var persistent_gold_awarded := 0
    if should_keep_temporary_gold and match_state.player_state != null:
        persistent_gold_awarded = match_state.player_state.temporary_gold

    var reward_summary: Dictionary = match_state.build_battle_reward_summary(
        outcome,
        int(player_profile_data.get("player_level", 1)),
        _get_current_boss_difficulty(),
        persistent_gold_before,
        persistent_gold_awarded
    )
    reward_summary["reward_profile_id"] = str(current_match_config.get("reward_profile_id", "")).strip_edges()
    reward_summary["boss_drop_table_id"] = str(current_boss_drop_table.get("id", "")).strip_edges()
    reward_summary["boss_drop_rewards"] = _grant_boss_drop_rewards(outcome)
    var hovel_shop_state: Dictionary = HOVEL_SHOP_SCRIPT.refresh_shop_state(
        player_profile_data,
        data_loader,
        HOVEL_SHOP_RULES_PATH,
        "battle_end"
    )
    if not hovel_shop_state.is_empty():
        reward_summary["hovel_shop_state"] = hovel_shop_state.duplicate(true)

    player_profile_data["persistent_gold"] = persistent_gold_before + persistent_gold_awarded
    reward_summary["persistent_gold_after"] = int(player_profile_data.get("persistent_gold", persistent_gold_before))
    player_profile_data["last_battle_reward_summary"] = reward_summary.duplicate(true)
    _save_player_profile()

    match_state.battle_reward_summary = reward_summary.duplicate(true)
    match_state.battle_rewards_persisted = true
    return reward_summary


func _get_current_boss_difficulty() -> String:
    var boss_difficulty := str(current_boss_data.get("boss_type", "")).strip_edges()
    if boss_difficulty != "":
        return boss_difficulty
    return "baseline"


func _load_reward_profile(reward_profile_id: String) -> Dictionary:
    var normalized_id := reward_profile_id.strip_edges()
    if normalized_id == "":
        return {}

    var reward_profile_path := "res://data/rewards/%s.json" % normalized_id
    if not FileAccess.file_exists(reward_profile_path):
        push_warning("Reward profile not found: " + reward_profile_path)
        return {}

    return data_loader.load_json(reward_profile_path)


func _load_boss_drop_table(boss_id: String) -> Dictionary:
    var normalized_boss_id := boss_id.strip_edges()
    if normalized_boss_id == "":
        return {}

    var boss_drop_table_path := "res://data/rewards/boss drops/%s_boss_drops.json" % normalized_boss_id
    if not FileAccess.file_exists(boss_drop_table_path):
        return {}

    return data_loader.load_json(boss_drop_table_path)


func _grant_boss_drop_rewards(outcome: String) -> Array:
    if current_boss_drop_table.is_empty():
        return []

    var grant_on_outcome = current_boss_drop_table.get("grant_on_outcome", [])
    if not (grant_on_outcome is Array):
        return []

    if outcome not in grant_on_outcome:
        return []

    var drop_count := int(current_boss_drop_table.get("drop_count", 0))
    if drop_count <= 0:
        return []

    var granted_rewards: Array = []
    for _i in range(drop_count):
        var reward_entry := _roll_weighted_boss_drop_entry(current_boss_drop_table)
        if reward_entry.is_empty():
            continue

        var card_id := str(reward_entry.get("card_id", "")).strip_edges()
        if card_id == "":
            continue

        _grant_reward_card_to_inventory(card_id)
        granted_rewards.append({
            "card_id": card_id,
            "rarity": str(reward_entry.get("rarity", "")).strip_edges()
        })

    return granted_rewards


func _roll_weighted_boss_drop_entry(boss_drop_table: Dictionary) -> Dictionary:
    var entries = boss_drop_table.get("entries", [])
    if not (entries is Array):
        return {}

    var total_weight := 0
    var weighted_entries: Array[Dictionary] = []
    for entry in entries:
        if not (entry is Dictionary):
            continue

        var weight := maxi(int(entry.get("weight", 0)), 0)
        if weight <= 0:
            continue

        total_weight += weight
        weighted_entries.append(entry)

    if total_weight <= 0 or weighted_entries.is_empty():
        return {}

    var roll := randi() % total_weight
    var running_weight := 0
    for entry in weighted_entries:
        running_weight += int(entry.get("weight", 0))
        if roll < running_weight:
            return entry.duplicate(true)

    return weighted_entries[weighted_entries.size() - 1].duplicate(true)


func _grant_reward_card_to_inventory(card_id: String) -> void:
    var normalized_card_id := card_id.strip_edges()
    if normalized_card_id == "":
        return

    var owned_card_counts = player_profile_data.get("owned_card_counts", {})
    if not (owned_card_counts is Dictionary):
        owned_card_counts = {}

    var current_count := int(owned_card_counts.get(normalized_card_id, 0))
    owned_card_counts[normalized_card_id] = current_count + 1
    player_profile_data["owned_card_counts"] = owned_card_counts


func _build_boss_reward_text(reward_summary: Dictionary) -> String:
    var rewards = reward_summary.get("boss_drop_rewards", [])
    if not (rewards is Array) or rewards.is_empty():
        return "Boss Reward: None"

    var reward_names: Array[String] = []
    for reward in rewards:
        if not (reward is Dictionary):
            continue

        var card_id := str(reward.get("card_id", "")).strip_edges()
        if card_id == "":
            continue

        reward_names.append(_get_reward_card_name(card_id))

    if reward_names.is_empty():
        return "Boss Reward: None"

    return "Boss Reward: %s" % ", ".join(reward_names)


func _get_reward_card_name(card_id: String) -> String:
    var card_data: Dictionary = data_loader.get_card(card_id)
    if card_data.is_empty():
        return card_id
    return str(card_data.get("name", card_id))


func _save_player_profile() -> void:
    var file := FileAccess.open(PLAYER_PROFILE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("Failed to open player profile for write: " + PLAYER_PROFILE_PATH)
        return

    file.store_string(JSON.stringify(player_profile_data, "\t"))
    file.close()


func is_modal_open() -> bool:
    return (
        (end_modal_overlay != null and end_modal_overlay.visible)
        or (shift_fate_modal_overlay != null and shift_fate_modal_overlay.visible)
    )


func _restart_battle() -> void:
    await _resume_battle_music_from_outcome()
    _build_battle_match_state()
    restart_pending = false
    set_status("Battle restarted.")
    _refresh_ui()
    await _play_battle_intro()


func _on_retry_battle_pressed() -> void:
    _hide_end_modal()
    _restart_battle()


func _on_quit_battle_pressed() -> void:
    get_tree().change_scene_to_file(HOVEL_SCENE_PATH)


func _process(_delta: float) -> void:
    if end_modal_overlay == null or not end_modal_overlay.visible:
        escape_was_pressed = false
        return

    var escape_pressed := Input.is_action_pressed("ui_cancel") or Input.is_key_pressed(KEY_ESCAPE)
    if escape_pressed and not escape_was_pressed:
        _on_quit_battle_pressed()
    escape_was_pressed = escape_pressed

func _on_take_first_monster_pressed() -> void:
 if restart_pending:
  return

 var board_cards = match_state.board_state.get_active_cards()

 for i in range(board_cards.size()):
  var card = board_cards[i]
  if _get_card_family(card) == "monster":
   var success = combat_controller.resolve_enemy_to_player(i)
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
   var success = combat_controller.move_player_card_to_left_hand(i)
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
   var success = combat_controller.move_player_card_to_backpack(i)
   if success:
    await _animate_board_card_resolution(i)
    set_status("Moved first usable card to backpack.")
   else:
    set_status("Could not move card to backpack.")
   _refresh_ui()
   return

 set_status("No usable card found for backpack.")


func _get_card_family(card) -> String:
    if _is_runtime_card(card):
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
 var board_card = null
 if board_index >= 0 and board_index < active_cards.size():
  board_card = active_cards[board_index]
  if _get_card_family(board_card) == "monster" and can_resolve_monster_into_shield("left_hand"):
   await _handle_monster_to_shield(board_index, true)
   return

 var before_left_hand = match_state.player_state.left_hand_card
 print("before move, left hand: ", before_left_hand)

 var success = false
 if board_card != null and _is_shift_fate_card(board_card):
  success = combat_controller.move_player_card_to_left_hand(board_index, true)
 else:
  success = combat_controller.move_player_card_to_left_hand(board_index)

 var after_left_hand = match_state.player_state.left_hand_card
 print("after move, left hand: ", after_left_hand)

 if success:
  _play_loot_drop_sfx(board_card, "left_hand")
  if board_card != null and _get_card_family(board_card) == "coin":
   _play_sfx(_load_common_sfx(GAIN_COINS_SFX_PATH))
  elif board_card != null and _get_card_family(board_card) == "potion":
   _play_sfx(_load_common_sfx(DRINK_POTION_SFX_PATH))
  await _animate_board_card_resolution(board_index)
  if await _handle_auto_resolve_hand_spell("left_hand"):
   return
  set_status("Dropped card into left hand.")
 else:
  set_status("Could not drop card into left hand.")
 _refresh_ui()

func handle_drop_to_right_hand(board_index: int) -> void:
 if restart_pending:
  return

 print("handle_drop_to_right_hand called with index: ", board_index)

 var active_cards = match_state.board_state.get_active_cards()
 var board_card = null
 if board_index >= 0 and board_index < active_cards.size():
  board_card = active_cards[board_index]
  if _get_card_family(board_card) == "monster" and can_resolve_monster_into_shield("right_hand"):
   await _handle_monster_to_shield(board_index, false)
   return

 var before_right_hand = match_state.player_state.right_hand_card
 print("before move, right hand: ", before_right_hand)

 var success = false
 if board_card != null and _is_shift_fate_card(board_card):
  success = combat_controller.move_player_card_to_right_hand(board_index, true)
 else:
  success = combat_controller.move_player_card_to_right_hand(board_index)

 var after_right_hand = match_state.player_state.right_hand_card
 print("after move, right hand: ", after_right_hand)

 if success:
  _play_loot_drop_sfx(board_card, "right_hand")
  if board_card != null and _get_card_family(board_card) == "coin":
   _play_sfx(_load_common_sfx(GAIN_COINS_SFX_PATH))
  elif board_card != null and _get_card_family(board_card) == "potion":
   _play_sfx(_load_common_sfx(DRINK_POTION_SFX_PATH))
  await _animate_board_card_resolution(board_index)
  if await _handle_auto_resolve_hand_spell("right_hand"):
   return
  set_status("Dropped card into right hand.")
 else:
  set_status("Could not drop card into right hand.")
 _refresh_ui()


func handle_drop_to_backpack(board_index: int) -> void:
 if restart_pending:
  return

 print("handle_drop_to_backpack called with index: ", board_index)

 var active_cards = match_state.board_state.get_active_cards()
 var board_card = null
 if board_index >= 0 and board_index < active_cards.size():
  board_card = active_cards[board_index]

 var before_backpack = match_state.player_state.backpack_cards.size()
 print("before move, backpack size: ", before_backpack)

 var success = combat_controller.move_player_card_to_backpack(board_index)

 var after_backpack = match_state.player_state.backpack_cards.size()
 print("after move, backpack size: ", after_backpack)

 if success:
  _play_loot_drop_sfx(board_card, "backpack")
  await _animate_board_card_resolution(board_index)
  set_status("Dropped card into backpack.")
 else:
  set_status("Could not drop card into backpack.")
 _refresh_ui()


func handle_drop_to_player_avatar(board_index: int) -> void:
 if restart_pending:
  return

 print("handle_drop_to_player_avatar called with index: ", board_index)

 var active_cards = match_state.board_state.get_active_cards()
 var board_card = null
 if board_index >= 0 and board_index < active_cards.size():
  board_card = active_cards[board_index]

 var before_health = match_state.player_state.current_health
 var poison_before = match_state.player_state.poison_counters
 var disease_before = match_state.player_state.disease_counters
 var boss_health_before = match_state.boss_state.current_health
 print("before resolve, player health: ", before_health)

 var success = combat_controller.resolve_enemy_to_player(board_index)

 var after_health = match_state.player_state.current_health
 print("after resolve, player health: ", after_health)

 if success:
  _play_sfx(_load_common_sfx(DROP_CARD_SFX_PATH))
  _play_monster_attack_sfx(board_card)
  await _animate_board_card_resolution(board_index)
  if after_health < before_health:
   _show_player_damage_slash()
   _play_damage_screen_shake()
   _play_random_player_hurt_sfx()
  var result_message := "Dropped monster onto player."
  if match_state.player_state.is_stunned():
   result_message += " You are stunned until round end."
  if match_state.player_state.poison_counters > poison_before:
   result_message += " Poison +%d." % (match_state.player_state.poison_counters - poison_before)
  if match_state.player_state.disease_counters > disease_before:
   result_message += " Disease +%d." % (match_state.player_state.disease_counters - disease_before)
  if match_state.boss_state.current_health > boss_health_before:
   result_message += " Boss healed %d." % (match_state.boss_state.current_health - boss_health_before)
  set_status(result_message)
 else:
  set_status("Only monsters can be dropped onto the player.")

 _refresh_ui()


func handle_drop_to_discard(board_index: int) -> void:
 if restart_pending:
  return

 print("handle_drop_to_discard called with index: ", board_index)

 var success = combat_controller.trash_player_card_from_board(board_index)

 if success:
  _play_sfx(_load_common_sfx(DROP_CARD_SFX_PATH))
  _play_sfx(_load_common_sfx(DISCARD_SFX_PATH))
  await _animate_board_card_resolution(board_index)
  set_status("Discarded card without benefit.")
 else:
  set_status("Only item cards can be discarded.")

 _refresh_ui()


func _get_card_unique_key(card) -> String:
 if _is_runtime_card(card):
  return card.instance_id

 if card is Dictionary:
  return str(card.get("instance_id", card.get("id", "")))

 return ""


func _is_runtime_card(value) -> bool:
    return value is Object and value.get_script() == CARD_RUNTIME_STATE_SCRIPT


func _is_slot_exhausted(slot_name: String) -> bool:
    if slot_name == "left_hand":
        return match_state.player_state.left_hand_exhausted
    if slot_name == "right_hand":
        return match_state.player_state.right_hand_exhausted
    if slot_name == "backpack":
        return match_state.player_state.backpack_exhausted
    return false


func _card_targets(card, target_rule: String) -> bool:
    if _is_runtime_card(card):
        var target_rules = card.card_data.get("target_rules", [])
        return target_rules is Array and target_rule in target_rules
    if card is Dictionary:
        var target_rules = card.get("target_rules", [])
        return target_rules is Array and target_rule in target_rules
    return false


func _card_auto_resolves_in_hand(card) -> bool:
    if _is_runtime_card(card):
        return bool(card.card_data.get("auto_resolve_on_hand_place", false))
    if card is Dictionary:
        return bool(card.get("auto_resolve_on_hand_place", false))
    return false


func _is_shift_fate_card(card) -> bool:
    return _has_special_rule(card, "shift_fate")


func _handle_auto_resolve_hand_spell(slot_name: String) -> bool:
    var card = get_slot_card(slot_name)
    if card == null or _get_card_family(card) != "spell":
        return false
    if not _card_auto_resolves_in_hand(card):
        return false

    if _is_shift_fate_card(card):
        set_status("Shift Fate awaits your choice.")
        _refresh_ui()
        _open_shift_fate_modal(slot_name)
        return true

    var success := false
    if slot_name == "left_hand":
        success = combat_controller.use_left_hand_spell_on_player()
    elif slot_name == "right_hand":
        success = combat_controller.use_right_hand_spell_on_player()

    if not success:
        set_status("Could not resolve spell in hand.")
        _refresh_ui()
        return true

    _play_sfx(_load_common_sfx(DROP_CARD_SFX_PATH))
    set_status("Spell resolved in hand.")
    _refresh_ui()
    return true


func _open_shift_fate_modal(slot_name: String) -> void:
    var spell = get_slot_card(slot_name)
    if not _is_shift_fate_card(spell):
        return

    _hide_shift_fate_modal()
    shift_fate_selected_slot = slot_name
    shift_fate_preview_cards = match_state.shared_deck_state.peek(SHIFT_FATE_PREVIEW_COUNT)
    shift_fate_required_selection_count = mini(SHIFT_FATE_SELECTION_COUNT, shift_fate_preview_cards.size())

    if shift_fate_required_selection_count <= 0:
        _finalize_shift_fate_choice()
        return

    for card in shift_fate_preview_cards:
        var wrapper := PanelContainer.new()
        wrapper.custom_minimum_size = Vector2(220, 300)
        wrapper.mouse_filter = Control.MOUSE_FILTER_STOP

        var style := StyleBoxFlat.new()
        style.bg_color = Color("130f0d")
        style.border_color = PANEL_BORDER
        style.border_width_left = 2
        style.border_width_top = 2
        style.border_width_right = 2
        style.border_width_bottom = 2
        style.corner_radius_top_left = 14
        style.corner_radius_top_right = 14
        style.corner_radius_bottom_right = 14
        style.corner_radius_bottom_left = 14
        wrapper.add_theme_stylebox_override("panel", style)

        var preview_card = CARD_VIEW_SCENE.instantiate()
        preview_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
        preview_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        wrapper.add_child(preview_card)
        preview_card.setup(card, -1)

        var order_label := Label.new()
        order_label.visible = false
        order_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        order_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        order_label.position = Vector2(12, 12)
        order_label.size = Vector2(36, 36)
        order_label.add_theme_color_override("font_color", Color("1b1410"))
        order_label.add_theme_font_size_override("font_size", 20)
        wrapper.add_child(order_label)

        wrapper.gui_input.connect(_on_shift_fate_preview_gui_input.bind(card))
        shift_fate_preview_grid.add_child(wrapper)
        shift_fate_preview_entries.append({
            "card": card,
            "wrapper": wrapper,
            "order_label": order_label
        })

    shift_fate_done_button.disabled = true
    move_child(shift_fate_modal_overlay, get_child_count() - 1)
    shift_fate_modal_overlay.visible = true
    _refresh_shift_fate_preview_state()


func _on_shift_fate_preview_gui_input(event: InputEvent, card) -> void:
    if not (event is InputEventMouseButton):
        return

    var mouse_event := event as InputEventMouseButton
    if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
        return

    if card in shift_fate_selected_cards:
        shift_fate_selected_cards.erase(card)
    elif shift_fate_selected_cards.size() < shift_fate_required_selection_count:
        shift_fate_selected_cards.append(card)

    _refresh_shift_fate_preview_state()


func _refresh_shift_fate_preview_state() -> void:
    for entry in shift_fate_preview_entries:
        var card = entry.get("card", null)
        var wrapper = entry.get("wrapper", null)
        var order_label = entry.get("order_label", null)
        if wrapper == null or order_label == null:
            continue

        var order_index := shift_fate_selected_cards.find(card)
        var style := StyleBoxFlat.new()
        style.bg_color = Color("130f0d")
        style.border_width_left = 2
        style.border_width_top = 2
        style.border_width_right = 2
        style.border_width_bottom = 2
        style.corner_radius_top_left = 14
        style.corner_radius_top_right = 14
        style.corner_radius_bottom_right = 14
        style.corner_radius_bottom_left = 14

        if order_index >= 0:
            style.border_color = SUCCESS_TEXT
            order_label.visible = true
            order_label.text = str(order_index + 1)
        else:
            style.border_color = PANEL_BORDER
            order_label.visible = false
            order_label.text = ""

        wrapper.add_theme_stylebox_override("panel", style)

    shift_fate_done_button.disabled = shift_fate_selected_cards.size() != shift_fate_required_selection_count


func _on_shift_fate_done_pressed() -> void:
    if shift_fate_selected_cards.size() != shift_fate_required_selection_count:
        return

    _finalize_shift_fate_choice()


func _finalize_shift_fate_choice() -> void:
    var selected_cards = shift_fate_selected_cards.duplicate()
    match_state.shared_deck_state.reorder_with_selected_top(selected_cards)

    var consumed := false
    if shift_fate_selected_slot == "left_hand":
        consumed = resolution_controller.use_left_hand_spell_on_player(match_state)
    elif shift_fate_selected_slot == "right_hand":
        consumed = resolution_controller.use_right_hand_spell_on_player(match_state)

    _hide_shift_fate_modal()

    if consumed:
        _play_sfx(_load_common_sfx(DROP_CARD_SFX_PATH))
        combat_controller.finalize_post_action()
        set_status("Shift Fate set the next draws.")
    else:
        set_status("Shift Fate could not resolve.")

    _refresh_ui()
