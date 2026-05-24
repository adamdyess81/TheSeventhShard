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


func reorder_with_selected_top(selected_cards: Array) -> int:
    var selected_runtime_cards: Array = []

    for candidate in selected_cards:
        if not (candidate is CardRuntimeState):
            continue
        if candidate not in _cards:
            continue
        if candidate in selected_runtime_cards:
            continue
        selected_runtime_cards.append(candidate)

    var remaining_cards: Array = []
    for card in _cards:
        if card in selected_runtime_cards:
            continue
        remaining_cards.append(card)

    remaining_cards.shuffle()

    _cards = []
    for card in selected_runtime_cards:
        card.set_zone("deck")
        _cards.append(card)
    for card in remaining_cards:
        if card is CardRuntimeState:
            card.set_zone("deck")
        _cards.append(card)

    return selected_runtime_cards.size()


func remaining_count() -> int:
    return _cards.size()


func is_empty() -> bool:
    return _cards.is_empty()


func insert_card_at_random(card_data: Dictionary) -> CardRuntimeState:
    var runtime_card := _build_runtime_card(card_data)
    runtime_card.set_zone("deck")
    var insert_index := 0

    if _cards.size() > 0:
        insert_index = randi_range(0, _cards.size())

    _cards.insert(insert_index, runtime_card)
    return runtime_card


func insert_runtime_card_at_random(card) -> bool:
    if card == null:
        return false

    if card is CardRuntimeState:
        card.set_zone("deck")
        var insert_index := 0
        if _cards.size() > 0:
            insert_index = randi_range(0, _cards.size())
        _cards.insert(insert_index, card)
        return true

    if card is Dictionary:
        insert_card_at_random(card)
        return true

    return false


func remove_first_card_by_id(card_id: String):
    var normalized_id := card_id.strip_edges()
    if normalized_id == "":
        return null

    for i in range(_cards.size()):
        var card = _cards[i]
        if not (card is CardRuntimeState):
            continue
        if card.card_id != normalized_id:
            continue
        return _cards.pop_at(i)

    return null


func advance_round_specials() -> void:
    for i in range(1, _cards.size()):
        var card = _cards[i]
        if not (card is CardRuntimeState):
            continue
        if not _has_special_rule(card, "rush"):
            continue

        var rush_amount = _get_special_rule_value(card, "rush", 1)
        var target_index = i - rush_amount
        if target_index < 0:
            target_index = 0
        if target_index == i:
            continue

        _cards.remove_at(i)
        _cards.insert(target_index, card)


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


func _has_special_rule(card: CardRuntimeState, special_rule: String) -> bool:
    var special_rules = card.card_data.get("special_rules", [])
    if special_rules is Array:
        return special_rule in special_rules
    return false


func _get_special_rule_value(card: CardRuntimeState, special_rule: String, default_value: int = 0) -> int:
    var special_values = card.card_data.get("special_values", {})
    if special_values is Dictionary and special_values.has(special_rule):
        return int(special_values.get(special_rule, default_value))
    return default_value
