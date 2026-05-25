extends RefCounted
class_name HovelShop

static func load_rules(loader: GameDataLoader, path: String) -> Dictionary:
	if path.strip_edges() == "":
		return {}
	if not FileAccess.file_exists(path):
		return {}
	return loader.load_json(path)


static func get_shop_level(profile_data: Dictionary) -> int:
	return maxi(int(profile_data.get("hovel_shop_level", 1)), 1)


static func refresh_shop_state(
	profile_data: Dictionary,
	loader: GameDataLoader,
	rules_path: String,
	refresh_source: String
) -> Dictionary:
	var rules: Dictionary = load_rules(loader, rules_path)
	if rules.is_empty():
		return {}

	var shop_level := get_shop_level(profile_data)
	var player_level := maxi(int(profile_data.get("player_level", 1)), 1)
	var offers := generate_offers(loader, rules, shop_level, player_level)
	var state := {
		"shop_table_id": str(rules.get("id", "")).strip_edges(),
		"shop_level": shop_level,
		"player_level_at_refresh": player_level,
		"last_refresh_source": refresh_source,
		"refresh_trigger": str(rules.get("refresh_trigger", "")).strip_edges(),
		"offers": offers
	}
	profile_data["hovel_shop_state"] = state
	return state


static func generate_offers(
	loader: GameDataLoader,
	rules: Dictionary,
	shop_level: int,
	player_level: int
) -> Array:
	var level_config := _get_shop_level_config(rules, shop_level)
	if level_config.is_empty():
		return []

	var slots = level_config.get("slots", [])
	if not (slots is Array):
		return []

	var price_rules = rules.get("price_rules", {})
	if not (price_rules is Dictionary):
		price_rules = {}

	var rarity_pools = rules.get("rarity_pools", {})
	if not (rarity_pools is Dictionary):
		rarity_pools = {}

	var allow_duplicate_offers := bool(rules.get("allow_duplicate_offers", true))
	var offers: Array = []
	var used_card_ids: Dictionary = {}

	for slot in slots:
		if not (slot is Dictionary):
			continue

		var rarity := _roll_slot_rarity(slot)
		if rarity == "":
			continue

		var card_id := _roll_card_id_from_rarity_pool(rarity_pools, rarity, allow_duplicate_offers, used_card_ids)
		if card_id == "":
			continue

		used_card_ids[card_id] = true
		offers.append({
			"offer_id": "shop_%d_%d_%d" % [shop_level, int(slot.get("slot_index", offers.size())), randi() % 1000000],
			"card_id": card_id,
			"rarity": rarity,
			"price": int(price_rules.get(rarity, 0)),
			"shop_level": shop_level,
			"player_level_at_roll": player_level
		})

	return offers


static func _get_shop_level_config(rules: Dictionary, shop_level: int) -> Dictionary:
	var shop_levels = rules.get("shop_levels", [])
	if not (shop_levels is Array):
		return {}

	for level_config in shop_levels:
		if level_config is Dictionary and int(level_config.get("shop_level", 0)) == shop_level:
			return level_config

	return {}


static func _roll_slot_rarity(slot: Dictionary) -> String:
	var guaranteed_rarity := str(slot.get("guaranteed_rarity", "")).strip_edges()
	if guaranteed_rarity != "":
		return guaranteed_rarity

	var rolls = slot.get("rolls", [])
	if not (rolls is Array):
		return ""

	var total_weight := 0
	var weighted_rolls: Array[Dictionary] = []
	for roll in rolls:
		if not (roll is Dictionary):
			continue
		var weight := maxi(int(roll.get("weight", 0)), 0)
		if weight <= 0:
			continue
		total_weight += weight
		weighted_rolls.append(roll)

	if total_weight <= 0 or weighted_rolls.is_empty():
		return ""

	var selection := randi() % total_weight
	var running_weight := 0
	for roll in weighted_rolls:
		running_weight += int(roll.get("weight", 0))
		if selection < running_weight:
			return str(roll.get("rarity", "")).strip_edges()

	return str(weighted_rolls[weighted_rolls.size() - 1].get("rarity", "")).strip_edges()


static func _roll_card_id_from_rarity_pool(
	rarity_pools: Dictionary,
	rarity: String,
	allow_duplicate_offers: bool,
	used_card_ids: Dictionary
) -> String:
	var raw_pool = rarity_pools.get(rarity, [])
	if not (raw_pool is Array) or raw_pool.is_empty():
		return ""

	var eligible_pool: Array[String] = []
	for entry in raw_pool:
		var card_id := str(entry).strip_edges()
		if card_id == "":
			continue
		if not allow_duplicate_offers and used_card_ids.has(card_id):
			continue
		eligible_pool.append(card_id)

	if eligible_pool.is_empty():
		return ""

	return eligible_pool[randi() % eligible_pool.size()]
