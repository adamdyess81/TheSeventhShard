extends RefCounted
class_name ProfileDeck


static func get_selected_deck_card_counts(profile_data: Dictionary) -> Dictionary:
	var selected = profile_data.get("selected_deck_card_counts", {})
	if selected is Dictionary and not selected.is_empty():
		return _sanitize_counts(selected)

	var fallback = profile_data.get("owned_card_counts", {})
	if fallback is Dictionary:
		return _sanitize_counts(fallback)

	return {}


static func build_deck_entries(deck_counts: Dictionary) -> Array:
	var entries: Array = []
	var card_ids: Array = deck_counts.keys()
	card_ids.sort()

	for card_id in card_ids:
		var quantity := int(deck_counts.get(card_id, 0))
		if quantity <= 0:
			continue
		entries.append({
			"card_id": str(card_id),
			"quantity": quantity
		})

	return entries


static func get_total_cards(deck_counts: Dictionary) -> int:
	var total := 0
	for quantity in deck_counts.values():
		total += int(quantity)
	return total


static func is_valid(deck_counts: Dictionary, min_cards: int, max_cards: int) -> bool:
	var total := get_total_cards(deck_counts)
	return total >= min_cards and total <= max_cards


static func _sanitize_counts(counts: Dictionary) -> Dictionary:
	var sanitized := {}
	for card_id in counts.keys():
		var quantity := int(counts.get(card_id, 0))
		if quantity > 0:
			sanitized[str(card_id)] = quantity
	return sanitized
