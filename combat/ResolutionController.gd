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

    var player_health_before := int(match_state.player_state.current_health)
    match_state.player_state.take_damage(damage)
    var player_damage_taken := maxi(player_health_before - int(match_state.player_state.current_health), 0)

    _apply_monster_unblocked_specials(match_state, card)
    _apply_monster_resolution_if_player_damaged(match_state, card, player_damage_taken)
    _apply_monster_resolved_specials(match_state, card)
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

    if _is_boss_protected_by_ossuary_veil(match_state):
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

    if _is_boss_protected_by_ossuary_veil(match_state):
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


func use_left_hand_spell_on_monster(match_state: MatchCombatState, board_index: int) -> bool:

    if _is_boss_protected_by_ossuary_veil(match_state):
         return false

    var spell = match_state.player_state.left_hand_card
    return _use_spell_on_monster(match_state, board_index, spell, true)


func use_right_hand_spell_on_monster(match_state: MatchCombatState, board_index: int) -> bool:
    var spell = match_state.player_state.right_hand_card
    return _use_spell_on_monster(match_state, board_index, spell, false)


func use_left_hand_spell_on_boss(match_state: MatchCombatState) -> bool:
    var spell = match_state.player_state.left_hand_card
    return _use_spell_on_boss(match_state, spell, true)


func use_right_hand_spell_on_boss(match_state: MatchCombatState) -> bool:

    if _is_boss_protected_by_ossuary_veil(match_state):
        return false

    var spell = match_state.player_state.right_hand_card
    return _use_spell_on_boss(match_state, spell, false)


func use_left_hand_spell_on_player(match_state: MatchCombatState) -> bool:
    var spell = match_state.player_state.left_hand_card
    return _use_spell_on_player(match_state, spell, true)


func use_right_hand_spell_on_player(match_state: MatchCombatState) -> bool:
    var spell = match_state.player_state.right_hand_card
    return _use_spell_on_player(match_state, spell, false)


func _use_weapon_on_monster(match_state: MatchCombatState, board_index: int, weapon, is_left_hand: bool) -> bool:
    var active_cards := match_state.board_state.get_active_cards()

    if board_index < 0 or board_index >= active_cards.size():
        return false

    var monster = active_cards[board_index]

    if _get_card_family(monster) != "monster":
        return false

    var adjacent_monsters := _get_adjacent_monster_refs(active_cards, board_index)
    var attack_value := _get_weapon_attack_value_for_monster_use(match_state, weapon, monster)
    var attack_result := _deal_damage_to_monster(match_state, monster, attack_value, "melee")

    if _has_special_rule(weapon, "sweep"):
        var sweep_damage := _get_special_rule_value(weapon, "sweep", 0)
        for adjacent_monster in adjacent_monsters:
            if sweep_damage <= 0 or adjacent_monster == null:
                continue
            _deal_damage_to_monster(match_state, adjacent_monster, sweep_damage, "melee")

    _finalize_weapon_after_attack(match_state, weapon, is_left_hand, attack_result, false)
    return true


func _use_spell_on_monster(match_state: MatchCombatState, board_index: int, spell, is_left_hand: bool) -> bool:
    if not _can_use_hand_spell(match_state, spell, is_left_hand):
        return false
    if not _spell_targets(spell, "enemy_card"):
        return false

    var active_cards := match_state.board_state.get_active_cards()
    if board_index < 0 or board_index >= active_cards.size():
        return false

    var target = active_cards[board_index]
    if _get_card_family(target) != "monster":
        return false

    var consumed := false

    if _has_special_rule(spell, "fire_damage"):
        var damage := _get_card_runtime_value(spell)
        _deal_damage_to_monster(match_state, target, damage, "spell")
        consumed = true
    elif _has_special_rule(spell, "board_burst"):
        _apply_board_burst_spell(match_state, spell)
        consumed = true
    elif _has_special_rule(spell, "recall"):
        match_state.board_state.remove_card_at(board_index)
        match_state.shared_deck_state.insert_runtime_card_at_random(target)
        consumed = true
    elif _has_special_rule(spell, "banishing_sigil"):
        match_state.shared_deck_state.remove_first_card_by_id(_get_card_id(target))
        consumed = true

    if not consumed:
        return false

    _consume_spell(match_state, spell, is_left_hand)
    return true


func _use_spell_on_boss(match_state: MatchCombatState, spell, is_left_hand: bool) -> bool:

    if _is_boss_protected_by_ossuary_veil(match_state):
        return false

    if not _can_use_hand_spell(match_state, spell, is_left_hand):
        return false
    if not _spell_targets(spell, "boss"):
        return false

    var consumed := false

    if _has_special_rule(spell, "fire_damage"):
        var damage := _get_card_runtime_value(spell)
        var boss_health_before := match_state.boss_state.current_health
        match_state.boss_state.take_damage(damage)
        if boss_health_before > match_state.boss_state.current_health:
            match_state.trigger_boss_retaliation_on_player_attack()
        consumed = true
    elif _has_special_rule(spell, "board_burst"):
        _apply_board_burst_spell(match_state, spell)
        consumed = true

    if not consumed:
        return false

    _consume_spell(match_state, spell, is_left_hand)
    return true


func _use_spell_on_player(match_state: MatchCombatState, spell, is_left_hand: bool) -> bool:
    if not _can_use_hand_spell(match_state, spell, is_left_hand):
        return false
    if not _spell_targets(spell, "player_avatar") and not _spell_targets(spell, "hand_slot"):
        return false

    var consumed := false

    if _has_special_rule(spell, "ward_of_ash"):
        match_state.player_state.add_damage_ward(_get_special_rule_value(spell, "ward_of_ash", _get_card_runtime_value(spell)))
        consumed = true
        _consume_spell(match_state, spell, is_left_hand)
    elif _has_special_rule(spell, "stasis_hex"):
        match_state.board_state.reduce_round_resolve_threshold(_get_card_runtime_value(spell))
        consumed = true
        _consume_spell(match_state, spell, is_left_hand)
    elif _has_special_rule(spell, "battle_focus"):
        consumed = true
        _consume_spell(match_state, spell, is_left_hand, false)
        match_state.player_state.left_hand_exhausted = false
        match_state.player_state.right_hand_exhausted = false
    elif _has_special_rule(spell, "shift_fate"):
        consumed = true
        _consume_spell(match_state, spell, is_left_hand)

    return consumed
 

func _apply_board_burst_spell(match_state: MatchCombatState, spell) -> void:
    var damage := _get_card_runtime_value(spell)
    if damage <= 0:
        return

    var active_cards := match_state.board_state.get_active_cards()
    var targets: Array = []

    for card in active_cards:
        if card != null and _get_card_family(card) == "monster":
            targets.append(card)

    for target in targets:
        _deal_damage_to_monster(match_state, target, damage, "spell")

    if _is_boss_protected_by_ossuary_veil(match_state):
        return

    var boss_health_before := match_state.boss_state.current_health
    match_state.boss_state.take_damage(damage)

    if boss_health_before > match_state.boss_state.current_health:
        match_state.trigger_boss_retaliation_on_player_attack()


func _can_use_hand_spell(match_state: MatchCombatState, spell, is_left_hand: bool) -> bool:
    if spell == null:
        return false
    if match_state.player_state.is_stunned():
        return false
    if _get_card_family(spell) != "spell":
        return false
    if is_left_hand:
        return not match_state.player_state.left_hand_exhausted
    return not match_state.player_state.right_hand_exhausted


func _consume_spell(match_state: MatchCombatState, spell, is_left_hand: bool, should_exhaust_hand: bool = true) -> void:
    _mark_card_resolved(spell)
    _mark_card_exhausted(spell)
    _mark_card_destroyed(spell)

    if is_left_hand:
        match_state.player_state.clear_left_hand_card()
        if should_exhaust_hand:
            match_state.player_state.exhaust_left_hand()
    else:
        match_state.player_state.clear_right_hand_card()
        if should_exhaust_hand:
            match_state.player_state.exhaust_right_hand()


func _spell_targets(spell, target_rule: String) -> bool:
    if spell is CardRuntimeState:
        var target_rules = spell.card_data.get("target_rules", [])
        return target_rules is Array and target_rule in target_rules
    if spell is Dictionary:
        var target_rules = spell.get("target_rules", [])
        return target_rules is Array and target_rule in target_rules
    return false


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
    _apply_monster_resolved_specials(match_state, monster)

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
           var player_health_before := int(match_state.player_state.current_health)
           match_state.player_state.take_damage(overflow_damage)
           var player_damage_taken := maxi(player_health_before - int(match_state.player_state.current_health), 0)

           _apply_monster_resolution_if_player_damaged(match_state, monster, player_damage_taken)

    return true

func _apply_monster_resolution_if_player_damaged(match_state: MatchCombatState, monster, player_damage_taken: int) -> void:
    if player_damage_taken <= 0:
        return

    if not _has_special_rule(monster, "resolution"):
        return

    _resolve_all_player_poison_counters(match_state, monster)


func _resolve_all_player_poison_counters(match_state: MatchCombatState, source_monster) -> void:
    if match_state == null or match_state.player_state == null:
        return

    var poison_amount := _get_player_poison_counter_count(match_state)

    if poison_amount <= 0:
        return

    match_state.player_state.take_damage(poison_amount)
    match_state.player_state.clear_poison()

    match_state.queue_event("player_poison_resolved", {
        "amount": poison_amount,
        "reason": "resolution",
        "source_card_id": _get_card_id(source_monster)
    })


func _get_player_poison_counter_count(match_state: MatchCombatState) -> int:
    if match_state == null or match_state.player_state == null:
        return 0

    var player_state = match_state.player_state

    if player_state.has_method("get_poison_counter_count"):
        return int(player_state.get_poison_counter_count())

    if player_state.has_method("get_poison_counters"):
        return int(player_state.get_poison_counters())

    var poison_counters = player_state.get("poison_counters")
    if poison_counters != null:
        return int(poison_counters)

    var poison_counter_count = player_state.get("poison_counter_count")
    if poison_counter_count != null:
        return int(poison_counter_count)

    return 0

func _use_weapon_on_boss(match_state: MatchCombatState, weapon, is_left_hand: bool) -> bool:

    if _is_boss_protected_by_ossuary_veil(match_state):
        return false

    var weapon_value := _get_weapon_attack_value_for_boss_use(match_state, weapon)
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

func _get_weapon_attack_value_for_boss_use(match_state: MatchCombatState, weapon) -> int:
    if _has_special_rule(weapon, "crushing_blow"):
        var boss_current_health := int(match_state.boss_state.current_health)

        if boss_current_health <= 0:
            return 0

        return maxi(int(ceil(float(boss_current_health) * 0.5)), 1)

    return _get_weapon_attack_value_for_use(weapon)

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
        match_state.player_state.add_shield_bonus(_get_card_runtime_value(potion))
        match_state.refresh_active_buffs_on_cards()
        handled_special = true

    if _has_special_rule(potion, "power"):
        match_state.player_state.add_weapon_bonus(_get_card_runtime_value(potion))
        match_state.refresh_active_buffs_on_cards()
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
    if _has_special_rule(monster, "entangle"):
        match_state.player_state.exhaust_all_loadout_slots()
        match_state.queue_event("player_entangled", {
            "source_card_id": _get_card_id(monster)
        })


func _apply_monster_resolved_specials(match_state: MatchCombatState, monster) -> void:
    if _has_special_rule(monster, "spite"):
        match_state.player_state.take_damage(_get_special_rule_value(monster, "spite", 1))

func _get_weapon_attack_value_for_monster_use(match_state: MatchCombatState, weapon, monster) -> int:
    if _has_special_rule(weapon, "instant_kill"):
        var monster_value := _get_effective_monster_value(match_state, monster)
        var armor_value := _get_special_rule_value(monster, "armored", 0)
        return monster_value + armor_value

    return _get_weapon_attack_value_for_use(weapon)
    
func _get_weapon_attack_value_for_use(weapon) -> int:
    if _has_special_rule(weapon, "split"):
        return 1
    return _get_card_runtime_value(weapon)

func _is_boss_protected_by_ossuary_veil(match_state: MatchCombatState) -> bool:
    if match_state == null:
        return false

    if not _boss_has_special_rule(match_state, "ossuary_veil"):
        return false

    return _get_active_monster_count(match_state) >= 3


func _get_active_monster_count(match_state: MatchCombatState) -> int:
    var count := 0
    var active_cards := match_state.board_state.get_active_cards()

    for card in active_cards:
        if card != null and _get_card_family(card) == "monster":
            count += 1

    return count


func _boss_has_special_rule(match_state: MatchCombatState, special_rule: String) -> bool:
    if match_state == null or match_state.boss_state == null:
        return false

    var boss = match_state.boss_state

    if boss.has_method("has_special_rule"):
        return boss.has_special_rule(special_rule)

    var special_rules = boss.get("special_rules")
    if special_rules is Array:
        return special_rule in special_rules

    var boss_data = boss.get("boss_data")
    if boss_data is Dictionary:
        var boss_special_rules = boss_data.get("special_rules", [])
        return boss_special_rules is Array and special_rule in boss_special_rules

    var card_data = boss.get("card_data")
    if card_data is Dictionary:
        var card_special_rules = card_data.get("special_rules", [])
        return card_special_rules is Array and special_rule in card_special_rules

    return false

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


func _deal_damage_to_monster(match_state: MatchCombatState, monster, damage: int, type) -> Dictionary:
    var result := {
        "killed": false,
        "overflow": 0,
        "damage_dealt": 0
    }
    if monster == null or damage <= 0:
        return result

    var monster_value := _get_effective_monster_value(match_state, monster)
    var armor_value := 0
    if type == "melee":
        armor_value = _get_special_rule_value(monster, "armored", 0)
         
    var total_health := monster_value + armor_value
    var remaining_monster := total_health - damage
    result["damage_dealt"] = mini(damage, total_health)

    if remaining_monster <= 0:
        result["killed"] = true
        result["overflow"] = abs(mini(remaining_monster, 0))
        _apply_monster_resolved_specials(match_state, monster)
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
        if not _get_weapon_second_strike_state(weapon):
            _set_weapon_second_strike_state(weapon, true)
            _clear_weapon_follow_up_state(weapon)
            return
        _clear_weapon_second_strike_state(weapon)

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


func _get_weapon_second_strike_state(weapon) -> bool:
    if weapon is CardRuntimeState:
        return bool(weapon.get_special_state("second_strike_used", false))
    if weapon is Dictionary:
        return bool(weapon.get("second_strike_used", false))
    return false


func _set_weapon_second_strike_state(weapon, is_used: bool) -> void:
    if weapon is CardRuntimeState:
        weapon.set_special_state("second_strike_used", is_used)
    elif weapon is Dictionary:
        weapon["second_strike_used"] = is_used


func _clear_weapon_second_strike_state(weapon) -> void:
    if weapon is CardRuntimeState:
        weapon.special_state.erase("second_strike_used")
    elif weapon is Dictionary:
        weapon.erase("second_strike_used")


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
