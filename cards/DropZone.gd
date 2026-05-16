extends PanelContainer

@export var drop_target: String = ""
@export var combat_scene_path: NodePath

var combat_scene

func _ready() -> void:
 combat_scene = get_node_or_null(combat_scene_path)
 print("DropZone ready: ", name)
 print("drop_target: ", drop_target)
 print("combat_scene_path: ", combat_scene_path)
 print("combat_scene: ", combat_scene)

func _can_drop_data(_at_position, data) -> bool:
 var can_drop = typeof(data) == TYPE_DICTIONARY and data.get("source", "") == "board"
 print("_can_drop_data called on ", name, " with data: ", data, " result: ", can_drop)
 return can_drop


func _drop_data(_at_position, data) -> void:
 print("_drop_data called on ", name, " with data: ", data)

 if combat_scene == null:
  print("combat_scene is null")
  return

 var board_index: int = data.get("board_index", -1)
 if board_index == -1:
  print("invalid board_index")
  return

 var normalized_target = String(drop_target).strip_edges()
 print("drop_target value is: '", normalized_target, "'")

 if normalized_target == "left_hand":
  print("calling handle_drop_to_left_hand with index ", board_index)
  combat_scene.handle_drop_to_left_hand(board_index)
 elif normalized_target == "right_hand":
  print("calling handle_drop_to_right_hand with index ", board_index)
  combat_scene.handle_drop_to_right_hand(board_index)
 elif normalized_target == "backpack":
  print("calling handle_drop_to_backpack with index ", board_index)
  combat_scene.handle_drop_to_backpack(board_index)
 else:
  print("unhandled drop_target: '", normalized_target, "'")
