extends RefCounted
class_name BoardState

var _active_cards: Array = []
var _board_cap: int = 4
var _round_resolve_threshold_reduction: int = 0


func setup(board_cap: int) -> void:
    _board_cap = board_cap
    _round_resolve_threshold_reduction = 0
    _active_cards.clear()
    for _i in range(_board_cap):
        _active_cards.append(null)


func refill_from_deck(shared_deck: SharedDeckState) -> void:
    for i in range(_board_cap):
        if shared_deck.is_empty():
            return

        if _active_cards[i] != null:
            continue

        var card = shared_deck.draw_card()
        if card != null:
            _set_card_zone(card, "board")
            _active_cards[i] = card


func remove_card_at(index: int):
    if index < 0 or index >= _active_cards.size():
        return null

    var card = _active_cards[index]
    _active_cards[index] = null
    return card


func get_active_cards() -> Array:
    return _active_cards


func active_count() -> int:
    var count := 0
    for card in _active_cards:
        if card != null:
            count += 1
    return count


func board_cap() -> int:
    return _board_cap


func can_refill() -> bool:
    return active_count() <= _remaining_cards_needed_for_next_round()


func get_base_resolve_threshold() -> int:
    return maxi(_board_cap - 1, 1)


func get_current_resolve_threshold() -> int:
    return maxi(get_base_resolve_threshold() - _round_resolve_threshold_reduction, 1)


func reduce_round_resolve_threshold(amount: int) -> void:
    if amount <= 0:
        return

    var max_reduction := maxi(get_base_resolve_threshold() - 1, 0)
    _round_resolve_threshold_reduction = mini(_round_resolve_threshold_reduction + amount, max_reduction)


func clear_round_resolve_threshold_modifiers() -> void:
    _round_resolve_threshold_reduction = 0


func _remaining_cards_needed_for_next_round() -> int:
    return maxi(_board_cap - get_current_resolve_threshold(), 0)


func _set_card_zone(card, new_zone: String) -> void:
    if card is CardRuntimeState:
        card.set_zone(new_zone)
    elif card is Dictionary:
        card["zone"] = new_zone
