extends RefCounted
class_name BoardState

var _active_cards: Array = []
var _board_cap: int = 4


func setup(board_cap: int) -> void:
    _board_cap = board_cap
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
    return active_count() <= 1


func _set_card_zone(card, new_zone: String) -> void:
    if card is CardRuntimeState:
        card.set_zone(new_zone)
    elif card is Dictionary:
        card["zone"] = new_zone
