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
  value_label.text = "Value %d" % card_data.current_value
 else:
  name_label.text = "Unknown"
  family_label.text = "Unknown"
  value_label.text = "Value ?"

 tooltip_text = "%s\n%s\n%s" % [
  name_label.text,
  family_label.text,
  value_label.text
 ]

func _get_drag_data(_at_position):
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


func _apply_visual_theme() -> void:
 var family := _get_card_family()
 var accent := _get_family_color(family)

 var panel_style := StyleBoxFlat.new()
 panel_style.bg_color = Color("171311")
 panel_style.border_color = accent
 panel_style.border_width_left = 2
 panel_style.border_width_top = 2
 panel_style.border_width_right = 2
 panel_style.border_width_bottom = 2
 panel_style.corner_radius_top_left = 14
 panel_style.corner_radius_top_right = 14
 panel_style.corner_radius_bottom_right = 14
 panel_style.corner_radius_bottom_left = 14
 panel_style.shadow_color = Color(0, 0, 0, 0.35)
 panel_style.shadow_size = 6
 add_theme_stylebox_override("panel", panel_style)

 name_label.add_theme_color_override("font_color", Color("f5ead7"))
 name_label.add_theme_font_size_override("font_size", 17)

 family_label.add_theme_color_override("font_color", accent)
 family_label.add_theme_font_size_override("font_size", 12)

 value_label.add_theme_color_override("font_color", Color("d7c7b1"))
 value_label.add_theme_font_size_override("font_size", 12)


func _get_family_color(family: String) -> Color:
 match family:
  "monster":
   return Color("c86b63")
  "weapon":
   return Color("d3b06a")
  "shield":
   return Color("8fb6c9")
  "potion":
   return Color("9dc27f")
  "coin", "chest":
   return Color("d6b55f")
  _:
   return Color("927f66")


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
