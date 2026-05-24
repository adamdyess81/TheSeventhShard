extends PanelContainer

@export var drop_target: String = ""
@export var combat_scene_path: NodePath
@export var allowed_families: Array[String] = []

var combat_scene

func _ready() -> void:
 combat_scene = get_node_or_null(combat_scene_path)
 mouse_exited.connect(_on_mouse_exited)
 print("DropZone ready: ", name)
 print("drop_target: ", drop_target)
 print("combat_scene_path: ", combat_scene_path)
 print("combat_scene: ", combat_scene)

func _can_drop_data(_at_position, data) -> bool:
 var can_drop = typeof(data) == TYPE_DICTIONARY
 if not can_drop or combat_scene == null:
  print("_can_drop_data called on ", name, " with data: ", data, " result: ", can_drop)
  return false

 if combat_scene.has_method("is_modal_open") and combat_scene.is_modal_open():
  return false

 var normalized_target = String(drop_target).strip_edges()
 can_drop = combat_scene.can_drop_on_slot(normalized_target, data)
 combat_scene.preview_drop_zone_state(normalized_target, can_drop)
 print("_can_drop_data called on ", name, " with data: ", data, " result: ", can_drop)
 return can_drop


func _get_drag_data(_at_position):
 if combat_scene == null:
  return null

 if combat_scene.has_method("is_modal_open") and combat_scene.is_modal_open():
  return null

 if drop_target not in ["left_hand", "right_hand", "backpack"]:
  return null

 if not combat_scene.can_drag_slot_card(drop_target):
  return null

 var preview = _build_slot_drag_preview()
 set_drag_preview(preview)
 modulate.a = 0.35

 var data = {
  "source": drop_target,
  "card_family": combat_scene.get_slot_card_family(drop_target)
 }

 print("slot drag data: ", data)
 return data


func _build_slot_drag_preview() -> Control:
 var preview_root := Control.new()
 preview_root.custom_minimum_size = size
 preview_root.size = size

 var card_canvas = get_node_or_null("CardCanvas")
 if card_canvas != null:
  var canvas_preview = card_canvas.duplicate()
  canvas_preview.position = Vector2.ZERO
  canvas_preview.size = size
  if canvas_preview is Control:
   canvas_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  preview_root.add_child(canvas_preview)
 else:
  var fallback = duplicate()
  if fallback is Control:
   fallback.position = Vector2.ZERO
  preview_root.add_child(fallback)

 return preview_root


func _drop_data(_at_position, data) -> void:
 print("_drop_data called on ", name, " with data: ", data)

 if combat_scene == null:
  print("combat_scene is null")
  return

 if combat_scene.has_method("is_modal_open") and combat_scene.is_modal_open():
  return

 var normalized_target = String(drop_target).strip_edges()
 combat_scene.clear_all_drop_zone_previews()
 print("drop_target value is: '", normalized_target, "'")

 if data.get("source", "") == "board":
  var board_index: int = data.get("board_index", -1)
  if board_index == -1:
   print("invalid board_index")
   return

  if normalized_target == "left_hand":
   print("calling handle_drop_to_left_hand with index ", board_index)
   combat_scene.handle_drop_to_left_hand(board_index)
  elif normalized_target == "right_hand":
   print("calling handle_drop_to_right_hand with index ", board_index)
   combat_scene.handle_drop_to_right_hand(board_index)
  elif normalized_target == "backpack":
   print("calling handle_drop_to_backpack with index ", board_index)
   combat_scene.handle_drop_to_backpack(board_index)
  elif normalized_target == "player_avatar":
   print("calling handle_drop_to_player_avatar with index ", board_index)
   combat_scene.handle_drop_to_player_avatar(board_index)
  elif normalized_target == "discard":
   print("calling handle_drop_to_discard with index ", board_index)
   combat_scene.handle_drop_to_discard(board_index)
  elif normalized_target == "boss":
   print("boss only accepts slot-dragged weapons")
  else:
   print("unhandled board drop_target: '", normalized_target, "'")
 elif normalized_target in ["left_hand", "right_hand", "backpack", "discard", "boss", "player_avatar"]:
  if normalized_target == "boss":
   combat_scene.handle_slot_card_drop_on_boss(String(data.get("source", "")).strip_edges())
  elif normalized_target == "player_avatar":
   combat_scene.handle_slot_card_drop_on_player_avatar(String(data.get("source", "")).strip_edges())
  else:
   combat_scene.handle_slot_to_slot_drop(String(data.get("source", "")).strip_edges(), normalized_target)
 else:
  print("unhandled drop_target: '", normalized_target, "'")


func _notification(what: int) -> void:
 if what == NOTIFICATION_DRAG_END and is_instance_valid(self):
  if combat_scene != null:
   combat_scene.clear_all_drop_zone_previews()
  if not get_viewport().gui_is_drag_successful():
   modulate.a = 1.0


func _on_mouse_exited() -> void:
 if combat_scene != null:
  combat_scene.clear_all_drop_zone_previews()
