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

 _apply_card_art()

 if card_data is CardRuntimeState:
  name_label.text = card_data.card_id
  family_label.text = str(card_data.get_family())
  value_label.text = "Value: %d" % card_data.current_value
 else:
  name_label.text = "unknown"
  family_label.text = "unknown"
  value_label.text = "Value: ?"

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
