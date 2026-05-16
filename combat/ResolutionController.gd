extends RefCounted
class_name ResolutionController

func resolve_enemy_to_player(match_state: MatchCombatState, board_index: int) -> bool:
    var active_cards := match_state.board_state.get_active_cards()

    if board_index < 0 or board_index >= active_cards.size():
        return false

    var card = active_cards[board_index]

    if _get_card_family(card) != "monster":
        return false

    var damage := _get_card_runtime_value(card)
    match_state.player_state.take_damage(damage)
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

    if match_state.player_state.left_hand_exhausted:
        return false

    if match_state.player_state.left_hand_card != null:
        return false

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

    if match_state.player_state.right_hand_exhausted:
        return false

    if match_state.player_state.right_hand_card != null:
        return false

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

    if _get_card_family(weapon) != "weapon":
        return false

    return _use_weapon_on_monster(match_state, board_index, weapon, true)


func use_right_hand_weapon_on_monster(match_state: MatchCombatState, board_index: int) -> bool:
    var weapon = match_state.player_state.right_hand_card
    if weapon == null:
        return false

    if _get_card_family(weapon) != "weapon":
        return false

    return _use_weapon_on_monster(match_state, board_index, weapon, false)


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

    if _get_card_family(potion) != "potion":
        return false

    if match_state.player_state.left_hand_exhausted:
        return false

    var heal_amount := _get_card_runtime_value(potion)
    match_state.player_state.heal(heal_amount)
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

    if _get_card_family(potion) != "potion":
        return false

    if match_state.player_state.right_hand_exhausted:
        return false

    var heal_amount := _get_card_runtime_value(potion)
    match_state.player_state.heal(heal_amount)
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

    var weapon_value := _get_card_runtime_value(weapon)
    var monster_value := _get_card_runtime_value(monster)

    if weapon_value < monster_value:
        return false

    _mark_card_resolved(monster)
    match_state.board_state.remove_card_at(board_index)

    _mark_card_exhausted(weapon)
    _mark_card_destroyed(weapon)

    if is_left_hand:
        match_state.player_state.clear_left_hand_card()
        match_state.player_state.exhaust_left_hand()
    else:
        match_state.player_state.clear_right_hand_card()
        match_state.player_state.exhaust_right_hand()

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
    var monster_value := _get_card_runtime_value(monster)

    _mark_card_resolved(monster)
    match_state.board_state.remove_card_at(board_index)

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


func _get_card_id(card) -> String:
    if card is CardRuntimeState:
        return card.card_id

    if card is Dictionary:
        return str(card.get("id", ""))

    return ""


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
