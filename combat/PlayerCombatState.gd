extends RefCounted
class_name PlayerCombatState

var max_health: int = 0
var current_health: int = 0
var temporary_gold: int = 0
var carried_chests: Array = []

var left_hand_card = null
var right_hand_card = null

var backpack_cards: Array = []

var left_hand_exhausted: bool = false
var right_hand_exhausted: bool = false

var backpack_capacity: int = 1


func setup(starting_health: int, starting_backpack_capacity: int = 1) -> void:
    max_health = starting_health
    current_health = starting_health
    temporary_gold = 0
    carried_chests.clear()

    left_hand_card = null
    right_hand_card = null

    backpack_cards.clear()

    left_hand_exhausted = false
    right_hand_exhausted = false

    backpack_capacity = starting_backpack_capacity


func take_damage(amount: int) -> void:
    current_health = max(current_health - amount, 0)


func heal(amount: int) -> void:
    current_health = min(current_health + amount, max_health)


func add_temporary_gold(amount: int) -> void:
    temporary_gold += amount


func add_carried_chest(chest_card) -> void:
    carried_chests.append(chest_card)


func set_left_hand_card(card) -> bool:
    if left_hand_exhausted or left_hand_card != null:
        return false

    _set_card_zone(card, "left_hand")
    left_hand_card = card
    return true


func set_right_hand_card(card) -> bool:
    if right_hand_exhausted or right_hand_card != null:
        return false

    _set_card_zone(card, "right_hand")
    right_hand_card = card
    return true


func clear_left_hand_card() -> void:
    left_hand_card = null


func clear_right_hand_card() -> void:
    right_hand_card = null


func exhaust_left_hand() -> void:
    left_hand_exhausted = true


func exhaust_right_hand() -> void:
    right_hand_exhausted = true


func reset_hand_exhaustion() -> void:
    left_hand_exhausted = false
    right_hand_exhausted = false


func add_to_backpack(card) -> bool:
    if backpack_cards.size() >= backpack_capacity:
        return false

    _set_card_zone(card, "backpack")
    backpack_cards.append(card)
    return true


func remove_backpack_card_at(index: int):
    if index < 0 or index >= backpack_cards.size():
        return null

    return backpack_cards.pop_at(index)


func is_dead() -> bool:
    return current_health <= 0


func _set_card_zone(card, new_zone: String) -> void:
    if card is CardRuntimeState:
        card.set_zone(new_zone)
    elif card is Dictionary:
        card["zone"] = new_zone
