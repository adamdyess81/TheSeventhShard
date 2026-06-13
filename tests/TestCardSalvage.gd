extends SceneTree

const GAME_DATA_LOADER_SCRIPT = preload("res://core/GameDataLoader.gd")
const CARD_SALVAGE_SCRIPT = preload("res://core/CardSalvage.gd")

var _loader = GAME_DATA_LOADER_SCRIPT.new()
var _failures: Array[String] = []


func _init() -> void:
	_loader.build_card_registry()
	_run_tests()
	if _failures.is_empty():
		print("CARD SALVAGE TESTS PASSED")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _run_tests() -> void:
	_test_weapon_stack_salvage_grants_scrap_and_updates_deck()
	_test_affixed_weapon_salvage_grants_scrap_and_essence()
	_test_affixed_spell_salvage_grants_double_essence()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _test_weapon_stack_salvage_grants_scrap_and_updates_deck() -> void:
	var profile_data := {
		"owned_card_counts": {"short_sword": 2},
		"selected_deck_card_counts": {"short_sword": 1}
	}
	var card_data: Dictionary = _loader.get_card("short_sword")

	var result := CARD_SALVAGE_SCRIPT.salvage_card_stack(profile_data, card_data, "short_sword")

	_expect(bool(result.get("ok", false)), "Weapon stack salvage should succeed.")
	_expect(int(result.get("scrap_materials", 0)) == 3, "Short Sword salvage should grant scrap equal to base value.")
	_expect(int(result.get("magic_essence", 0)) == 0, "Non-affixed weapons should not grant magic essence.")
	_expect(int(profile_data.get("scrap_materials", 0)) == 3, "Scrap materials should persist onto the profile after salvage.")
	_expect(int(profile_data.get("owned_card_counts", {}).get("short_sword", 0)) == 1, "Weapon stack salvage should remove one inventory copy.")
	_expect(int(profile_data.get("selected_deck_card_counts", {}).get("short_sword", 0)) == 0, "Weapon stack salvage should remove a selected deck copy when present.")


func _test_affixed_weapon_salvage_grants_scrap_and_essence() -> void:
	var profile_data := {
		"owned_card_instances": [
			{
				"card_id": "short_sword",
				"instance_id": "card_instance_000011",
				"affix_ids": ["sharp"]
			}
		],
		"selected_deck_card_instance_ids": ["card_instance_000011"]
	}
	var card_data: Dictionary = _loader.get_card("short_sword")

	var result := CARD_SALVAGE_SCRIPT.salvage_card_instance(
		profile_data,
		card_data,
		"card_instance_000011",
		["sharp"]
	)

	_expect(bool(result.get("ok", false)), "Affixed weapon salvage should succeed.")
	_expect(int(result.get("scrap_materials", 0)) == 3, "Affixed weapon salvage should still grant scrap equal to base value.")
	_expect(int(result.get("magic_essence", 0)) == 3, "Affixed weapon salvage should grant bonus essence equal to base value.")
	_expect(int(profile_data.get("scrap_materials", 0)) == 3, "Affixed weapon salvage should persist scrap gains.")
	_expect(int(profile_data.get("magic_essence", 0)) == 3, "Affixed weapon salvage should persist essence gains.")
	_expect(profile_data.get("owned_card_instances", []).is_empty(), "Affixed weapon salvage should remove the owned instance.")
	_expect(profile_data.get("selected_deck_card_instance_ids", []).is_empty(), "Affixed weapon salvage should remove the instance from the selected deck.")


func _test_affixed_spell_salvage_grants_double_essence() -> void:
	var profile_data := {
		"owned_card_instances": [
			{
				"card_id": "fire_bolt",
				"instance_id": "card_instance_000099",
				"affix_ids": ["overcharged"]
			}
		],
		"selected_deck_card_instance_ids": []
	}
	var card_data: Dictionary = _loader.get_card("fire_bolt")

	var result := CARD_SALVAGE_SCRIPT.salvage_card_instance(
		profile_data,
		card_data,
		"card_instance_000099",
		["overcharged"]
	)

	_expect(bool(result.get("ok", false)), "Affixed spell salvage should succeed.")
	_expect(int(result.get("scrap_materials", 0)) == 0, "Affixed spell salvage should not grant scrap.")
	_expect(int(result.get("magic_essence", 0)) == 6, "Affixed spell salvage should grant base essence plus base-value bonus essence.")
	_expect(int(profile_data.get("magic_essence", 0)) == 6, "Affixed spell salvage should persist the full essence payout.")
