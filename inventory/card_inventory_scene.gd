extends Control

const PLAYER_PROFILE_PATH := "res://profiles/player_main.json"
const HOVEL_SCENE_PATH := "res://hovel/hovel_scene.tscn"
const COMBAT_SCENE_PATH := "res://combat/combat_scene.tscn"
const MINIMUM_DECK_SIZE := 15
const DEFAULT_MAX_DECK_SIZE := 15
const GAME_DATA_LOADER_SCRIPT = preload("res://core/GameDataLoader.gd")
const PROFILE_DECK_SCRIPT = preload("res://core/ProfileDeck.gd")
const PROGRESSION_SCRIPT = preload("res://core/Progression.gd")

@onready var deck_summary_label = $Root/Content/Header/DeckSummary
@onready var status_label = $Root/Content/Header/StatusLabel
@onready var card_list = $Root/Content/Body/Scroll/Rows
@onready var return_button = $Root/Content/Footer/ReturnButton
@onready var go_fight_button = $Root/Content/Footer/GoFightButton
@onready var exit_button = $Root/Content/Footer/ExitGameButton

var loader
var player_profile_data: Dictionary = {}
var selected_deck_counts: Dictionary = {}
var owned_card_counts: Dictionary = {}


func _ready() -> void:
	loader = GAME_DATA_LOADER_SCRIPT.new()
	loader.build_card_registry()
	_load_player_profile()
	_ensure_selected_deck()
	_refresh_scene()
	return_button.pressed.connect(_on_return_pressed)
	go_fight_button.pressed.connect(_on_go_fight_pressed)
	exit_button.pressed.connect(_on_exit_game_pressed)


func _load_player_profile() -> void:
	player_profile_data = loader.load_json(PLAYER_PROFILE_PATH)
	var owned = player_profile_data.get("owned_card_counts", {})
	if owned is Dictionary:
		owned_card_counts = owned.duplicate(true)
	else:
		owned_card_counts = {}


func _ensure_selected_deck() -> void:
	selected_deck_counts = PROFILE_DECK_SCRIPT.get_selected_deck_card_counts(player_profile_data)
	player_profile_data["selected_deck_card_counts"] = selected_deck_counts.duplicate(true)
	_save_player_profile()


func _refresh_scene() -> void:
	_refresh_summary()
	_rebuild_card_rows()
	var can_leave := _can_leave_scene()
	return_button.disabled = not can_leave
	go_fight_button.disabled = not can_leave


func _refresh_summary() -> void:
	var total_cards := PROFILE_DECK_SCRIPT.get_total_cards(selected_deck_counts)
	var max_deck_size := _get_effective_max_deck_size()
	deck_summary_label.text = "Deck: %d cards | Minimum: %d | Max: %d" % [
		total_cards,
		MINIMUM_DECK_SIZE,
		max_deck_size
	]
	if _can_leave_scene():
		status_label.text = "Deck is valid."
	elif total_cards < MINIMUM_DECK_SIZE:
		status_label.text = "Select at least %d cards before leaving." % MINIMUM_DECK_SIZE
	else:
		status_label.text = "Deck exceeds max size of %d." % max_deck_size


func _rebuild_card_rows() -> void:
	for child in card_list.get_children():
		child.queue_free()

	var card_ids: Array = owned_card_counts.keys()
	card_ids.sort()

	for card_id in card_ids:
		var owned_quantity := int(owned_card_counts.get(card_id, 0))
		var selected_quantity := int(selected_deck_counts.get(card_id, 0))
		var card_name := _get_card_name(str(card_id))

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)

		var name_label := Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text = card_name
		row.add_child(name_label)

		var owned_label := Label.new()
		owned_label.custom_minimum_size = Vector2(110, 0)
		owned_label.text = "Owned: %d" % owned_quantity
		row.add_child(owned_label)

		var remove_button := Button.new()
		remove_button.text = "-"
		remove_button.disabled = selected_quantity <= 0
		remove_button.pressed.connect(_on_remove_card.bind(str(card_id)))
		row.add_child(remove_button)

		var selected_label := Label.new()
		selected_label.custom_minimum_size = Vector2(90, 0)
		selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		selected_label.text = "Deck: %d" % selected_quantity
		row.add_child(selected_label)

		var add_button := Button.new()
		add_button.text = "+"
		add_button.disabled = selected_quantity >= owned_quantity or PROFILE_DECK_SCRIPT.get_total_cards(selected_deck_counts) >= _get_effective_max_deck_size()
		add_button.pressed.connect(_on_add_card.bind(str(card_id)))
		row.add_child(add_button)

		card_list.add_child(row)


func _get_card_name(card_id: String) -> String:
	var card_data: Dictionary = loader.get_card(card_id)
	if card_data.is_empty():
		return card_id
	return str(card_data.get("name", card_id))


func _on_add_card(card_id: String) -> void:
	var owned_quantity := int(owned_card_counts.get(card_id, 0))
	var selected_quantity := int(selected_deck_counts.get(card_id, 0))
	if selected_quantity >= owned_quantity:
		return
	if PROFILE_DECK_SCRIPT.get_total_cards(selected_deck_counts) >= _get_effective_max_deck_size():
		status_label.text = "Deck is already at its max size."
		return

	selected_deck_counts[card_id] = selected_quantity + 1
	_save_selected_deck()
	_refresh_scene()


func _on_remove_card(card_id: String) -> void:
	var selected_quantity := int(selected_deck_counts.get(card_id, 0))
	if selected_quantity <= 0:
		return
	if selected_quantity == 1:
		selected_deck_counts.erase(card_id)
	else:
		selected_deck_counts[card_id] = selected_quantity - 1

	_save_selected_deck()
	_refresh_scene()


func _on_return_pressed() -> void:
	if not _can_leave_scene():
		status_label.text = "Select at least %d cards before leaving." % MINIMUM_DECK_SIZE
		return
	get_tree().change_scene_to_file(HOVEL_SCENE_PATH)


func _on_go_fight_pressed() -> void:
	if not _can_leave_scene():
		status_label.text = "Select at least %d cards before fighting." % MINIMUM_DECK_SIZE
		return
	get_tree().change_scene_to_file(COMBAT_SCENE_PATH)


func _on_exit_game_pressed() -> void:
	get_tree().quit()


func _can_leave_scene() -> bool:
	return PROFILE_DECK_SCRIPT.is_valid(
		selected_deck_counts,
		MINIMUM_DECK_SIZE,
		_get_effective_max_deck_size()
	)


func _get_effective_max_deck_size() -> int:
	var player_level := int(player_profile_data.get("player_level", 1))
	var max_deck_size_base := int(player_profile_data.get("max_deck_size_base", DEFAULT_MAX_DECK_SIZE))
	return PROGRESSION_SCRIPT.get_effective_max_deck_size(max_deck_size_base, player_level)


func _save_selected_deck() -> void:
	player_profile_data["selected_deck_card_counts"] = selected_deck_counts.duplicate(true)
	_save_player_profile()


func _save_player_profile() -> void:
	var file := FileAccess.open(PLAYER_PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open player profile for write: " + PLAYER_PROFILE_PATH)
		return

	file.store_string(JSON.stringify(player_profile_data, "\t"))
	file.close()
