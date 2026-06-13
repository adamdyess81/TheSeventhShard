extends Control

const PLAYER_PROFILE_PATH := "res://profiles/player_main.json"
const HOVEL_SCENE_PATH := "res://hovel/hovel_scene.tscn"
const COMBAT_SCENE_PATH := "res://combat/combat_scene.tscn"
const MINIMUM_DECK_SIZE := 15
const DEFAULT_MAX_DECK_SIZE := 15
const GAME_DATA_LOADER_SCRIPT = preload("res://core/GameDataLoader.gd")
const PROFILE_DECK_SCRIPT = preload("res://core/ProfileDeck.gd")
const PROGRESSION_SCRIPT = preload("res://core/Progression.gd")
const CARD_AFFIX_LIBRARY_SCRIPT = preload("res://core/CardAffixLibrary.gd")
const CARD_SALVAGE_SCRIPT = preload("res://core/CardSalvage.gd")
const CARD_BACK_TEXTURE = preload("res://art/ui/CardBack.png")
const PANEL_FILL = Color("18110d")
const PANEL_BORDER = Color("75563c")
const TEXT_PRIMARY = Color("f1e7d6")
const TEXT_MUTED = Color("c7b79f")
const TEXT_SUCCESS = Color("d6c583")
const TEXT_ERROR = Color("d38a80")
const TILE_WIDTH := 220.0
const TILE_ART_HEIGHT := 250.0
const CARD_VIEW_SCENE = preload("res://cards/card_view.tscn")

@onready var deck_summary_label = $Root/Content/Header/DeckSummary
@onready var status_label = $Root/Content/Header/StatusLabel
@onready var body_panel = $Root/Content/Body
@onready var card_scroll = $Root/Content/Body/BodyMargin/Scroll
@onready var card_grid = $Root/Content/Body/BodyMargin/Scroll/CardGrid
@onready var return_button = $Root/Content/Footer/ReturnButton
@onready var go_fight_button = $Root/Content/Footer/GoFightButton
@onready var exit_button = $Root/Content/Footer/ExitGameButton

var loader
var player_profile_data: Dictionary = {}
var selected_deck_counts: Dictionary = {}
var owned_card_counts: Dictionary = {}
var card_texture_cache: Dictionary = {}
var owned_card_instances: Array = []
var selected_deck_card_instance_ids: Array = []


func _ready() -> void:
	_play_hovel_music()
	loader = GAME_DATA_LOADER_SCRIPT.new()
	loader.build_card_registry()
	_load_player_profile()
	_ensure_selected_deck()
	_apply_visual_theme()
	_refresh_scene()
	return_button.pressed.connect(_on_return_pressed)
	go_fight_button.pressed.connect(_on_go_fight_pressed)
	exit_button.pressed.connect(_on_exit_game_pressed)
	get_viewport().size_changed.connect(_on_viewport_resized)
	call_deferred("_update_grid_columns")


func _load_player_profile() -> void:
	player_profile_data = loader.load_json(PLAYER_PROFILE_PATH)
	CARD_SALVAGE_SCRIPT.ensure_profile_resource_fields(player_profile_data)

	var owned = player_profile_data.get("owned_card_counts", {})
	if owned is Dictionary:
		owned_card_counts = owned.duplicate(true)
	else:
		owned_card_counts = {}

	var owned_instances = player_profile_data.get("owned_card_instances", [])
	if owned_instances is Array:
		owned_card_instances = owned_instances.duplicate(true)
	else:
		owned_card_instances = []

	var selected_instances = player_profile_data.get("selected_deck_card_instance_ids", [])
	if selected_instances is Array:
		selected_deck_card_instance_ids = selected_instances.duplicate(true)
	else:
		selected_deck_card_instance_ids = []


func _ensure_selected_deck() -> void:
	selected_deck_counts = PROFILE_DECK_SCRIPT.get_selected_deck_card_counts(player_profile_data)
	player_profile_data["selected_deck_card_counts"] = selected_deck_counts.duplicate(true)

	var selected_instances = player_profile_data.get("selected_deck_card_instance_ids", [])
	if selected_instances is Array:
		selected_deck_card_instance_ids = selected_instances.duplicate(true)
	else:
		selected_deck_card_instance_ids = []
		player_profile_data["selected_deck_card_instance_ids"] = []

	_save_player_profile()


func _refresh_scene() -> void:
	_refresh_summary()
	_rebuild_card_rows()
	var can_leave := _can_leave_scene()
	return_button.disabled = not can_leave
	go_fight_button.disabled = not can_leave


func _refresh_summary() -> void:
	var total_cards := _get_total_selected_cards()
	var max_deck_size := _get_effective_max_deck_size()
	deck_summary_label.text = "Scrap: %d | Essence: %d\nDeck: %d cards | Minimum: %d | Max: %d" % [
		int(player_profile_data.get("scrap_materials", 0)),
		int(player_profile_data.get("magic_essence", 0)),
		total_cards,
		MINIMUM_DECK_SIZE,
		max_deck_size
	]
	if _can_leave_scene():
		status_label.text = "Deck is valid."
		status_label.modulate = TEXT_SUCCESS
	elif total_cards < MINIMUM_DECK_SIZE:
		status_label.text = "Select at least %d cards before leaving." % MINIMUM_DECK_SIZE
		status_label.modulate = TEXT_ERROR
	else:
		status_label.text = "Deck exceeds max size of %d." % max_deck_size
		status_label.modulate = TEXT_ERROR

func _get_total_selected_cards() -> int:
	return PROFILE_DECK_SCRIPT.get_total_cards(selected_deck_counts) + selected_deck_card_instance_ids.size()
	
func _rebuild_card_rows() -> void:
	for child in card_grid.get_children():
		child.queue_free()

	var sorted_instances := owned_card_instances.duplicate()
	sorted_instances.sort_custom(func(a, b):
		if not (a is Dictionary) or not (b is Dictionary):
			return false

		return _get_instance_display_name(a).naturalnocasecmp_to(_get_instance_display_name(b)) < 0
	)

	for card_instance in sorted_instances:
		if not (card_instance is Dictionary):
			continue

		card_grid.add_child(_build_card_instance_tile(card_instance))

	var card_ids: Array = owned_card_counts.keys()
	card_ids.sort_custom(func(a, b): return _get_card_name(str(a)).naturalnocasecmp_to(_get_card_name(str(b))) < 0)

	for card_id in card_ids:
		var owned_quantity := int(owned_card_counts.get(card_id, 0))
		var selected_quantity := int(selected_deck_counts.get(card_id, 0))
		card_grid.add_child(_build_card_tile(str(card_id), owned_quantity, selected_quantity))

	_update_grid_columns()

func _build_card_instance_tile(card_instance: Dictionary) -> Control:
	var instance_id := str(card_instance.get("instance_id", "")).strip_edges()

	var is_selected := selected_deck_card_instance_ids.has(instance_id)
	var display_data := _build_instance_display_data(card_instance)

	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(TILE_WIDTH, 460)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var tile_style := StyleBoxFlat.new()
	tile_style.bg_color = PANEL_FILL
	tile_style.border_width_left = 2
	tile_style.border_width_top = 2
	tile_style.border_width_right = 2
	tile_style.border_width_bottom = 2
	tile_style.border_color = Color("d7b17a")
	tile_style.corner_radius_top_left = 10
	tile_style.corner_radius_top_right = 10
	tile_style.corner_radius_bottom_right = 10
	tile_style.corner_radius_bottom_left = 10
	tile.add_theme_stylebox_override("panel", tile_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	tile.add_child(margin)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)

	var card_holder := CenterContainer.new()
	card_holder.custom_minimum_size = Vector2(0, 330)
	card_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(card_holder)

	var card_view = CARD_VIEW_SCENE.instantiate()
	card_view.custom_minimum_size = Vector2(220, 302)
	card_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	if card_view.has_method("setup"):
		card_view.setup(display_data, -1)

	card_holder.add_child(card_view)
	
	var name_label := Label.new()
	name_label.text = str(display_data.get("name", "Unknown Card"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.modulate = Color("f6d77b")
	stack.add_child(name_label)

	var counts_label := Label.new()
	counts_label.text = "Affixed Card   Deck: %s" % ["Yes" if is_selected else "No"]
	counts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counts_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	counts_label.modulate = TEXT_MUTED
	stack.add_child(counts_label)

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 10)
	stack.add_child(controls)

	var remove_button := Button.new()
	remove_button.text = "-"
	remove_button.custom_minimum_size = Vector2(46, 36)
	remove_button.disabled = not is_selected
	remove_button.pressed.connect(_on_remove_card_instance.bind(instance_id))
	controls.add_child(remove_button)

	var deck_label := Label.new()
	deck_label.custom_minimum_size = Vector2(58, 0)
	deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_label.text = "1" if is_selected else "0"
	deck_label.modulate = TEXT_PRIMARY
	controls.add_child(deck_label)

	var add_button := Button.new()
	add_button.text = "+"
	add_button.custom_minimum_size = Vector2(46, 36)
	add_button.disabled = is_selected or _get_total_selected_cards() >= _get_effective_max_deck_size()
	add_button.pressed.connect(_on_add_card_instance.bind(instance_id))
	controls.add_child(add_button)

	var salvage_button := Button.new()
	salvage_button.text = _build_salvage_button_text(display_data, card_instance.get("affix_ids", []))
	salvage_button.disabled = not CARD_SALVAGE_SCRIPT.is_salvageable(display_data)
	salvage_button.pressed.connect(_on_salvage_card_instance.bind(instance_id))
	stack.add_child(salvage_button)

	return tile

func _build_instance_display_data(card_instance: Dictionary) -> Dictionary:
	var card_id := str(card_instance.get("card_id", "")).strip_edges()

	var base_card_data: Dictionary = loader.get_card(card_id)
	var display_data := base_card_data.duplicate(true)

	var affix_ids = card_instance.get("affix_ids", [])
	if not (affix_ids is Array):
		affix_ids = []

	display_data["id"] = card_id
	display_data["card_id"] = card_id
	display_data["instance_id"] = str(card_instance.get("instance_id", "")).strip_edges()
	display_data["affix_ids"] = affix_ids

	CARD_AFFIX_LIBRARY_SCRIPT.apply_affixes_to_card_data(display_data, base_card_data, card_id, affix_ids)

	return display_data

func _on_add_card_instance(instance_id: String) -> void:
	if instance_id == "":
		return

	if selected_deck_card_instance_ids.has(instance_id):
		return

	if _get_total_selected_cards() >= _get_effective_max_deck_size():
		status_label.text = "Deck is already at its max size."
		return

	selected_deck_card_instance_ids.append(instance_id)
	_save_selected_deck()
	_refresh_scene()

func _on_remove_card_instance(instance_id: String) -> void:
	if instance_id == "":
		return

	selected_deck_card_instance_ids.erase(instance_id)

	_save_selected_deck()
	_refresh_scene()

func _build_card_tile(card_id: String, owned_quantity: int, selected_quantity: int) -> Control:
	var card_data: Dictionary = loader.get_card(card_id)

	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(TILE_WIDTH, 460)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var tile_style := StyleBoxFlat.new()
	tile_style.bg_color = PANEL_FILL
	tile_style.border_width_left = 2
	tile_style.border_width_top = 2
	tile_style.border_width_right = 2
	tile_style.border_width_bottom = 2
	tile_style.border_color = PANEL_BORDER
	tile_style.corner_radius_top_left = 10
	tile_style.corner_radius_top_right = 10
	tile_style.corner_radius_bottom_right = 10
	tile_style.corner_radius_bottom_left = 10
	tile.add_theme_stylebox_override("panel", tile_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	tile.add_child(margin)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)

	var card_holder := CenterContainer.new()
	card_holder.custom_minimum_size = Vector2(0, 330)
	card_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(card_holder)

	var card_view = CARD_VIEW_SCENE.instantiate()
	card_view.custom_minimum_size = Vector2(220, 302)
	card_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	if card_view.has_method("setup"):
		card_view.setup(card_data, -1)

	card_holder.add_child(card_view)
	
	var name_label := Label.new()
	name_label.text = str(card_data.get("name", card_id))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.modulate = TEXT_PRIMARY
	stack.add_child(name_label)

	var counts_label := Label.new()
	counts_label.text = "Inventory: %d   Deck: %d" % [owned_quantity, selected_quantity]
	counts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counts_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	counts_label.modulate = TEXT_MUTED
	stack.add_child(counts_label)

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 10)
	stack.add_child(controls)

	var remove_button := Button.new()
	remove_button.text = "-"
	remove_button.custom_minimum_size = Vector2(46, 36)
	remove_button.disabled = selected_quantity <= 0
	remove_button.pressed.connect(_on_remove_card.bind(card_id))
	controls.add_child(remove_button)

	var deck_label := Label.new()
	deck_label.custom_minimum_size = Vector2(58, 0)
	deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_label.text = str(selected_quantity)
	deck_label.modulate = TEXT_PRIMARY
	controls.add_child(deck_label)

	var add_button := Button.new()
	add_button.text = "+"
	add_button.custom_minimum_size = Vector2(46, 36)
	add_button.disabled = selected_quantity >= owned_quantity or _get_total_selected_cards() >= _get_effective_max_deck_size()
	add_button.pressed.connect(_on_add_card.bind(card_id))
	controls.add_child(add_button)

	var salvage_button := Button.new()
	salvage_button.text = _build_salvage_button_text(card_data)
	salvage_button.disabled = not CARD_SALVAGE_SCRIPT.is_salvageable(card_data)
	salvage_button.pressed.connect(_on_salvage_card.bind(card_id))
	stack.add_child(salvage_button)

	return tile


func _get_card_name(card_id: String) -> String:
	var card_data: Dictionary = loader.get_card(card_id)
	if card_data.is_empty():
		return card_id
	return str(card_data.get("name", card_id))


func _get_card_texture(card_data: Dictionary) -> Texture2D:
	var art_ref := str(card_data.get("art_ref", "")).strip_edges()
	if art_ref == "":
		return CARD_BACK_TEXTURE
	if card_texture_cache.has(art_ref):
		return card_texture_cache[art_ref]
	var texture = load(art_ref)
	if texture is Texture2D:
		card_texture_cache[art_ref] = texture
		return texture
	return CARD_BACK_TEXTURE


func _on_add_card(card_id: String) -> void:
	var owned_quantity := int(owned_card_counts.get(card_id, 0))
	var selected_quantity := int(selected_deck_counts.get(card_id, 0))
	if selected_quantity >= owned_quantity:
		return
	if _get_total_selected_cards() >= _get_effective_max_deck_size():
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


func _on_salvage_card(card_id: String) -> void:
	var card_data: Dictionary = loader.get_card(card_id)
	var result := CARD_SALVAGE_SCRIPT.salvage_card_stack(player_profile_data, card_data, card_id)
	if not bool(result.get("ok", false)):
		status_label.text = "Could not salvage %s." % _get_card_name(card_id)
		return

	owned_card_counts = player_profile_data.get("owned_card_counts", {}).duplicate(true)
	selected_deck_counts = player_profile_data.get("selected_deck_card_counts", {}).duplicate(true)
	_save_player_profile()
	_refresh_scene()
	status_label.text = "Salvaged %s for %s." % [
		_get_card_name(card_id),
		_format_salvage_reward_text(int(result.get("scrap_materials", 0)), int(result.get("magic_essence", 0)))
	]
	status_label.modulate = TEXT_SUCCESS


func _on_salvage_card_instance(instance_id: String) -> void:
	if instance_id == "":
		return

	var card_instance := _find_owned_card_instance(instance_id)
	if card_instance.is_empty():
		status_label.text = "Could not find that affixed card to salvage."
		status_label.modulate = TEXT_ERROR
		return

	var card_id := str(card_instance.get("card_id", "")).strip_edges()
	var base_card_data: Dictionary = loader.get_card(card_id)
	var affix_ids = card_instance.get("affix_ids", [])
	if not (affix_ids is Array):
		affix_ids = []

	var result := CARD_SALVAGE_SCRIPT.salvage_card_instance(player_profile_data, base_card_data, instance_id, affix_ids)
	if not bool(result.get("ok", false)):
		status_label.text = "Could not salvage %s." % _get_instance_display_name(card_instance)
		status_label.modulate = TEXT_ERROR
		return

	owned_card_instances = player_profile_data.get("owned_card_instances", []).duplicate(true)
	selected_deck_card_instance_ids = player_profile_data.get("selected_deck_card_instance_ids", []).duplicate(true)
	_save_player_profile()
	_refresh_scene()
	status_label.text = "Salvaged %s for %s." % [
		_get_instance_display_name(card_instance),
		_format_salvage_reward_text(int(result.get("scrap_materials", 0)), int(result.get("magic_essence", 0)))
	]
	status_label.modulate = TEXT_SUCCESS


func _on_return_pressed() -> void:
	if not _can_leave_scene():
		status_label.text = "Select at least %d cards before leaving." % MINIMUM_DECK_SIZE
		return
	get_tree().change_scene_to_file(HOVEL_SCENE_PATH)


func _on_go_fight_pressed() -> void:
	if not _can_leave_scene():
		status_label.text = "Select at least %d cards before fighting." % MINIMUM_DECK_SIZE
		return
	_stop_hovel_music()
	get_tree().change_scene_to_file(COMBAT_SCENE_PATH)


func _on_exit_game_pressed() -> void:
	get_tree().quit()


func _can_leave_scene() -> bool:
	var total_cards := _get_total_selected_cards()
	var max_deck_size := _get_effective_max_deck_size()

	return total_cards >= MINIMUM_DECK_SIZE and total_cards <= max_deck_size


func _get_effective_max_deck_size() -> int:
	var player_level := int(player_profile_data.get("player_level", 1))
	var max_deck_size_base := int(player_profile_data.get("max_deck_size_base", DEFAULT_MAX_DECK_SIZE))
	return PROGRESSION_SCRIPT.get_effective_max_deck_size(max_deck_size_base, player_level)


func _save_selected_deck() -> void:
	player_profile_data["selected_deck_card_counts"] = selected_deck_counts.duplicate(true)
	player_profile_data["selected_deck_card_instance_ids"] = selected_deck_card_instance_ids.duplicate(true)
	_save_player_profile()

func _get_instance_display_name(card_instance: Dictionary) -> String:
	var card_id := str(card_instance.get("card_id", "")).strip_edges()
	var base_name := _get_card_name(card_id)

	var affix_ids = card_instance.get("affix_ids", [])
	if not (affix_ids is Array):
		return base_name

	return CARD_AFFIX_LIBRARY_SCRIPT.build_affixed_name(base_name, affix_ids)

func _save_player_profile() -> void:
	var file := FileAccess.open(PLAYER_PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open player profile for write: " + PLAYER_PROFILE_PATH)
		return

	file.store_string(JSON.stringify(player_profile_data, "\t"))
	file.close()


func _apply_visual_theme() -> void:
	deck_summary_label.modulate = TEXT_PRIMARY
	status_label.modulate = TEXT_MUTED
	var body_style := StyleBoxFlat.new()
	body_style.bg_color = Color("0e0a08")
	body_style.border_width_left = 2
	body_style.border_width_top = 2
	body_style.border_width_right = 2
	body_style.border_width_bottom = 2
	body_style.border_color = PANEL_BORDER
	body_style.corner_radius_top_left = 12
	body_style.corner_radius_top_right = 12
	body_style.corner_radius_bottom_right = 12
	body_style.corner_radius_bottom_left = 12
	body_panel.add_theme_stylebox_override("panel", body_style)


func _on_viewport_resized() -> void:
	_update_grid_columns()


func _update_grid_columns() -> void:
	if card_grid == null or card_scroll == null:
		return
	var available_width: float = maxf(card_scroll.size.x - 16.0, TILE_WIDTH)
	var columns := int(floor(available_width / (TILE_WIDTH + 16.0)))
	card_grid.columns = clampi(columns, 1, 5)


func _find_owned_card_instance(instance_id: String) -> Dictionary:
	for card_instance in owned_card_instances:
		if card_instance is Dictionary and str(card_instance.get("instance_id", "")).strip_edges() == instance_id:
			return card_instance
	return {}


func _build_salvage_button_text(card_data: Dictionary, affix_ids: Array = []) -> String:
	if not CARD_SALVAGE_SCRIPT.is_salvageable(card_data):
		return "Cannot Salvage"

	var rewards := CARD_SALVAGE_SCRIPT.calculate_salvage_rewards(card_data, affix_ids)
	return "Salvage (%s)" % _format_salvage_reward_text(
		int(rewards.get("scrap_materials", 0)),
		int(rewards.get("magic_essence", 0))
	)


func _format_salvage_reward_text(scrap_materials: int, magic_essence: int) -> String:
	var parts: Array[String] = []
	if scrap_materials > 0:
		parts.append("%d Scrap" % scrap_materials)
	if magic_essence > 0:
		parts.append("%d Essence" % magic_essence)
	if parts.is_empty():
		return "No salvage reward"
	return " + ".join(parts)


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
