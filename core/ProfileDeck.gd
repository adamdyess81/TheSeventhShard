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


static func is_valid(
	deck_counts: Dictionary,
	min_cards: int,
	max_cards: int,
	card_registry: Dictionary = {},
	selected_instance_ids: Array = [],
	owned_card_instances: Array = []
) -> bool:
	var total := get_total_cards(deck_counts)
	if total < min_cards or total > max_cards:
		return false

	if has_duplicate_unique_cards(deck_counts, card_registry, selected_instance_ids, owned_card_instances):
		return false

	return true


static func has_duplicate_unique_cards(
	deck_counts: Dictionary,
	card_registry: Dictionary,
	selected_instance_ids: Array = [],
	owned_card_instances: Array = []
) -> bool:
	return not get_duplicate_unique_card_ids(deck_counts, card_registry, selected_instance_ids, owned_card_instances).is_empty()


static func get_duplicate_unique_card_ids(
	deck_counts: Dictionary,
	card_registry: Dictionary,
	selected_instance_ids: Array = [],
	owned_card_instances: Array = []
) -> Array[String]:
	if card_registry.is_empty():
		return []

	var unique_counts := {}
	var duplicate_ids: Array[String] = []

	for raw_card_id in deck_counts.keys():
		var card_id := str(raw_card_id).strip_edges()
		if card_id == "" or not _is_unique_card(card_id, card_registry):
			continue
		unique_counts[card_id] = int(unique_counts.get(card_id, 0)) + int(deck_counts.get(card_id, 0))

	var instance_lookup := {}
	for card_instance in owned_card_instances:
		if not (card_instance is Dictionary):
			continue
		var instance_id := str(card_instance.get("instance_id", "")).strip_edges()
		if instance_id == "":
			continue
		instance_lookup[instance_id] = str(card_instance.get("card_id", "")).strip_edges()

	for raw_instance_id in selected_instance_ids:
		var instance_id := str(raw_instance_id).strip_edges()
		if instance_id == "" or not instance_lookup.has(instance_id):
			continue
		var instance_card_id := str(instance_lookup.get(instance_id, "")).strip_edges()
		if not _is_unique_card(instance_card_id, card_registry):
			continue
		unique_counts[instance_card_id] = int(unique_counts.get(instance_card_id, 0)) + 1

	for raw_card_id in unique_counts.keys():
		var card_id := str(raw_card_id).strip_edges()
		if int(unique_counts.get(card_id, 0)) > 1:
			duplicate_ids.append(card_id)

	duplicate_ids.sort()
	return duplicate_ids


static func _sanitize_counts(counts: Dictionary) -> Dictionary:
	var sanitized := {}
	for card_id in counts.keys():
		var quantity := int(counts.get(card_id, 0))
		if quantity > 0:
			sanitized[str(card_id)] = quantity
	return sanitized


static func _is_unique_card(card_id: String, card_registry: Dictionary) -> bool:
	if card_id == "" or not card_registry.has(card_id):
		return false

	var card_data = card_registry.get(card_id, {})
	if not (card_data is Dictionary):
		return false

	return str(card_data.get("rarity", "")).strip_edges().to_lower() == "unique"
