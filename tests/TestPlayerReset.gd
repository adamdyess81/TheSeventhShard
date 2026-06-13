extends SceneTree

const HOVEL_SCENE_SCRIPT = preload("res://hovel/hovel_scene.gd")

var _failures: Array[String] = []


func _init() -> void:
	_run_tests()
	if _failures.is_empty():
		print("PLAYER RESET TESTS PASSED")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _run_tests() -> void:
	_test_reset_restores_knight_baseline()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _test_reset_restores_knight_baseline() -> void:
	var hovel = HOVEL_SCENE_SCRIPT.new()
	hovel.player_profile_data = {
		"active_class_id": "knight",
		"persistent_gold": 999,
		"scrap_materials": 123,
		"magic_essence": 456,
		"player_level": 12,
		"total_xp": 3165,
		"max_deck_size_base": 99,
		"starting_health_base": 99,
		"owned_card_counts": {
			"shift_fate": 10
		},
		"selected_deck_card_counts": {
			"shift_fate": 10
		},
		"owned_relic_ids": ["some_relic"],
		"owned_rune_ids": ["some_rune"],
		"progression_flag_ids": ["flag"],
		"hovel_upgrade_ids": ["upgrade"],
		"hovel_shop_state": {
			"offers": [
				{ "offer_id": "offer_1" }
			]
		},
		"last_battle_reward_summary": {
			"boss_drop_rewards": []
		}
	}

	hovel.reset_player_profile_to_knight_baseline()

	_expect(int(hovel.player_profile_data.get("player_level", 0)) == 1, "Reset should restore player level 1.")
	_expect(int(hovel.player_profile_data.get("total_xp", -1)) == 0, "Reset should restore 0 XP.")
	_expect(int(hovel.player_profile_data.get("persistent_gold", -1)) == 0, "Reset should restore 0 gold.")
	_expect(int(hovel.player_profile_data.get("scrap_materials", -1)) == 0, "Reset should restore 0 scrap materials.")
	_expect(int(hovel.player_profile_data.get("magic_essence", -1)) == 0, "Reset should restore 0 magic essence.")
	_expect(int(hovel.player_profile_data.get("max_deck_size_base", 0)) == 15, "Reset should restore a 15-card max deck base.")
	_expect(int(hovel.player_profile_data.get("starting_health_base", 0)) == 20, "Reset should restore 20 base health.")
	_expect(hovel.player_profile_data.get("owned_relic_ids", []).is_empty(), "Reset should clear owned relics.")
	_expect(hovel.player_profile_data.get("owned_rune_ids", []).is_empty(), "Reset should clear owned runes.")
	_expect(hovel.player_profile_data.get("progression_flag_ids", []).is_empty(), "Reset should clear progression flags.")
	_expect(hovel.player_profile_data.get("hovel_upgrade_ids", []).is_empty(), "Reset should clear Hovel upgrades.")
	_expect(hovel.player_profile_data.get("hovel_shop_state", {}).is_empty(), "Reset should clear current Hovel shop state before reroll.")
	_expect(not hovel.player_profile_data.has("last_battle_reward_summary"), "Reset should clear the last battle reward summary.")

	var inventory: Dictionary = hovel.player_profile_data.get("owned_card_counts", {})
	_expect(int(inventory.get("small_health_potion", 0)) == 5, "Reset should restore 5 small health potions.")
	_expect(int(inventory.get("large_health_potion", 0)) == 2, "Reset should restore 2 large health potions.")
	_expect(int(inventory.get("small_shield", 0)) == 4, "Reset should restore 4 small shields.")
	_expect(int(inventory.get("short_sword", 0)) == 4, "Reset should restore 4 short swords.")
	_expect(inventory.size() == 4, "Reset should restore only the Knight starting inventory.")

	var selected_deck: Dictionary = hovel.player_profile_data.get("selected_deck_card_counts", {})
	_expect(int(selected_deck.get("small_health_potion", 0)) == 5, "Reset should restore the Knight starter deck selection.")
	_expect(int(selected_deck.get("large_health_potion", 0)) == 2, "Reset should restore the Knight starter deck selection.")
	_expect(int(selected_deck.get("small_shield", 0)) == 4, "Reset should restore the Knight starter deck selection.")
	_expect(int(selected_deck.get("short_sword", 0)) == 4, "Reset should restore the Knight starter deck selection.")
	_expect(hovel.player_profile_data.get("selected_deck_card_instance_ids", []) is Array, "Reset should restore selected affixed deck ids as an array.")
	_expect(hovel.player_profile_data.get("owned_card_instances", []) is Array, "Reset should restore owned affixed card instances as an array.")
