extends Control

const PLAYER_PROFILE_PATH := "res://profiles/player_main.json"
const COMBAT_SCENE_PATH := "res://combat/combat_scene.tscn"
const DEFAULT_STARTING_HEALTH := 20
const DEFAULT_MAX_DECK_SIZE := 15

@onready var health_value = $Root/Content/StatsPanel/StatsContent/StatsRows/HealthRow/Value
@onready var gold_value = $Root/Content/StatsPanel/StatsContent/StatsRows/GoldRow/Value
@onready var xp_value = $Root/Content/StatsPanel/StatsContent/StatsRows/ExperienceRow/Value
@onready var level_value = $Root/Content/StatsPanel/StatsContent/StatsRows/LevelRow/Value
@onready var deck_size_value = $Root/Content/StatsPanel/StatsContent/StatsRows/DeckSizeRow/Value
@onready var status_label = $Root/Content/ActionPanel/ActionContent/StatusLabel
@onready var inventory_overlay = $InventoryOverlay
@onready var inventory_text = $InventoryOverlay/InventoryCenter/InventoryPanel/InventoryContent/InventoryText
@onready var inventory_close_button = $InventoryOverlay/InventoryCenter/InventoryPanel/InventoryContent/CloseButton
@onready var inventory_button = $Root/Content/ActionPanel/ActionContent/ActionButtons/CardInventoryButton
@onready var go_fight_button = $Root/Content/ActionPanel/ActionContent/ActionButtons/GoFightButton
@onready var exit_button = $Root/Content/ActionPanel/ActionContent/ActionButtons/ExitGameButton

var player_profile_data: Dictionary = {}


func _ready() -> void:
	_load_player_profile()
	_refresh_stats()
	_refresh_inventory_text()
	status_label.text = "The Hovel stands ready."
	inventory_close_button.pressed.connect(_on_close_inventory_pressed)
	inventory_button.pressed.connect(_on_card_inventory_pressed)
	go_fight_button.pressed.connect(_on_go_fight_pressed)
	exit_button.pressed.connect(_on_exit_game_pressed)
	inventory_overlay.visible = false


func _load_player_profile() -> void:
	var loader = GameDataLoader.new()
	player_profile_data = loader.load_json(PLAYER_PROFILE_PATH)


func _refresh_stats() -> void:
	var starting_health := int(player_profile_data.get("starting_health_base", DEFAULT_STARTING_HEALTH))
	var persistent_gold := int(player_profile_data.get("persistent_gold", 0))
	var max_deck_size := int(player_profile_data.get("max_deck_size_base", DEFAULT_MAX_DECK_SIZE))
	var total_xp := int(player_profile_data.get("total_xp", 0))
	var progress := Progression.get_current_level_progress(total_xp)

	health_value.text = str(starting_health)
	gold_value.text = str(persistent_gold)
	xp_value.text = "%d total | %d/%d to next" % [
		total_xp,
		int(progress.get("xp_into_level", 0)),
		int(progress.get("xp_to_next_level", 0))
	]
	level_value.text = str(int(progress.get("level", 1)))
	deck_size_value.text = str(max_deck_size)


func _refresh_inventory_text() -> void:
	var owned_cards = player_profile_data.get("owned_card_counts", {})
	if not (owned_cards is Dictionary) or owned_cards.is_empty():
		inventory_text.text = "Card Inventory\n\nNo cards recorded yet."
		return

	var card_lines: Array[String] = []
	var card_ids := owned_cards.keys()
	card_ids.sort()
	for card_id in card_ids:
		card_lines.append("%s x%d" % [str(card_id), int(owned_cards.get(card_id, 0))])

	inventory_text.text = "Card Inventory\n\n%s" % "\n".join(card_lines)


func _on_card_inventory_pressed() -> void:
	inventory_overlay.visible = true
	status_label.text = "Inventory opened."
	inventory_close_button.grab_focus()


func _on_close_inventory_pressed() -> void:
	inventory_overlay.visible = false
	status_label.text = "Inventory closed."
	inventory_button.grab_focus()


func _on_go_fight_pressed() -> void:
	get_tree().change_scene_to_file(COMBAT_SCENE_PATH)


func _on_exit_game_pressed() -> void:
	get_tree().quit()
