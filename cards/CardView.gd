extends PanelContainer

var card_data
var board_index: int = -1

@onready var name_label: Label = %NameLabel
@onready var family_label: Label = %FamilyLabel
@onready var value_label: Label = %ValueLabel

func setup(card, index: int) -> void:
 print("card view setup called")
 print(name_label)
 print(family_label)
 print(value_label)

 card_data = card
 board_index = index


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

 var data = {
  "source": "board",
  "board_index": board_index,
  "card_family": _get_card_family()
 }

 print("drag data: ", data)
 return data


func _get_card_family() -> String:
 if card_data is CardRuntimeState:
  return String(card_data.get_family())

 if card_data is Dictionary:
  return String(card_data.get("family", ""))

 return ""
