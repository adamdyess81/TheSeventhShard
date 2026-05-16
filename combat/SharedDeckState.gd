extends RefCounted
class_name SharedDeckState

var _cards: Array = []
var _instance_counter: int = 0


func setup(cards: Array) -> void:
    _cards.clear()
    _instance_counter = 0

    for card in cards:
        var runtime_card := _build_runtime_card(card)
        _cards.append(runtime_card)


func draw_card():
    if _cards.is_empty():
        return null

    return _cards.pop_front()


func draw_multiple(count: int) -> Array:
    var drawn: Array = []

    for i in range(count):
        if _cards.is_empty():
            break
        drawn.append(draw_card())

    return drawn


func peek(count: int) -> Array:
    var result: Array = []

    for i in range(min(count, _cards.size())):
        result.append(_cards[i])

    return result


func remaining_count() -> int:
    return _cards.size()


func is_empty() -> bool:
    return _cards.is_empty()


func _build_runtime_card(card_data: Dictionary) -> CardRuntimeState:
    _instance_counter += 1

    var runtime_card := CardRuntimeState.new()
    runtime_card.setup(
        "card_%d" % _instance_counter,
        card_data,
        _infer_owner_source(card_data),
        "deck",
        -1
    )

    return runtime_card


func _infer_owner_source(card_data: Dictionary) -> String:
    var family := str(card_data.get("family", ""))

    if family == "monster" or family == "coin" or family == "chest":
        return "monster_deck"

    return "player_deck"
