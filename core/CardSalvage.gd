extends RefCounted
class_name CardSalvage

const RESOURCE_SCRAP := "scrap_materials"
const RESOURCE_ESSENCE := "magic_essence"
const SUPPORTED_FAMILIES := {
	"weapon": true,
	"shield": true,
	"potion": true,
	"spell": true
}


static func ensure_profile_resource_fields(profile_data: Dictionary) -> bool:
	var changed := false
	if not profile_data.has(RESOURCE_SCRAP):
		profile_data[RESOURCE_SCRAP] = 0
		changed = true
	else:
		profile_data[RESOURCE_SCRAP] = int(profile_data.get(RESOURCE_SCRAP, 0))

	if not profile_data.has(RESOURCE_ESSENCE):
		profile_data[RESOURCE_ESSENCE] = 0
		changed = true
	else:
		profile_data[RESOURCE_ESSENCE] = int(profile_data.get(RESOURCE_ESSENCE, 0))

	return changed


static func is_salvageable(card_data: Dictionary) -> bool:
	if card_data.is_empty():
		return false

	var family := str(card_data.get("family", "")).strip_edges().to_lower()
	if not SUPPORTED_FAMILIES.has(family):
		return false

	return bool(card_data.get("can_be_trashed", true))


static func calculate_salvage_rewards(card_data: Dictionary, affix_ids: Array = []) -> Dictionary:
	var base_value := maxi(int(card_data.get("base_value", 0)), 0)
	var family := str(card_data.get("family", "")).strip_edges().to_lower()
	var scrap_materials := 0
	var magic_essence := 0

	match family:
		"weapon", "shield":
			scrap_materials = base_value
		"potion", "spell":
			magic_essence = base_value

	if not affix_ids.is_empty():
		magic_essence += base_value

	return {
		RESOURCE_SCRAP: scrap_materials,
		RESOURCE_ESSENCE: magic_essence,
		"base_value": base_value
	}


static func salvage_card_stack(profile_data: Dictionary, card_data: Dictionary, card_id: String) -> Dictionary:
	ensure_profile_resource_fields(profile_data)

	if card_id == "":
		return {"ok": false, "reason": "missing_card_id"}
	if not is_salvageable(card_data):
		return {"ok": false, "reason": "unsupported_card_family"}

	var owned_card_counts = profile_data.get("owned_card_counts", {})
	if not (owned_card_counts is Dictionary):
		owned_card_counts = {}

	var owned_quantity := int(owned_card_counts.get(card_id, 0))
	if owned_quantity <= 0:
		return {"ok": false, "reason": "missing_owned_card"}

	var rewards := calculate_salvage_rewards(card_data, [])
	_apply_rewards(profile_data, rewards)

	owned_quantity -= 1
	if owned_quantity <= 0:
		owned_card_counts.erase(card_id)
	else:
		owned_card_counts[card_id] = owned_quantity
	profile_data["owned_card_counts"] = owned_card_counts

	var selected_deck_counts = profile_data.get("selected_deck_card_counts", {})
	if not (selected_deck_counts is Dictionary):
		selected_deck_counts = {}

	var removed_from_deck := false
	var selected_quantity := int(selected_deck_counts.get(card_id, 0))
	if selected_quantity > 0:
		removed_from_deck = true
		selected_quantity -= 1
		if selected_quantity <= 0:
			selected_deck_counts.erase(card_id)
		else:
			selected_deck_counts[card_id] = selected_quantity
	profile_data["selected_deck_card_counts"] = selected_deck_counts

	return {
		"ok": true,
		"removed_from_deck": removed_from_deck,
		RESOURCE_SCRAP: int(rewards.get(RESOURCE_SCRAP, 0)),
		RESOURCE_ESSENCE: int(rewards.get(RESOURCE_ESSENCE, 0))
	}


static func salvage_card_instance(profile_data: Dictionary, card_data: Dictionary, instance_id: String, affix_ids: Array = []) -> Dictionary:
	ensure_profile_resource_fields(profile_data)

	if instance_id == "":
		return {"ok": false, "reason": "missing_instance_id"}
	if not is_salvageable(card_data):
		return {"ok": false, "reason": "unsupported_card_family"}

	var owned_card_instances = profile_data.get("owned_card_instances", [])
	if not (owned_card_instances is Array):
		owned_card_instances = []

	var removed_index := -1
	for index in range(owned_card_instances.size()):
		var entry = owned_card_instances[index]
		if entry is Dictionary and str(entry.get("instance_id", "")).strip_edges() == instance_id:
			removed_index = index
			break

	if removed_index < 0:
		return {"ok": false, "reason": "missing_owned_instance"}

	owned_card_instances.remove_at(removed_index)
	profile_data["owned_card_instances"] = owned_card_instances

	var selected_instance_ids = profile_data.get("selected_deck_card_instance_ids", [])
	if not (selected_instance_ids is Array):
		selected_instance_ids = []

	var removed_from_deck: bool = selected_instance_ids.has(instance_id)
	selected_instance_ids.erase(instance_id)
	profile_data["selected_deck_card_instance_ids"] = selected_instance_ids

	var rewards := calculate_salvage_rewards(card_data, affix_ids)
	_apply_rewards(profile_data, rewards)

	return {
		"ok": true,
		"removed_from_deck": removed_from_deck,
		RESOURCE_SCRAP: int(rewards.get(RESOURCE_SCRAP, 0)),
		RESOURCE_ESSENCE: int(rewards.get(RESOURCE_ESSENCE, 0))
	}


static func _apply_rewards(profile_data: Dictionary, rewards: Dictionary) -> void:
	profile_data[RESOURCE_SCRAP] = int(profile_data.get(RESOURCE_SCRAP, 0)) + int(rewards.get(RESOURCE_SCRAP, 0))
	profile_data[RESOURCE_ESSENCE] = int(profile_data.get(RESOURCE_ESSENCE, 0)) + int(rewards.get(RESOURCE_ESSENCE, 0))
