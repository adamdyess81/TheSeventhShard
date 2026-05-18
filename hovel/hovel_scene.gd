extends Control

const PLAYER_PROFILE_PATH := "res://profiles/player_main.json"
const COMBAT_SCENE_PATH := "res://combat/combat_scene.tscn"
const CARD_INVENTORY_SCENE_PATH := "res://inventory/card_inventory_scene.tscn"
const DEFAULT_STARTING_HEALTH := 15
const DEFAULT_MAX_DECK_SIZE := 15
const GAME_DATA_LOADER_SCRIPT = preload("res://core/GameDataLoader.gd")
const PROGRESSION_SCRIPT = preload("res://core/Progression.gd")
const PROFILE_DECK_SCRIPT = preload("res://core/ProfileDeck.gd")
const MINIMUM_DECK_SIZE := 15

@onready var health_value = $Root/Content/StatsPanel/StatsContent/StatsRows/HealthRow/Value
@onready var gold_value = $Root/Content/StatsPanel/StatsContent/StatsRows/GoldRow/Value
@onready var xp_value = $Root/Content/StatsPanel/StatsContent/StatsRows/ExperienceRow/Value
@onready var level_value = $Root/Content/StatsPanel/StatsContent/StatsRows/LevelRow/Value
@onready var deck_size_value = $Root/Content/StatsPanel/StatsContent/StatsRows/DeckSizeRow/Value
@onready var status_label = $Root/Content/ActionPanel/ActionContent/StatusLabel
@onready var inventory_button = $Root/Content/ActionPanel/ActionContent/ActionButtons/CardInventoryButton
@onready var go_fight_button = $Root/Content/ActionPanel/ActionContent/ActionButtons/GoFightButton
@onready var exit_button = $Root/Content/ActionPanel/ActionContent/ActionButtons/ExitGameButton

var player_profile_data: Dictionary = {}


func _ready() -> void:
	_load_player_profile()
	_refresh_stats()
	status_label.text = "The Hovel stands ready."
	inventory_button.pressed.connect(_on_card_inventory_pressed)
	go_fight_button.pressed.connect(_on_go_fight_pressed)
	exit_button.pressed.connect(_on_exit_game_pressed)


func _load_player_profile() -> void:
	var loader = GAME_DATA_LOADER_SCRIPT.new()
	player_profile_data = loader.load_json(PLAYER_PROFILE_PATH)


func _refresh_stats() -> void:
	var player_level := int(player_profile_data.get("player_level", 1))
	var starting_health_base := int(player_profile_data.get("starting_health_base", DEFAULT_STARTING_HEALTH))
	var persistent_gold := int(player_profile_data.get("persistent_gold", 0))
	var max_deck_size_base := int(player_profile_data.get("max_deck_size_base", DEFAULT_MAX_DECK_SIZE))
	var total_xp := int(player_profile_data.get("total_xp", 0))
	var progress: Dictionary = PROGRESSION_SCRIPT.get_current_level_progress(total_xp)
	var starting_health := PROGRESSION_SCRIPT.get_effective_max_health(starting_health_base, player_level)
	var max_deck_size := PROGRESSION_SCRIPT.get_effective_max_deck_size(max_deck_size_base, player_level)

	health_value.text = str(starting_health)
	gold_value.text = str(persistent_gold)
	xp_value.text = "%d total | %d/%d to next level" % [
		total_xp,
		int(progress.get("xp_into_level", 0)),
		int(progress.get("xp_to_next_level", 0))
	]
	level_value.text = str(int(progress.get("level", 1)))
	deck_size_value.text = str(max_deck_size)
func _on_card_inventory_pressed() -> void:
	get_tree().change_scene_to_file(CARD_INVENTORY_SCENE_PATH)


func _on_go_fight_pressed() -> void:
	var selected_deck_counts := PROFILE_DECK_SCRIPT.get_selected_deck_card_counts(player_profile_data)
	var player_level := int(player_profile_data.get("player_level", 1))
	var max_deck_size_base := int(player_profile_data.get("max_deck_size_base", DEFAULT_MAX_DECK_SIZE))
	var max_deck_size := PROGRESSION_SCRIPT.get_effective_max_deck_size(max_deck_size_base, player_level)
	if not PROFILE_DECK_SCRIPT.is_valid(selected_deck_counts, MINIMUM_DECK_SIZE, max_deck_size):
		status_label.text = "Deck invalid. Open Card Inventory and build a deck between %d and %d cards." % [MINIMUM_DECK_SIZE, max_deck_size]
		return

	get_tree().change_scene_to_file(COMBAT_SCENE_PATH)


func _on_exit_game_pressed() -> void:
	get_tree().quit()
