extends RefCounted
class_name ResolutionController

func resolve_enemy_to_player(match_state: MatchCombatState, board_index: int) -> bool:
    var active_cards := match_state.board_state.get_active_cards()

    if board_index < 0 or board_index >= active_cards.size():
        return false

    var card = active_cards[board_index]

    if _get_card_family(card) != "monster":
        return false

    var damage := _get_effective_monster_value(match_state, card)
    match_state.player_state.take_damage(damage)
    _apply_monster_unblocked_specials(match_state, card)
    _mark_card_resolved(card)
    match_state.board_state.remove_card_at(board_index)

    return true


func resolve_gold_to_temporary_gold(match_state: MatchCombatState, board_index: int) -> bool:
    var active_cards := match_state.board_state.get_active_cards()

    if board_index < 0 or board_index >= active_cards.size():
        return false

    var card = active_cards[board_index]

    if _get_card_family(card) != "coin":
        return false

    var gold_amount := _get_card_runtime_value(card)
    match_state.player_state.add_temporary_gold(gold_amount)
    _mark_card_resolved(card)
    match_state.board_state.remove_card_at(board_index)

    return true


func move_player_card_to_left_hand(match_state: MatchCombatState, board_index: int) -> bool:
    var active_cards := match_state.board_state.get_active_cards()

    if board_index < 0 or board_index >= active_cards.size():
        return false

    var card = active_cards[board_index]

    if not _is_player_usable_card(card):
        return false

    if match_state.player_state.is_stunned():
        return false

    if match_state.player_state.left_hand_exhausted:
        return false

    if match_state.player_state.left_hand_card != null:
        return false

    var family := _get_card_family(card)

    if family == "coin":
        var gold_amount := _get_card_runtime_value(card)
        match_state.player_state.add_temporary_gold(gold_amount)
        _mark_card_resolved(card)
        _mark_card_exhausted(card)
        _mark_card_destroyed(card)
        match_state.player_state.exhaust_left_hand()
        match_state.board_state.remove_card_at(board_index)
        return true

    if family == "potion":
        _apply_potion_to_player(match_state, card)
        _mark_card_resolved(card)
        _mark_card_exhausted(card)
        _mark_card_destroyed(card)
        match_state.player_state.exhaust_left_hand()
        match_state.board_state.remove_card_at(board_index)
        return true

    if not match_state.player_state.set_left_hand_card(card):
        return false

    match_state.board_state.remove_card_at(board_index)
    return true



func move_player_card_to_right_hand(match_state: MatchCombatState, board_index: int) -> bool:
    var active_cards := match_state.board_state.get_active_cards()

    if board_index < 0 or board_index >= active_cards.size():
        return false

    var card = active_cards[board_index]

    if not _is_player_usable_card(card):
        return false

    if match_state.player_state.is_stunned():
        return false

    if match_state.player_state.right_hand_exhausted:
        return false

    if match_state.player_state.right_hand_card != null:
        return false

    var family := _get_card_family(card)

    if family == "coin":
        var gold_amount := _get_card_runtime_value(card)
        match_state.player_state.add_temporary_gold(gold_amount)
        _mark_card_resolved(card)
        _mark_card_exhausted(card)
        _mark_card_destroyed(card)
        match_state.player_state.exhaust_right_hand()
        match_state.board_state.remove_card_at(board_index)
        return true

    if family == "potion":
        _apply_potion_to_player(match_state, card)
        _mark_card_resolved(card)
        _mark_card_exhausted(card)
        _mark_card_destroyed(card)
        match_state.player_state.exhaust_right_hand()
        match_state.board_state.remove_card_at(board_index)
        return true

    if not match_state.player_state.set_right_hand_card(card):
        return false

    match_state.board_state.remove_card_at(board_index)
    return true




func move_player_card_to_backpack(match_state: MatchCombatState, board_index: int) -> bool:
    var active_cards := match_state.board_state.get_active_cards()

    if board_index < 0 or board_index >= active_cards.size():
        return false

    var card = active_cards[board_index]

    if not _is_player_usable_card(card):
        return false

    if match_state.player_state.is_stunned():
        return false

    if not match_state.player_state.add_to_backpack(card):
        return false

    match_state.board_state.remove_card_at(board_index)
    return true


func trash_player_card_from_board(match_state: MatchCombatState, board_index: int) -> bool:
    var active_cards := match_state.board_state.get_active_cards()

    if board_index < 0 or board_index >= active_cards.size():
        return false

    var card = active_cards[board_index]

    if not _is_player_usable_card(card):
        return false

    _mark_card_resolved(card)
    _mark_card_destroyed(card)
    match_state.board_state.remove_card_at(board_index)
    return true


func use_left_hand_weapon_on_monster(match_state: MatchCombatState, board_index: int) -> bool:
    var weapon = match_state.player_state.left_hand_card
    if weapon == null:
        return false
    if match_state.player_state.is_stunned():
        return false

    if _get_card_family(weapon) != "weapon":
        return false

    return _use_weapon_on_monster(match_state, board_index, weapon, true)


func use_right_hand_weapon_on_monster(match_state: MatchCombatState, board_index: int) -> bool:
    var weapon = match_state.player_state.right_hand_card
    if weapon == null:
        return false
    if match_state.player_state.is_stunned():
        return false

    if _get_card_family(weapon) != "weapon":
        return false

    return _use_weapon_on_monster(match_state, board_index, weapon, false)


func use_left_hand_weapon_on_boss(match_state: MatchCombatState) -> bool:
    var weapon = match_state.player_state.left_hand_card
    if weapon == null:
        return false
    if match_state.player_state.is_stunned():
        return false

    if _get_card_family(weapon) != "weapon":
        return false

    if match_state.player_state.left_hand_exhausted:
        return false

    return _use_weapon_on_boss(match_state, weapon, true)


func use_right_hand_weapon_on_boss(match_state: MatchCombatState) -> bool:
    var weapon = match_state.player_state.right_hand_card
    if weapon == null:
        return false
    if match_state.player_state.is_stunned():
        return false

    if _get_card_family(weapon) != "weapon":
        return false

    if match_state.player_state.right_hand_exhausted:
        return false

    return _use_weapon_on_boss(match_state, weapon, false)


func resolve_monster_into_left_hand_shield(match_state: MatchCombatState, board_index: int) -> bool:
    var shield = match_state.player_state.left_hand_card
    if shield == null:
        return false

    if _get_card_family(shield) != "shield":
        return false

    return _resolve_monster_into_shield(match_state, board_index, true)


func resolve_monster_into_right_hand_shield(match_state: MatchCombatState, board_index: int) -> bool:
    var shield = match_state.player_state.right_hand_card
    if shield == null:
        return false

    if _get_card_family(shield) != "shield":
        return false

    return _resolve_monster_into_shield(match_state, board_index, false)


func use_left_hand_potion(match_state: MatchCombatState) -> bool:
    var potion = match_state.player_state.left_hand_card
    if potion == null:
        return false
    if match_state.player_state.is_stunned():
        return false

    if _get_card_family(potion) != "potion":
        return false

    if match_state.player_state.left_hand_exhausted:
        return false

    _apply_potion_to_player(match_state, potion)
    _mark_card_resolved(potion)
    _mark_card_exhausted(potion)
    _mark_card_destroyed(potion)
    match_state.player_state.clear_left_hand_card()
    match_state.player_state.exhaust_left_hand()

    return true


func use_right_hand_potion(match_state: MatchCombatState) -> bool:
    var potion = match_state.player_state.right_hand_card
    if potion == null:
        return false
    if match_state.player_state.is_stunned():
        return false

    if _get_card_family(potion) != "potion":
        return false

    if match_state.player_state.right_hand_exhausted:
        return false

    _apply_potion_to_player(match_state, potion)
    _mark_card_resolved(potion)
    _mark_card_exhausted(potion)
    _mark_card_destroyed(potion)
    match_state.player_state.clear_right_hand_card()
    match_state.player_state.exhaust_right_hand()

    return true


func _use_weapon_on_monster(match_state: MatchCombatState, board_index: int, weapon, is_left_hand: bool) -> bool:
    var active_cards := match_state.board_state.get_active_cards()

    if board_index < 0 or board_index >= active_cards.size():
        return false

    var monster = active_cards[board_index]

    if _get_card_family(monster) != "monster":
        return false

    var adjacent_monsters := _get_adjacent_monster_refs(active_cards, board_index)
    var attack_value := _get_weapon_attack_value_for_use(weapon)
    var attack_result := _deal_damage_to_monster(match_state, monster, attack_value)

    if _has_special_rule(weapon, "sweep"):
        var sweep_damage := _get_special_rule_value(weapon, "sweep", 0)
        for adjacent_monster in adjacent_monsters:
            if sweep_damage <= 0 or adjacent_monster == null:
                continue
            _deal_damage_to_monster(match_state, adjacent_monster, sweep_damage)

    _finalize_weapon_after_attack(match_state, weapon, is_left_hand, attack_result, false)
    return true


func _resolve_monster_into_shield(match_state: MatchCombatState, board_index: int, is_left_hand: bool) -> bool:
    var active_cards := match_state.board_state.get_active_cards()

    if board_index < 0 or board_index >= active_cards.size():
        return false

    var monster = active_cards[board_index]

    if _get_card_family(monster) != "monster":
        return false

    var shield
    if is_left_hand:
        shield = match_state.player_state.left_hand_card
    else:
        shield = match_state.player_state.right_hand_card

    var shield_value := _get_card_runtime_value(shield)
    var monster_value := _get_effective_monster_value(match_state, monster, true)
    if _has_special_rule(shield, "thorns"):
        monster_value = maxi(monster_value - _get_special_rule_value(shield, "thorns", 1), 0)

    _mark_card_resolved(monster)
    match_state.board_state.remove_card_at(board_index)
    _apply_monster_blocked_specials(match_state, monster)

    var remaining_shield := shield_value - monster_value

    if remaining_shield > 0:
        _set_card_runtime_value(shield, remaining_shield)

        if is_left_hand:
            match_state.player_state.left_hand_card = shield
        else:
            match_state.player_state.right_hand_card = shield
    else:
        var overflow_damage: int = int(abs(min(remaining_shield, 0)))

        _mark_card_destroyed(shield)
        _mark_card_exhausted(shield)

        if is_left_hand:
            match_state.player_state.clear_left_hand_card()
            match_state.player_state.exhaust_left_hand()
        else:
            match_state.player_state.clear_right_hand_card()
            match_state.player_state.exhaust_right_hand()

        if overflow_damage > 0:
            match_state.player_state.take_damage(overflow_damage)

    return true


func _use_weapon_on_boss(match_state: MatchCombatState, weapon, is_left_hand: bool) -> bool:
    var weapon_value := _get_weapon_attack_value_for_use(weapon)
    var boss_health_before := match_state.boss_state.current_health
    match_state.boss_state.take_damage(weapon_value)
    var boss_damage_dealt: int = maxi(boss_health_before - match_state.boss_state.current_health, 0)
    if boss_damage_dealt > 0:
        match_state.trigger_boss_retaliation_on_player_attack()
    var boss_result := {
        "killed": match_state.boss_state.is_defeated(),
        "overflow": maxi(weapon_value - boss_damage_dealt, 0),
        "damage_dealt": boss_damage_dealt
    }
    _finalize_weapon_after_attack(match_state, weapon, is_left_hand, boss_result, true)
    return true


func _get_card_id(card) -> String:
    if card is CardRuntimeState:
        return card.card_id

    if card is Dictionary:
        return str(card.get("id", ""))

    return ""


func _apply_potion_to_player(match_state: MatchCombatState, potion) -> void:
    var handled_special := false

    if _has_special_rule(potion, "adrenaline"):
        match_state.player_state.boost_max_health(_get_special_rule_value(potion, "adrenaline", 1))
        handled_special = true

    if _has_special_rule(potion, "defense"):
        match_state.player_state.queue_shield_bonus(_get_special_rule_value(potion, "defense", 1))
        handled_special = true

    if _has_special_rule(potion, "power"):
        match_state.player_state.queue_weapon_bonus(_get_special_rule_value(potion, "power", 1))
        handled_special = true

    if not handled_special:
        var heal_amount := _get_card_runtime_value(potion)
        if heal_amount > 0:
            match_state.player_state.heal(heal_amount)

    if _has_special_rule(potion, "cure"):
        match_state.player_state.clear_poison()
        match_state.player_state.clear_disease()


func _get_effective_monster_value(match_state: MatchCombatState, monster, blocked_by_shield: bool = false) -> int:
    var value := _get_card_runtime_value(monster)

    if match_state != null and match_state.player_state != null and _has_special_rule(monster, "predation"):
        if match_state.player_state.has_poison_or_disease():
            value += _get_special_rule_value(monster, "predation", 1)

    if blocked_by_shield and _has_special_rule(monster, "corrosion"):
        value *= 2

    return maxi(value, 0)


func _apply_monster_unblocked_specials(match_state: MatchCombatState, monster) -> void:
    if _has_special_rule(monster, "stun"):
        match_state.player_state.apply_stun()

    if _has_special_rule(monster, "agony"):
        var agony_heal := _get_special_rule_value(monster, "agony", 1)
        match_state.boss_state.heal(agony_heal)
        match_state.queue_event("boss_heal", {
            "amount": agony_heal,
            "reason": "agony",
            "source_card_id": _get_card_id(monster)
        })

    if _has_special_rule(monster, "spite"):
        match_state.player_state.take_damage(_get_special_rule_value(monster, "spite", 1))

    if _has_special_rule(monster, "poison"):
        var poison_amount := _get_special_rule_value(monster, "poison", 1)
        match_state.player_state.add_poison_counters(poison_amount)
        match_state.queue_event("player_poisoned", {
            "amount": poison_amount,
            "source_card_id": _get_card_id(monster)
        })

    if _has_special_rule(monster, "disease"):
        var disease_amount := _get_special_rule_value(monster, "disease", 1)
        match_state.player_state.add_disease_counters(disease_amount)
        match_state.queue_event("player_diseased", {
            "amount": disease_amount,
            "source_card_id": _get_card_id(monster)
        })


func _apply_monster_blocked_specials(match_state: MatchCombatState, monster) -> void:
    if _has_special_rule(monster, "spite"):
        match_state.player_state.take_damage(_get_special_rule_value(monster, "spite", 1))

    if _has_special_rule(monster, "entangle"):
        match_state.player_state.exhaust_all_loadout_slots()
        match_state.queue_event("player_entangled", {
            "source_card_id": _get_card_id(monster)
        })


func _get_weapon_attack_value_for_use(weapon) -> int:
    if _has_special_rule(weapon, "split"):
        return 1
    return _get_card_runtime_value(weapon)


func _get_adjacent_monster_refs(active_cards: Array, board_index: int) -> Array:
    var adjacent: Array = []
    var left_index := board_index - 1
    var right_index := board_index + 1

    if left_index >= 0 and left_index < active_cards.size():
        var left_card = active_cards[left_index]
        if left_card != null and _get_card_family(left_card) == "monster":
            adjacent.append(left_card)

    if right_index >= 0 and right_index < active_cards.size():
        var right_card = active_cards[right_index]
        if right_card != null and _get_card_family(right_card) == "monster":
            adjacent.append(right_card)

    return adjacent


func _deal_damage_to_monster(match_state: MatchCombatState, monster, damage: int) -> Dictionary:
    var result := {
        "killed": false,
        "overflow": 0,
        "damage_dealt": 0
    }
    if monster == null or damage <= 0:
        return result

    var monster_value := _get_effective_monster_value(match_state, monster)
    var armor_value := _get_special_rule_value(monster, "armored", 0)
    var total_health := monster_value + armor_value
    var remaining_monster := total_health - damage
    result["damage_dealt"] = mini(damage, total_health)

    if remaining_monster <= 0:
        result["killed"] = true
        result["overflow"] = abs(mini(remaining_monster, 0))
        _mark_card_resolved(monster)
        _remove_board_card_reference(match_state, monster)
        match_state.trigger_boss_on_player_monster_kill(monster)
        if _has_special_rule(monster, "martyrdom"):
            match_state.trigger_boss_special("martyrdom", monster)
    else:
        _set_card_runtime_value(monster, remaining_monster)

    return result


func _remove_board_card_reference(match_state: MatchCombatState, target_card) -> void:
    var active_cards := match_state.board_state.get_active_cards()
    for i in range(active_cards.size()):
        if active_cards[i] == target_card:
            match_state.board_state.remove_card_at(i)
            return


func _finalize_weapon_after_attack(
    match_state: MatchCombatState,
    weapon,
    is_left_hand: bool,
    attack_result: Dictionary,
    attacked_boss: bool
) -> void:
    if _has_special_rule(weapon, "second_strike"):
        _clear_weapon_follow_up_state(weapon)
        return

    if _has_special_rule(weapon, "split"):
        var remaining_points := maxi(_get_card_runtime_value(weapon) - 1, 0)
        if remaining_points > 0:
            _set_card_runtime_value(weapon, remaining_points)
            _clear_weapon_follow_up_state(weapon)
            return

    var followup_pending := _get_weapon_follow_up_state(weapon)
    if _has_special_rule(weapon, "pierce") and not followup_pending:
        var overflow := int(attack_result.get("overflow", 0))
        if overflow > 0 and (not attacked_boss or not match_state.boss_state.is_defeated()):
            _set_card_runtime_value(weapon, overflow)
            _set_weapon_follow_up_state(weapon, true)
            return

    _clear_weapon_follow_up_state(weapon)
    _consume_weapon(match_state, weapon, is_left_hand)


func _consume_weapon(match_state: MatchCombatState, weapon, is_left_hand: bool) -> void:
    _mark_card_exhausted(weapon)
    _mark_card_destroyed(weapon)

    if is_left_hand:
        match_state.player_state.clear_left_hand_card()
        match_state.player_state.exhaust_left_hand()
    else:
        match_state.player_state.clear_right_hand_card()
        match_state.player_state.exhaust_right_hand()


func _get_weapon_follow_up_state(weapon) -> bool:
    if weapon is CardRuntimeState:
        return bool(weapon.get_special_state("pierce_follow_up_pending", false))
    if weapon is Dictionary:
        return bool(weapon.get("pierce_follow_up_pending", false))
    return false


func _set_weapon_follow_up_state(weapon, is_pending: bool) -> void:
    if weapon is CardRuntimeState:
        weapon.set_special_state("pierce_follow_up_pending", is_pending)
    elif weapon is Dictionary:
        weapon["pierce_follow_up_pending"] = is_pending


func _clear_weapon_follow_up_state(weapon) -> void:
    if weapon is CardRuntimeState:
        weapon.special_state.erase("pierce_follow_up_pending")
    elif weapon is Dictionary:
        weapon.erase("pierce_follow_up_pending")


func _get_card_family(card) -> String:
    if card is CardRuntimeState:
        return card.get_family()

    if card is Dictionary:
        return str(card.get("family", ""))

    return ""


func _get_card_runtime_value(card) -> int:
    if card is CardRuntimeState:
        return card.current_value

    if card is Dictionary:
        if card.has("current_value"):
            return int(card.get("current_value", 0))
        return int(card.get("base_value", 0))

    return 0


func _set_card_runtime_value(card, value: int) -> void:
    if card is CardRuntimeState:
        card.current_value = value
        return

    if card is Dictionary:
        card["current_value"] = value


func _has_special_rule(card, special_rule: String) -> bool:
    if card is CardRuntimeState:
        var special_rules = card.card_data.get("special_rules", [])
        if special_rules is Array:
            return special_rule in special_rules
        return false

    if card is Dictionary:
        var special_rules = card.get("special_rules", [])
        if special_rules is Array:
            return special_rule in special_rules
        return false

    return false


func _get_special_rule_value(card, special_rule: String, default_value: int = 0) -> int:
    if not _has_special_rule(card, special_rule):
        return default_value

    if card is CardRuntimeState:
        var special_values = card.card_data.get("special_values", {})
        if special_values is Dictionary and special_values.has(special_rule):
            return int(special_values.get(special_rule, default_value))
        return default_value

    if card is Dictionary:
        var special_values = card.get("special_values", {})
        if special_values is Dictionary and special_values.has(special_rule):
            return int(special_values.get(special_rule, default_value))
        return default_value

    return default_value


func _mark_card_resolved(card) -> void:
    if card is CardRuntimeState:
        card.mark_resolved()
    elif card is Dictionary:
        card["is_resolved"] = true


func _mark_card_exhausted(card) -> void:
    if card is CardRuntimeState:
        card.mark_exhausted()
    elif card is Dictionary:
        card["is_exhausted"] = true


func _mark_card_destroyed(card) -> void:
    if card is CardRuntimeState:
        card.mark_destroyed()
    elif card is Dictionary:
        card["is_destroyed"] = true


func _is_player_usable_card(card) -> bool:
    var family := _get_card_family(card)
    return family in ["weapon", "shield", "potion", "spell", "artifact", "coin", "chest"]
