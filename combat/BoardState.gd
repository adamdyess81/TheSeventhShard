extends RefCounted
class_name BoardState

var _active_cards: Array = []
var _board_cap: int = 4


func setup(board_cap: int) -> void:
    _board_cap = board_cap
    _active_cards.clear()


func refill_from_deck(shared_deck: SharedDeckState) -> void:
    while _active_cards.size() < _board_cap and not shared_deck.is_empty():
        var card = shared_deck.draw_card()
        if card != null:
            _set_card_zone(card, "board")
            _active_cards.append(card)


func remove_card_at(index: int):
    if index < 0 or index >= _active_cards.size():
        return null

    var card = _active_cards.pop_at(index)
    return card


func get_active_cards() -> Array:
    return _active_cards


func active_count() -> int:
    return _active_cards.size()


func board_cap() -> int:
    return _board_cap


func can_refill() -> bool:
    return _active_cards.size() <= 1


func _set_card_zone(card, new_zone: String) -> void:
    if card is CardRuntimeState:
        card.set_zone(new_zone)
    elif card is Dictionary:
        card["zone"] = new_zone
