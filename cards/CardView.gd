extends PanelContainer

const CARD_ART_PATHS := {
	"crypt_hound": "res://art/cards/Crypt Hound.png",
	"grave_thrall": "res://art/cards/Grave Thrall.png",
	"large_health_potion": "res://art/cards/Large Healing Potion.png",
	"gold_10": "res://art/cards/Coins.png",
	"risen_bones": "res://art/cards/Risen Bones.png",
	"sepulcher_guard": "res://art/cards/Sepulcher Guard.png",
	"short_sword": "res://art/cards/Short Sword.png",
	"small_chest": "res://art/cards/Small Chest.png",
	"small_health_potion": "res://art/cards/Small Healing Potion.png",
	"small_shield": "res://art/cards/Small Shield.png"
}

var card_data
var board_index: int = -1

@onready var card_canvas: Control = %CardCanvas
@onready var art_rect: TextureRect = %ArtRect
@onready var name_label: Label = %NameLabel
@onready var family_label: Label = %FamilyLabel
@onready var value_label: Label = %ValueLabel

func setup(card, index: int) -> void:
 card_data = card
 board_index = index

 _apply_visual_theme()
 _apply_card_art()

 if card_data is CardRuntimeState:
  name_label.text = _humanize_token(card_data.card_id)
  family_label.text = _humanize_token(str(card_data.get_family()))
  value_label.text = str(card_data.current_value)
 else:
  name_label.text = "Unknown"
  family_label.text = "Unknown"
  value_label.text = "?"

 tooltip_text = "%s\n%s\n%s" % [
  name_label.text,
  family_label.text,
  value_label.text
 ]

func _get_drag_data(_at_position):
 var combat_scene = get_tree().get_first_node_in_group("combat_scene")
 if combat_scene != null and combat_scene.has_method("is_modal_open") and combat_scene.is_modal_open():
  return null

 var preview = duplicate()
 set_drag_preview(preview)
 modulate.a = 0.35

 var data = {
  "source": "board",
  "board_index": board_index,
  "card_family": _get_card_family()
 }

 print("drag data: ", data)
 return data


func _can_drop_data(_at_position, data) -> bool:
 if typeof(data) != TYPE_DICTIONARY:
  return false

 var source := String(data.get("source", "")).strip_edges()
 var dragged_family := String(data.get("card_family", "")).strip_edges()
 if source not in ["left_hand", "right_hand"]:
  return false

 if dragged_family != "weapon" or _get_card_family() != "monster":
  return false

 var combat_scene = get_tree().get_first_node_in_group("combat_scene")
 if combat_scene == null:
  return false

 if combat_scene.has_method("is_modal_open") and combat_scene.is_modal_open():
  return false

 return combat_scene.can_use_slot_weapon_on_monster(source)


func _drop_data(_at_position, data) -> void:
 var combat_scene = get_tree().get_first_node_in_group("combat_scene")
 if combat_scene == null:
  return

 if combat_scene.has_method("is_modal_open") and combat_scene.is_modal_open():
  return

 var source := String(data.get("source", "")).strip_edges()
 combat_scene.handle_weapon_drop_on_board(source, board_index)


func _apply_card_art() -> void:
 var card_id := _get_card_id()
 var art_path = CARD_ART_PATHS.get(card_id, "")

 if art_path == "":
  art_rect.texture = null
  return

 art_rect.texture = load(art_path)


func _get_card_id() -> String:
 if card_data is CardRuntimeState:
  return String(card_data.card_id)

 if card_data is Dictionary:
  return String(card_data.get("id", ""))

 return ""


func _get_card_family() -> String:
 if card_data is CardRuntimeState:
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
