extends RefCounted
class_name CardAffixLibrary

const AFFIX_DATA_PATH := "res://data/cards/Specials/affixes.json"
const GAME_DATA_LOADER_SCRIPT = preload("res://core/GameDataLoader.gd")

static var _affix_registry: Dictionary = {}


static func get_affix_registry() -> Dictionary:
	if _affix_registry.is_empty():
		var loader = GAME_DATA_LOADER_SCRIPT.new()
		_affix_registry = loader.load_json(AFFIX_DATA_PATH)

	return _affix_registry


static func get_affix_data(affix_id: String) -> Dictionary:
	var normalized_affix_id := affix_id.strip_edges()
	if normalized_affix_id == "":
		return {}

	var registry := get_affix_registry()
	var affix_data = registry.get(normalized_affix_id, {})
	if affix_data is Dictionary:
		return affix_data.duplicate(true)

	return {}


static func can_apply_to_family(affix_data: Dictionary, card_family: String) -> bool:
	var normalized_family := card_family.strip_edges().to_lower()
	var families = affix_data.get("families", [])
	if not (families is Array) or families.is_empty():
		return true

	for family in families:
		if str(family).strip_edges().to_lower() == normalized_family:
			return true

	return false


static func get_roll_candidates_for_family(card_family: String) -> Array[Dictionary]:
	var registry := get_affix_registry()
	var candidates: Array[Dictionary] = []

	for affix_id in registry.keys():
		var affix_data = registry.get(affix_id, {})
		if not (affix_data is Dictionary):
			continue

		var affix_entry: Dictionary = affix_data
		var weight := maxi(int(affix_entry.get("weight", 0)), 0)
		if weight <= 0:
			continue

		if not can_apply_to_family(affix_entry, card_family):
			continue

		candidates.append(affix_entry.duplicate(true))

	return candidates


static func roll_affix_id_for_family(card_family: String) -> String:
	var candidates := get_roll_candidates_for_family(card_family)
	if candidates.is_empty():
		return ""

	var total_weight := 0
	for candidate in candidates:
		total_weight += maxi(int(candidate.get("weight", 0)), 0)

	if total_weight <= 0:
		return ""

	var selection := randi() % total_weight
	var running_weight := 0
	for candidate in candidates:
		running_weight += maxi(int(candidate.get("weight", 0)), 0)
		if selection < running_weight:
			return str(candidate.get("id", "")).strip_edges()

	return str(candidates[candidates.size() - 1].get("id", "")).strip_edges()


static func build_affixed_name(base_name: String, affix_ids: Array) -> String:
	var current_name := base_name

	for raw_affix_id in affix_ids:
		var affix_id := str(raw_affix_id).strip_edges()
		if affix_id == "":
			continue

		var affix_data := get_affix_data(affix_id)
		if affix_data.is_empty():
			continue

		var display_name := str(affix_data.get("display_name", affix_id)).strip_edges()
		if display_name == "":
			continue

		var name_position := str(affix_data.get("name_position", "prefix")).strip_edges().to_lower()
		if name_position == "suffix":
			current_name = current_name + " " + display_name
		else:
			current_name = display_name + " " + current_name

	return current_name


static func build_affix_description_lines(affix_ids: Array) -> Array[String]:
	var lines: Array[String] = []

	for raw_affix_id in affix_ids:
		var affix_id := str(raw_affix_id).strip_edges()
		if affix_id == "":
			continue

		var affix_data := get_affix_data(affix_id)
		if affix_data.is_empty():
			continue

		var display_name := str(affix_data.get("display_name", affix_id)).strip_edges()
		var description := str(affix_data.get("description", "")).strip_edges()
		if display_name == "" and description == "":
			continue

		if display_name == "":
			lines.append(description)
		elif description == "":
			lines.append(display_name)
		else:
			lines.append("%s: %s" % [display_name, description])

	return lines


static func has_foil_affix(affix_ids: Array) -> bool:
	for raw_affix_id in affix_ids:
		var affix_id := str(raw_affix_id).strip_edges()
		if affix_id == "":
			continue

		var affix_data := get_affix_data(affix_id)
		if affix_data.is_empty():
			continue

		if bool(affix_data.get("foil", false)):
			return true

	return false


static func apply_affix_gameplay_effects(card_data: Dictionary, affix_ids: Array) -> void:
	for raw_affix_id in affix_ids:
		var affix_id := str(raw_affix_id).strip_edges()
		if affix_id == "":
			continue

		var affix_data := get_affix_data(affix_id)
		if affix_data.is_empty():
			continue

		var effect := str(affix_data.get("effect", "")).strip_edges()
		if effect == "":
			continue

		var effect_amount := int(affix_data.get("effect_amount", 1))
		match effect.to_lower():
			"increase_card_value":
				var current_base_value := int(card_data.get("base_value", 0))
				card_data["base_value"] = current_base_value + effect_amount
				if card_data.has("current_value"):
					card_data["current_value"] = int(card_data.get("current_value", current_base_value)) + effect_amount
			_:
				if effect.begins_with("special:"):
					_apply_special_rule_effect(card_data, effect.substr("special:".length()), effect_amount)


static func get_on_discard_gold_bonus(affix_ids: Array, card_value: int) -> int:
	var bonus_gold := 0

	for raw_affix_id in affix_ids:
		var affix_id := str(raw_affix_id).strip_edges()
		if affix_id == "":
			continue

		var affix_data := get_affix_data(affix_id)
		if affix_data.is_empty():
			continue

		var trigger := str(affix_data.get("trigger", "")).strip_edges().to_lower()
		var effect := str(affix_data.get("effect", "")).strip_edges().to_lower()
		if trigger != "on_discard" or effect != "gain_gold_equal_to_card_value":
			continue

		var multiplier := maxi(int(affix_data.get("effect_amount", 1)), 1)
		bonus_gold += card_value * multiplier

	return bonus_gold


static func apply_affixes_to_card_data(card_data: Dictionary, base_card_data: Dictionary, card_id: String, affix_ids: Array) -> void:
	if affix_ids.is_empty():
		return

	var base_name := str(base_card_data.get("name", card_id))
	card_data["name"] = build_affixed_name(base_name, affix_ids)
	apply_affix_gameplay_effects(card_data, affix_ids)

	if has_foil_affix(affix_ids):
		card_data["is_foil"] = true

	var base_description := str(base_card_data.get("description", "")).strip_edges()
	var affix_lines := build_affix_description_lines(affix_ids)
	if affix_lines.is_empty():
		return

	var affix_text := "\n".join(affix_lines)
	if base_description == "":
		card_data["description"] = affix_text
	else:
		card_data["description"] = base_description + "\n\n" + affix_text


static func _apply_special_rule_effect(card_data: Dictionary, special_rule_name: String, effect_amount: int) -> void:
	var normalized_rule := special_rule_name.strip_edges().to_lower()
	if normalized_rule == "":
		return

	var special_rules = card_data.get("special_rules", [])
	if not (special_rules is Array):
		special_rules = []
	if normalized_rule not in special_rules:
		special_rules.append(normalized_rule)
	card_data["special_rules"] = special_rules

	var special_values = card_data.get("special_values", {})
	if not (special_values is Dictionary):
		special_values = {}

	var applied_amount := effect_amount if effect_amount > 0 else 1
	special_values[normalized_rule] = int(special_values.get(normalized_rule, 0)) + applied_amount
	card_data["special_values"] = special_values
