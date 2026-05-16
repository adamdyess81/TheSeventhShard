extends RefCounted
class_name CardRuntimeState

var instance_id: String = ""
var card_id: String = ""
var card_data: Dictionary = {}

var owner_source: String = ""
var zone: String = "deck"

var current_value: int = 0

var is_resolved: bool = false
var is_exhausted: bool = false
var is_destroyed: bool = false

var round_entered: int = -1
var special_state: Dictionary = {}


func setup(
    new_instance_id: String,
    new_card_data: Dictionary,
    new_owner_source: String,
    new_zone: String = "deck",
    new_round_entered: int = -1
) -> void:
    instance_id = new_instance_id
    card_data = new_card_data.duplicate(true)
    card_id = str(card_data.get("id", ""))
    owner_source = new_owner_source
    zone = new_zone
    current_value = 0 if card_data.get("base_value", null) == null else card_data.get("base_value", 0)
    is_resolved = false
    is_exhausted = false
    is_destroyed = false
    round_entered = new_round_entered
    special_state = {}


func get_name() -> String:
    return str(card_data.get("name", ""))


func get_family() -> String:
    return str(card_data.get("family", ""))


func get_base_value() -> int:
    return int(card_data.get("base_value", 0))


func set_zone(new_zone: String) -> void:
    zone = new_zone


func set_current_value(value: int) -> void:
    current_value = value


func mark_resolved() -> void:
    is_resolved = true


func mark_exhausted() -> void:
    is_exhausted = true


func clear_exhausted() -> void:
    is_exhausted = false


func mark_destroyed() -> void:
    is_destroyed = true


func set_special_state(key: String, value) -> void:
    special_state[key] = value


func get_special_state(key: String, default_value = null):
    return special_state.get(key, default_value)
