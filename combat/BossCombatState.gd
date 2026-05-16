extends RefCounted
class_name BossCombatState

var boss_id: String = ""
var boss_name: String = ""
var max_health: int = 0
var current_health: int = 0
var special_rules: Array = []


func setup(id: String, name: String, starting_health: int, rules: Array = []) -> void:
 boss_id = id
 boss_name = name
 max_health = starting_health
 current_health = starting_health
 special_rules = rules.duplicate(true)


func take_damage(amount: int) -> void:
 current_health = max(current_health - amount, 0)


func heal(amount: int) -> void:
 current_health = min(current_health + amount, max_health)


func is_defeated() -> bool:
 return current_health <= 0
