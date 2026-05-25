extends SceneTree

const GAME_DATA_LOADER_SCRIPT = preload("res://core/GameDataLoader.gd")
const HOVEL_SHOP_SCRIPT = preload("res://core/HovelShop.gd")

const HOVEL_SHOP_RULES_PATH := "res://data/rewards/hovel_shop_common.json"

var _loader = GAME_DATA_LOADER_SCRIPT.new()
var _failures: Array[String] = []


func _init() -> void:
	_loader.build_card_registry()
	_run_tests()
	if _failures.is_empty():
		print("PHASE 5 HOVEL SHOP TESTS PASSED")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _run_tests() -> void:
	_test_hovel_shop_rules_load()
	_test_level_one_offer_shape()
	_test_shop_state_refresh_persists_three_offers()
	_test_purchase_offer_succeeds_and_removes_stock()
	_test_purchase_offer_creates_missing_inventory_key()
	_test_purchase_offer_blocks_when_gold_is_too_low()
	_test_missing_shop_rules_fail_soft()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _test_hovel_shop_rules_load() -> void:
	var rules: Dictionary = HOVEL_SHOP_SCRIPT.load_rules(_loader, HOVEL_SHOP_RULES_PATH)
	_expect(str(rules.get("id", "")) == "hovel_shop_common", "Hovel shop rules should load from the configured JSON file.")
	_expect(bool(rules.get("allow_duplicate_offers", false)), "Baseline Hovel shop rules should allow duplicate offers for now.")


func _test_level_one_offer_shape() -> void:
	var rules: Dictionary = HOVEL_SHOP_SCRIPT.load_rules(_loader, HOVEL_SHOP_RULES_PATH)
	var offers: Array = HOVEL_SHOP_SCRIPT.generate_offers(_loader, rules, 1, 12)
	_expect(offers.size() == 3, "Shop level 1 should generate exactly three offers.")
	_expect(str(offers[0].get("rarity", "")) == "common", "Shop level 1 slot one should always be common.")
	_expect(str(offers[1].get("rarity", "")) == "common", "Shop level 1 slot two should always be common.")
	_expect(str(offers[2].get("rarity", "")) in ["common", "uncommon"], "Shop level 1 slot three should roll common or uncommon.")
	for offer in offers:
		var rarity := str(offer.get("rarity", "")).strip_edges()
		var price := int(offer.get("price", -1))
		if rarity == "common":
			_expect(price == 25, "Common shop offers should price from the common rarity rule.")
		elif rarity == "uncommon":
			_expect(price == 60, "Uncommon shop offers should price from the uncommon rarity rule.")


func _test_shop_state_refresh_persists_three_offers() -> void:
	var profile_data := {
		"player_level": 12
	}
	var state: Dictionary = HOVEL_SHOP_SCRIPT.refresh_shop_state(
		profile_data,
		_loader,
		HOVEL_SHOP_RULES_PATH,
		"battle_end"
	)
	var offers = state.get("offers", [])
	_expect(state.has("shop_table_id"), "Refreshing Hovel shop state should persist the source table id.")
	_expect(str(state.get("last_refresh_source", "")) == "battle_end", "Refreshing Hovel shop state should preserve the refresh source.")
	_expect(offers is Array and offers.size() == 3, "Refreshing Hovel shop state should persist exactly three offers.")


func _test_purchase_offer_succeeds_and_removes_stock() -> void:
	var profile_data := {
		"persistent_gold": 100,
		"owned_card_counts": {},
		"hovel_shop_state": {
			"offers": [
				{ "offer_id": "offer_1", "card_id": "short_sword", "rarity": "common", "price": 25 },
				{ "offer_id": "offer_2", "card_id": "small_shield", "rarity": "common", "price": 25 },
				{ "offer_id": "offer_3", "card_id": "battle_focus", "rarity": "common", "price": 25 }
			]
		}
	}
	var result: Dictionary = HOVEL_SHOP_SCRIPT.purchase_offer(profile_data, 1)
	var offers = profile_data["hovel_shop_state"]["offers"]
	_expect(bool(result.get("ok", false)), "Purchase should succeed when the player has enough gold.")
	_expect(int(profile_data.get("persistent_gold", 0)) == 75, "Successful purchases should subtract the offer price from persistent gold.")
	_expect(int(profile_data["owned_card_counts"].get("small_shield", 0)) == 1, "Successful purchases should add the bought card to inventory.")
	_expect(offers[1] == null, "Successful purchases should clear the purchased offer slot until the next reroll.")


func _test_purchase_offer_creates_missing_inventory_key() -> void:
	var profile_data := {
		"persistent_gold": 100,
		"owned_card_counts": {},
		"hovel_shop_state": {
			"offers": [
				{ "offer_id": "offer_1", "card_id": "ward_of_ash", "rarity": "uncommon", "price": 60 }
			]
		}
	}
	var result: Dictionary = HOVEL_SHOP_SCRIPT.purchase_offer(profile_data, 0)
	_expect(bool(result.get("ok", false)), "Purchase should succeed for a valid one-off offer.")
	_expect(int(profile_data["owned_card_counts"].get("ward_of_ash", 0)) == 1, "Buying a card should create the inventory key when it does not already exist.")


func _test_purchase_offer_blocks_when_gold_is_too_low() -> void:
	var profile_data := {
		"persistent_gold": 10,
		"owned_card_counts": {},
		"hovel_shop_state": {
			"offers": [
				{ "offer_id": "offer_1", "card_id": "short_sword", "rarity": "common", "price": 25 }
			]
		}
	}
	var result: Dictionary = HOVEL_SHOP_SCRIPT.purchase_offer(profile_data, 0)
	_expect(not bool(result.get("ok", false)), "Purchase should fail when the player does not have enough gold.")
	_expect(str(result.get("reason", "")) == "insufficient_gold", "Low-gold purchase failures should report the correct reason.")
	_expect(int(profile_data.get("persistent_gold", 0)) == 10, "Failed purchases should not change persistent gold.")
	_expect(int(profile_data["owned_card_counts"].get("short_sword", 0)) == 0, "Failed purchases should not add cards to inventory.")


func _test_missing_shop_rules_fail_soft() -> void:
	var profile_data := {
		"player_level": 12
	}
	var state: Dictionary = HOVEL_SHOP_SCRIPT.refresh_shop_state(
		profile_data,
		_loader,
		"res://data/rewards/does_not_exist.json",
		"battle_end"
	)
	_expect(state.is_empty(), "Missing Hovel shop rule files should fail soft and return an empty state.")
