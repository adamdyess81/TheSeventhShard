extends PanelContainer

const CARD_RUNTIME_STATE_SCRIPT = preload("res://cards/CardRuntimeState.gd")

static var art_cache: Dictionary = {}

var card_data
var board_index: int = -1
var drag_source: String = "board"
var _is_setup_ready: bool = false
var value_label_base_position: Vector2

@onready var card_canvas: Control = %CardCanvas
@onready var art_rect: TextureRect = %ArtRect
@onready var name_label: Label = %NameLabel
@onready var family_label: Label = %FamilyLabel
@onready var value_label: Label = %ValueLabel

func _ready() -> void:
	value_label_base_position = value_label.position
	_is_setup_ready = true
	if card_data != null:
		_apply_setup()


func setup(card, index: int) -> void:
	card_data = card
	board_index = index
	if not _is_setup_ready:
		return
	_apply_setup()


func set_drag_source(source: String) -> void:
	drag_source = source.strip_edges()


func _apply_setup() -> void:
	_apply_visual_theme()
	_apply_card_art()
	_apply_card_foil()
	
	var meta := _get_card_meta()

	if _is_runtime_card(card_data):
		name_label.text = _get_card_display_name(meta, _humanize_token(card_data.card_id))
		family_label.text = _humanize_token(str(card_data.get_family()))
		value_label.text = _format_card_value(card_data.current_value)
	elif card_data is Dictionary:
		name_label.text = _get_card_display_name(meta, "Unknown")
		family_label.text = _humanize_token(str(card_data.get("family", "")))
		value_label.text = _format_card_value(card_data.get("current_value", card_data.get("base_value", "?")))
	else:
		name_label.text = "Unknown"
		family_label.text = "Unknown"
		value_label.text = "?"

	tooltip_text = _build_tooltip_text()

func _format_card_value(value) -> String:
	if typeof(value) == TYPE_INT:
		return str(value)

	if typeof(value) == TYPE_FLOAT:
		return str(int(value))

	var value_text := str(value).strip_edges()
	if value_text.ends_with(".0"):
		value_text = value_text.substr(0, value_text.length() - 2)

	return value_text

func _get_drag_data(_at_position):
	var combat_scene = get_tree().get_first_node_in_group("combat_scene")
	if combat_scene != null and combat_scene.has_method("is_modal_open") and combat_scene.is_modal_open():
		return null

	if drag_source != "board":
		if combat_scene == null or not combat_scene.can_drag_slot_card(drag_source):
			return null

	var preview = _build_drag_preview()
	set_drag_preview(preview)
	modulate.a = 0.35

	var data = {
		"source": drag_source,
		"card_family": _get_card_family()
	}
	if drag_source == "board":
		data["board_index"] = board_index

	print("drag data: ", data)
	return data


func _can_drop_data(_at_position, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false

	var source := String(data.get("source", "")).strip_edges()
	var dragged_family := String(data.get("card_family", "")).strip_edges()

	var combat_scene = get_tree().get_first_node_in_group("combat_scene")
	if combat_scene == null:
		return false

	if combat_scene.has_method("is_modal_open") and combat_scene.is_modal_open():
		return false

	if source == "board" and dragged_family == "monster":
		if drag_source in ["left_hand", "right_hand"] and _get_card_family() == "shield":
			return combat_scene.can_drop_on_slot(drag_source, data)
		return false

	if source not in ["left_hand", "right_hand"]:
		return false

	if _get_card_family() != "monster":
		return false

	if dragged_family == "weapon":
		return combat_scene.can_use_slot_weapon_on_monster(source)
	if dragged_family == "spell":
		return combat_scene.can_use_slot_spell_on_monster(source)
	return false


func _drop_data(_at_position, data) -> void:
	var combat_scene = get_tree().get_first_node_in_group("combat_scene")
	if combat_scene == null:
		return

	if combat_scene.has_method("is_modal_open") and combat_scene.is_modal_open():
		return

	var source := String(data.get("source", "")).strip_edges()
	if source == "board":
		var board_index := int(data.get("board_index", -1))
		if board_index == -1:
			return
		if drag_source == "left_hand":
			combat_scene.handle_drop_to_left_hand(board_index)
		elif drag_source == "right_hand":
			combat_scene.handle_drop_to_right_hand(board_index)
		return
	combat_scene.handle_slot_card_drop_on_board(source, self.board_index)


func _build_drag_preview() -> Control:
	var preview_root := Control.new()
	preview_root.custom_minimum_size = size
	preview_root.size = size

	var canvas_preview = card_canvas.duplicate()
	canvas_preview.position = Vector2.ZERO
	canvas_preview.scale = Vector2.ONE
	canvas_preview.rotation = 0.0
	canvas_preview.size = size
	if canvas_preview is Control:
		canvas_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	preview_root.add_child(canvas_preview)
	return preview_root


func _apply_card_art() -> void:
	var art_path := String(_get_card_meta().get("art_ref", "")).strip_edges()

	if art_path == "":
		art_rect.texture = null
		return

	if art_cache.has(art_path):
		art_rect.texture = art_cache[art_path]
		return

	var texture = load(art_path)
	if texture is Texture2D:
		art_cache[art_path] = texture
		art_rect.texture = texture
		return

	art_rect.texture = null


func _apply_card_foil() -> void:
	var is_foil := bool(_get_card_meta().get("is_foil", false))

	if art_rect.material == null:
		return

	if not (art_rect.material is ShaderMaterial):
		return

	art_rect.material = art_rect.material.duplicate()

	var shader_material := art_rect.material as ShaderMaterial
	shader_material.set_shader_parameter("foil_enabled", is_foil)

func _get_card_id() -> String:
	if _is_runtime_card(card_data):
		return String(card_data.card_id)

	if card_data is Dictionary:
		return String(card_data.get("id", ""))

	return ""


func _get_card_family() -> String:
	if _is_runtime_card(card_data):
		return String(card_data.get_family())

	if card_data is Dictionary:
		return String(card_data.get("family", ""))

	return ""


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and is_instance_valid(self):
		if not get_viewport().gui_is_drag_successful():
			modulate.a = 1.0


func set_content_visible(is_visible: bool) -> void:
	if card_canvas != null:
		card_canvas.visible = is_visible


func _apply_visual_theme() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0)
	panel_style.border_width_left = 0
	panel_style.border_width_top = 0
	panel_style.border_width_right = 0
	panel_style.border_width_bottom = 0
	panel_style.shadow_size = 0
	add_theme_stylebox_override("panel", panel_style)

	name_label.add_theme_color_override("font_color", Color("f7ead7"))
	name_label.add_theme_font_size_override("font_size", 17)

	family_label.add_theme_color_override("font_color", Color("ddd0bb"))
	family_label.add_theme_font_size_override("font_size", 12)

	value_label.add_theme_color_override("font_color", Color("ffffff"))
	value_label.add_theme_font_size_override("font_size", 18)
	


func _humanize_token(value: String) -> String:
	var cleaned := value.strip_edges().replace("_", " ")
	if cleaned == "":
		return "Unknown"

	var words := cleaned.split(" ", false)
	for i in range(words.size()):
		var word := String(words[i])
		if word == "":
			continue
		words[i] = word.substr(0, 1).to_upper() + word.substr(1)

	return " ".join(words)


func _build_tooltip_text() -> String:
	var meta := _get_card_meta()
	var lines: Array = []

	var display_name := String(meta.get("name", name_label.text)).strip_edges()
	if display_name == "":
		display_name = name_label.text
	lines.append(display_name)

	var identity_parts: Array = []
	var subtype := String(meta.get("subtype", "")).strip_edges()
	if subtype != "":
		identity_parts.append(_humanize_token(subtype))

	var rarity := String(meta.get("rarity", "")).strip_edges()
	if rarity != "":
		identity_parts.append(_humanize_token(rarity))

	if not identity_parts.is_empty():
		lines.append(" • ".join(identity_parts))

	var description := String(meta.get("description", "")).strip_edges()
	if description != "":
		lines.append("")
		lines.append(description)

	var specials_text := _format_specials(meta)
	if specials_text != "":
		lines.append("")
		lines.append("Specials: %s" % specials_text)

	var tags_text := _format_tags(meta.get("tags", []))
	if tags_text != "":
		lines.append("Tags: %s" % tags_text)

	return "\n".join(lines)


func _get_card_meta() -> Dictionary:
	if _is_runtime_card(card_data):
		return card_data.card_data

	if card_data is Dictionary:
		return card_data

	return {}


func _get_card_display_name(meta: Dictionary, fallback: String) -> String:
	var display_name := String(meta.get("name", "")).strip_edges()
	if display_name != "":
		return display_name
	return fallback


func _is_runtime_card(value) -> bool:
	if value == null:
		return false

	if not (value is Object):
		return false

	return value.get_script() == CARD_RUNTIME_STATE_SCRIPT


func _format_specials(meta: Dictionary) -> String:
	var special_rules = meta.get("special_rules", [])
	if not (special_rules is Array):
		return ""

	var special_values = meta.get("special_values", {})
	if not (special_values is Dictionary):
		special_values = {}

	var parts: Array = []
	for rule in special_rules:
		var key := String(rule).strip_edges()
		if key == "":
			continue

		var label := _humanize_token(key)
		if special_values.has(key):
			label += " %s" % str(special_values[key])

		parts.append(label)

	return ", ".join(parts)


func _format_tags(raw_tags) -> String:
	if not (raw_tags is Array):
		return ""

	var tags: Array = []
	for raw_tag in raw_tags:
		var tag := String(raw_tag).strip_edges()
		if tag == "":
			continue
		tags.append(_humanize_token(tag))

	return ", ".join(tags)
