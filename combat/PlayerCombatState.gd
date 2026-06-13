extends RefCounted
class_name PlayerCombatState

var max_health: int = 0
var base_max_health: int = 0
var current_health: int = 0
var max_deck_size: int = 0
var temporary_gold: int = 0
var carried_chests: Array = []

var left_hand_card = null
var right_hand_card = null

var backpack_cards: Array = []

var left_hand_exhausted: bool = false
var right_hand_exhausted: bool = false
var backpack_exhausted: bool = false
var stunned_until_round_end: bool = false
var poison_counters: int = 0
var disease_counters: int = 0
var pending_weapon_bonus: int = 0
var active_weapon_bonus: int = 0
var pending_shield_bonus: int = 0
var active_shield_bonus: int = 0
var damage_ward: int = 0

var backpack_capacity: int = 1


func setup(
    starting_health: int,
    starting_backpack_capacity: int = 1,
    starting_max_deck_size: int = 0
) -> void:
    base_max_health = starting_health
    max_health = starting_health
    current_health = starting_health
    max_deck_size = starting_max_deck_size
    temporary_gold = 0
    carried_chests.clear()

    left_hand_card = null
    right_hand_card = null

    backpack_cards.clear()

    left_hand_exhausted = false
    right_hand_exhausted = false
    backpack_exhausted = false
    stunned_until_round_end = false
    poison_counters = 0
    disease_counters = 0
    pending_weapon_bonus = 0
    active_weapon_bonus = 0
    pending_shield_bonus = 0
    active_shield_bonus = 0
    damage_ward = 0

    backpack_capacity = starting_backpack_capacity


func take_damage(amount: int) -> void:
    if amount <= 0:
        return

    if damage_ward > 0:
        var prevented := mini(amount, damage_ward)
        damage_ward -= prevented
        amount -= prevented

    if amount <= 0:
        return

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


func exhaust_backpack() -> void:
    backpack_exhausted = true


func exhaust_all_loadout_slots() -> void:
    left_hand_exhausted = true
    right_hand_exhausted = true
    backpack_exhausted = true


func reset_hand_exhaustion() -> void:
    left_hand_exhausted = false
    right_hand_exhausted = false
    backpack_exhausted = false


func apply_stun() -> void:
    stunned_until_round_end = true


func clear_stun() -> void:
    stunned_until_round_end = false


func is_stunned() -> bool:
    return stunned_until_round_end


func add_poison_counters(amount: int) -> void:
    if amount <= 0:
        return
    poison_counters += amount


func clear_poison() -> void:
    poison_counters = 0


func has_poison() -> bool:
    return poison_counters > 0


func add_disease_counters(amount: int) -> void:
    if amount <= 0:
        return
    disease_counters += amount
    _refresh_max_health_from_disease()


func clear_disease() -> void:
    disease_counters = 0
    _refresh_max_health_from_disease()


func has_disease() -> bool:
    return disease_counters > 0


func has_poison_or_disease() -> bool:
    return has_poison() or has_disease()


func process_end_of_round_poison() -> int:
    if poison_counters <= 0:
        return 0

    poison_counters -= 1
    take_damage(1)
    return 1


func queue_weapon_bonus(amount: int) -> void:
    if amount <= 0:
        return
    pending_weapon_bonus += amount


func queue_shield_bonus(amount: int) -> void:
    if amount <= 0:
        return
    pending_shield_bonus += amount


func add_weapon_bonus(amount: int) -> void:
    if amount <= 0:
        return
    active_weapon_bonus += amount


func add_shield_bonus(amount: int) -> void:
    if amount <= 0:
        return
    active_shield_bonus += amount


func advance_round_buffs() -> void:
    active_weapon_bonus += pending_weapon_bonus
    active_shield_bonus += pending_shield_bonus
    pending_weapon_bonus = 0
    pending_shield_bonus = 0


func add_damage_ward(amount: int) -> void:
    if amount <= 0:
        return

    damage_ward += amount


func boost_max_health(amount: int, heal_added_capacity: bool = true) -> void:
    if amount <= 0:
        return
    base_max_health += amount
    max_health += amount
    if heal_added_capacity:
        current_health = min(current_health + amount, max_health)


func add_to_backpack(card) -> bool:
    if backpack_exhausted:
        return false
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


func _refresh_max_health_from_disease() -> void:
    max_health = maxi(base_max_health - disease_counters, 1)
    current_health = mini(current_health, max_health)


func _set_card_zone(card, new_zone: String) -> void:
    if card is CardRuntimeState:
        card.set_zone(new_zone)
    elif card is Dictionary:
        card["zone"] = new_zone
