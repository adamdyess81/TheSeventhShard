extends Control

const PLAYER_PROFILE_PATH := "res://profiles/player_main.json"
const COMBAT_SCENE_PATH := "res://combat/combat_scene.tscn"
const CARD_INVENTORY_SCENE_PATH := "res://inventory/card_inventory_scene.tscn"
const DEFAULT_STARTING_HEALTH := 15
const DEFAULT_MAX_DECK_SIZE := 15
const BOSS_DIRECTORY_PATH := "res://data/bosses"
const DECK_DIRECTORY_PATH := "res://data/decks"
const GAME_DATA_LOADER_SCRIPT = preload("res://core/GameDataLoader.gd")
const HOVEL_SHOP_SCRIPT = preload("res://core/HovelShop.gd")
const PROGRESSION_SCRIPT = preload("res://core/Progression.gd")
const PROFILE_DECK_SCRIPT = preload("res://core/ProfileDeck.gd")
const RUN_CONTEXT_SCRIPT = preload("res://core/RunContext.gd")
const CARD_SALVAGE_SCRIPT = preload("res://core/CardSalvage.gd")
const MINIMUM_DECK_SIZE := 15
const HOVEL_SHOP_RULES_PATH := "res://data/rewards/hovel_shop_common.json"
const KNIGHT_CLASS_PATH := "res://data/classes/knight.json"
const KNIGHT_STARTER_LOADOUT_PATH := "res://data/loadouts/loadout_knight_starter_01.json"
const RESET_PLAYER_LEVEL := 1
const RESET_TOTAL_XP := 0
const RESET_PERSISTENT_GOLD := 0
const RESET_STARTING_HEALTH := 20
const RESET_MAX_DECK_SIZE := 15
const RESET_HOVEL_SHOP_LEVEL := 1

@onready var health_value = $Root/Content/StatsPanel/StatsContent/StatsRows/HealthRow/Value
@onready var gold_value = $Root/Content/StatsPanel/StatsContent/StatsRows/GoldRow/Value
@onready var xp_value = $Root/Content/StatsPanel/StatsContent/StatsRows/ExperienceRow/Value
@onready var level_value = $Root/Content/StatsPanel/StatsContent/StatsRows/LevelRow/Value
@onready var deck_size_value = $Root/Content/StatsPanel/StatsContent/StatsRows/DeckSizeRow/Value
@onready var scrap_value = $Root/Content/StatsPanel/StatsContent/StatsRows/ScrapRow/Value
@onready var essence_value = $Root/Content/StatsPanel/StatsContent/StatsRows/EssenceRow/Value
@onready var opponent_selector = $Root/Content/ActionPanel/ActionContent/OpponentSection/OpponentSelector
@onready var opponent_details_label = $Root/Content/ActionPanel/ActionContent/OpponentSection/OpponentDetailsLabel
@onready var status_label = $Root/Content/ActionPanel/ActionContent/StatusLabel
@onready var shop_offer_one = $Root/Content/ActionPanel/ActionContent/ShopSection/ShopOfferOne
@onready var shop_buy_one = $Root/Content/ActionPanel/ActionContent/ShopSection/ShopBuyOne
@onready var shop_offer_two = $Root/Content/ActionPanel/ActionContent/ShopSection/ShopOfferTwo
@onready var shop_buy_two = $Root/Content/ActionPanel/ActionContent/ShopSection/ShopBuyTwo
@onready var shop_offer_three = $Root/Content/ActionPanel/ActionContent/ShopSection/ShopOfferThree
@onready var shop_buy_three = $Root/Content/ActionPanel/ActionContent/ShopSection/ShopBuyThree
@onready var inventory_button = $Root/Content/ActionPanel/ActionContent/ActionButtons/CardInventoryButton
@onready var go_fight_button = $Root/Content/ActionPanel/ActionContent/ActionButtons/GoFightButton
@onready var reset_button = $Root/Content/ActionPanel/ActionContent/ActionButtons/ResetPlayerButton
@onready var exit_button = $Root/Content/ActionPanel/ActionContent/ActionButtons/ExitGameButton

var player_profile_data: Dictionary = {}
var available_encounters: Array[Dictionary] = []
var loader = GAME_DATA_LOADER_SCRIPT.new()


func _ready() -> void:
	_play_hovel_music()
	loader.build_card_registry()
	_load_player_profile()
	_ensure_hovel_shop_stock()
	_load_available_encounters()
	_refresh_stats()
	_refresh_shop_display()
	_update_selected_encounter_details()
	status_label.text = "The Hovel stands ready."
	shop_buy_one.pressed.connect(_on_shop_buy_pressed.bind(0))
	shop_buy_two.pressed.connect(_on_shop_buy_pressed.bind(1))
	shop_buy_three.pressed.connect(_on_shop_buy_pressed.bind(2))
	inventory_button.pressed.connect(_on_card_inventory_pressed)
	opponent_selector.item_selected.connect(_on_opponent_selected)
	go_fight_button.pressed.connect(_on_go_fight_pressed)
	reset_button.pressed.connect(_on_reset_player_pressed)
	exit_button.pressed.connect(_on_exit_game_pressed)


func _load_player_profile() -> void:
	player_profile_data = loader.load_json(PLAYER_PROFILE_PATH)
	if CARD_SALVAGE_SCRIPT.ensure_profile_resource_fields(player_profile_data):
		_save_player_profile()


func _save_player_profile() -> void:
	var file := FileAccess.open(PLAYER_PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open player profile for write: " + PLAYER_PROFILE_PATH)
		return

	file.store_string(JSON.stringify(player_profile_data, "\t"))
	file.close()


func _ensure_hovel_shop_stock() -> void:
	var shop_state = player_profile_data.get("hovel_shop_state", {})
	if shop_state is Dictionary:
		var offers = shop_state.get("offers", [])
		if offers is Array and not offers.is_empty():
			return

	var refreshed_state: Dictionary = HOVEL_SHOP_SCRIPT.refresh_shop_state(
		player_profile_data,
		loader,
		HOVEL_SHOP_RULES_PATH,
		"hovel_open"
	)
	if not refreshed_state.is_empty():
		_save_player_profile()


func _refresh_shop_display() -> void:
	var offer_labels = [shop_offer_one, shop_offer_two, shop_offer_three]
	var buy_buttons = [shop_buy_one, shop_buy_two, shop_buy_three]
	var shop_state = player_profile_data.get("hovel_shop_state", {})
	var offers = []
	if shop_state is Dictionary:
		offers = shop_state.get("offers", [])

	for index in range(offer_labels.size()):
		var label: Label = offer_labels[index]
		var button: Button = buy_buttons[index]
		if index >= offers.size():
			label.text = "Offer %d: Empty" % [index + 1]
			button.disabled = true
			button.text = "Sold Out"
			continue

		var offer = offers[index]
		if not (offer is Dictionary):
			label.text = "Offer %d: Empty" % [index + 1]
			button.disabled = true
			button.text = "Sold Out"
			continue

		var card_id := str(offer.get("card_id", "")).strip_edges()
		var rarity := str(offer.get("rarity", "")).strip_edges()
		var price := int(offer.get("price", 0))
		label.text = "Offer %d: %s | %s | %d gold" % [
			index + 1,
			_get_card_name(card_id),
			rarity.capitalize(),
			price
		]
		button.disabled = false
		button.text = "Buy"


func _get_card_name(card_id: String) -> String:
	var card_data: Dictionary = loader.get_card(card_id)
	if card_data.is_empty():
		return card_id
	return str(card_data.get("name", card_id))


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
	xp_value.text = "%d total | %d to next level" % [
		total_xp,
		int(progress.get("xp_to_next_level", 0)) - int(progress.get("xp_into_level", 0))		
	]
	level_value.text = str(int(progress.get("level", 1)))
	deck_size_value.text = str(max_deck_size)
	scrap_value.text = str(int(player_profile_data.get("scrap_materials", 0)))
	essence_value.text = str(int(player_profile_data.get("magic_essence", 0)))


func _load_available_encounters() -> void:
	available_encounters.clear()
	opponent_selector.clear()

	var loader = GAME_DATA_LOADER_SCRIPT.new()

	var player_data := loader.load_json(PLAYER_PROFILE_PATH)
	var unlocked_boss_ids: Array = player_data.get("unlocked_boss_ids", [])

	var unlocked_boss_lookup := {}
	for boss_id in unlocked_boss_ids:
		unlocked_boss_lookup[str(boss_id).strip_edges()] = true

	var dir := DirAccess.open(DECK_DIRECTORY_PATH)
	if dir == null:
		status_label.text = "Could not open deck directory."
		return

	var deck_paths: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with("_deck.json"):
			deck_paths.append("%s/%s" % [DECK_DIRECTORY_PATH, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()
	deck_paths.sort()

	for deck_path in deck_paths:
		var deck_data := loader.load_deck(deck_path)
		if deck_data.is_empty():
			continue

		var boss_data_path := str(deck_data.get("boss_data_path", "")).strip_edges()
		if boss_data_path == "":
			continue

		var boss_data := loader.load_json(boss_data_path)
		if boss_data.is_empty():
			continue

		var boss_id := str(boss_data.get("id", "")).strip_edges()
		if boss_id == "":
			continue

		if not unlocked_boss_lookup.has(boss_id):
			continue

		available_encounters.append({
			"boss_id": boss_id,
			"boss_name": str(boss_data.get("name", "Unknown Opponent")).strip_edges(),
			"boss_health": int(boss_data.get("base_health", DEFAULT_STARTING_HEALTH)),
			"deck_id": str(deck_data.get("id", "")).strip_edges(),
			"deck_name": str(deck_data.get("name", "Unknown Deck")).strip_edges(),
			"card_count": _count_deck_entries(deck_data)
		})

	available_encounters.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("boss_name", "")) < str(b.get("boss_name", ""))
	)

	for encounter in available_encounters:
		opponent_selector.add_item(str(encounter.get("boss_name", "Unknown Opponent")))

	if available_encounters.is_empty():
		opponent_details_label.text = "No unlocked boss decks found."
		go_fight_button.disabled = true
		return

	go_fight_button.disabled = false
	var selected_index: int = _find_default_encounter_index()
	opponent_selector.select(selected_index)

func _count_deck_entries(deck_data: Dictionary) -> int:
	var total := 0
	var entries = deck_data.get("entries", [])
	if entries is Array:
		for entry in entries:
			if entry is Dictionary:
				total += int(entry.get("quantity", 0))
	return total


func _find_default_encounter_index() -> int:
	var current_selection: Dictionary = RUN_CONTEXT_SCRIPT.get_battle_selection()
	var selected_boss_id := str(current_selection.get("boss_id", "")).strip_edges()
	var selected_deck_id := str(current_selection.get("monster_deck_id", "")).strip_edges()

	for index in available_encounters.size():
		var encounter := available_encounters[index]
		if str(encounter.get("boss_id", "")) == selected_boss_id and str(encounter.get("deck_id", "")) == selected_deck_id:
			return index

	return 0


func _update_selected_encounter_details() -> void:
	var encounter := _get_selected_encounter()
	if encounter.is_empty():
		opponent_details_label.text = "No opponent selected."
		return

	opponent_details_label.text = "%s HP | %s cards in the encounter deck" % [
		str(encounter.get("boss_health", 0)),
		str(encounter.get("card_count", 0))
	]


func _get_selected_encounter() -> Dictionary:
	var selected_index: int = opponent_selector.get_selected()
	if selected_index < 0 or selected_index >= available_encounters.size():
		return {}
	return available_encounters[selected_index]


func _on_opponent_selected(_index: int) -> void:
	_update_selected_encounter_details()


func _on_card_inventory_pressed() -> void:
	get_tree().change_scene_to_file(CARD_INVENTORY_SCENE_PATH)


func _on_reset_player_pressed() -> void:
	reset_player_profile_to_knight_baseline()
	var refreshed_state: Dictionary = HOVEL_SHOP_SCRIPT.refresh_shop_state(
		player_profile_data,
		loader,
		HOVEL_SHOP_RULES_PATH,
		"player_reset"
	)
	if refreshed_state.is_empty():
		player_profile_data["hovel_shop_state"] = {}
	_save_player_profile()
	_refresh_stats()
	_refresh_shop_display()
	status_label.text = "Player reset to Knight baseline."


func reset_player_profile_to_knight_baseline() -> void:
	var knight_class: Dictionary = loader.load_json(KNIGHT_CLASS_PATH)
	var knight_loadout: Dictionary = loader.load_json(KNIGHT_STARTER_LOADOUT_PATH)
	var starting_inventory := _build_card_counts_from_entries(knight_class.get("starting_card_grants", []))
	var starting_deck := _build_card_counts_from_entries(knight_loadout.get("deck_card_entries", []))

	player_profile_data["active_class_id"] = "knight"
	player_profile_data["hovel_upgrade_ids"] = []
	player_profile_data["hovel_shop_level"] = RESET_HOVEL_SHOP_LEVEL
	player_profile_data["max_deck_size_base"] = RESET_MAX_DECK_SIZE
	player_profile_data["owned_card_counts"] = starting_inventory
	player_profile_data["owned_relic_ids"] = []
	player_profile_data["owned_rune_ids"] = []
	player_profile_data["persistent_gold"] = RESET_PERSISTENT_GOLD
	player_profile_data["scrap_materials"] = 0
	player_profile_data["magic_essence"] = 0
	player_profile_data["player_level"] = RESET_PLAYER_LEVEL
	player_profile_data["progression_flag_ids"] = []
	player_profile_data["saved_loadout_ids"] = ["loadout_knight_starter_01"]
	player_profile_data["selected_deck_card_counts"] = starting_deck
	player_profile_data["starting_health_base"] = RESET_STARTING_HEALTH
	player_profile_data["total_xp"] = RESET_TOTAL_XP
	player_profile_data["unlocked_branch_ids"] = ["ossara"]
	player_profile_data["unlocked_campaign_ids"] = ["ossara_short_01"]
	player_profile_data["unlocked_classes"] = ["knight"]
	player_profile_data["hovel_shop_state"] = {}
	player_profile_data.erase("last_battle_reward_summary")
	player_profile_data["unlocked_boss_ids"] = ["ossaran_lich"]
	player_profile_data["selected_deck_card_instance_ids"] = []
	player_profile_data["owned_card_instances"] = []


func _build_card_counts_from_entries(entries) -> Dictionary:
	var counts: Dictionary = {}
	if not (entries is Array):
		return counts

	for entry in entries:
		if not (entry is Dictionary):
			continue
		var card_id := str(entry.get("card_id", "")).strip_edges()
		if card_id == "":
			continue
		var quantity := int(entry.get("quantity", 0))
		if quantity <= 0:
			continue
		counts[card_id] = quantity

	return counts


func _on_shop_buy_pressed(offer_index: int) -> void:
	var result: Dictionary = HOVEL_SHOP_SCRIPT.purchase_offer(player_profile_data, offer_index)
	if not bool(result.get("ok", false)):
		var reason := str(result.get("reason", "")).strip_edges()
		if reason == "insufficient_gold":
			status_label.text = "Not enough gold for that offer."
		elif reason == "empty_offer_slot":
			status_label.text = "That offer is already gone."
		else:
			status_label.text = "Could not complete that purchase."
		return

	_save_player_profile()
	_refresh_stats()
	_refresh_shop_display()
	var card_id := str(result.get("card_id", "")).strip_edges()
	status_label.text = "Purchased %s for %d gold." % [
		_get_card_name(card_id),
		int(result.get("price", 0))
	]


func _on_go_fight_pressed() -> void:
	var selected_deck_counts := PROFILE_DECK_SCRIPT.get_selected_deck_card_counts(player_profile_data)
	var player_level := int(player_profile_data.get("player_level", 1))
	var max_deck_size_base := int(player_profile_data.get("max_deck_size_base", DEFAULT_MAX_DECK_SIZE))
	var max_deck_size := PROGRESSION_SCRIPT.get_effective_max_deck_size(max_deck_size_base, player_level)
	var validation_error := PROFILE_DECK_SCRIPT.get_validation_error(
		selected_deck_counts,
		MINIMUM_DECK_SIZE,
		max_deck_size,
		loader.card_registry,
		player_profile_data.get("selected_deck_card_instance_ids", []),
		player_profile_data.get("owned_card_instances", [])
	)
	if validation_error != "":
		if validation_error == "duplicate_unique":
			status_label.text = "Deck invalid. Only one copy of each unique card can be equipped."
		elif validation_error == "above_max":
			status_label.text = "Deck invalid. Open Card Inventory and trim the deck to %d cards or fewer." % max_deck_size
		else:
			status_label.text = "Deck invalid. Open Card Inventory and build a deck between %d and %d cards." % [MINIMUM_DECK_SIZE, max_deck_size]
		return

	var encounter := _get_selected_encounter()
	if encounter.is_empty():
		status_label.text = "Choose an opponent before leaving the Hovel."
		return

	RUN_CONTEXT_SCRIPT.set_battle_selection(
		str(encounter.get("boss_id", "")),
		str(encounter.get("deck_id", ""))
	)
	_stop_hovel_music()
	get_tree().change_scene_to_file(COMBAT_SCENE_PATH)


func _on_exit_game_pressed() -> void:
	get_tree().quit()


func _get_music_manager():
	return get_node_or_null("/root/MusicManager")


func _play_hovel_music() -> void:
	var music_manager = _get_music_manager()
	if music_manager != null and music_manager.has_method("play_hovel_music"):
		music_manager.play_hovel_music()


func _stop_hovel_music() -> void:
	var music_manager = _get_music_manager()
	if music_manager != null and music_manager.has_method("stop_hovel_music"):
		music_manager.stop_hovel_music()
