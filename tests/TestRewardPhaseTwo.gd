extends SceneTree

const COMBAT_SCENE_SCRIPT = preload("res://combat/combat_scene.gd")
const CARD_AFFIX_LIBRARY_SCRIPT = preload("res://core/CardAffixLibrary.gd")

var _failures: Array[String] = []


func _init() -> void:
	_run_tests()
	if _failures.is_empty():
		print("PHASE 2 REWARD TESTS PASSED")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _run_tests() -> void:
	_test_missing_boss_drop_table_fails_soft()
	_test_named_boss_drop_table_loads()
	_test_boss_drop_grant_creates_affixed_reward_instance()
	_test_nonmatching_outcome_does_not_grant_boss_drop()
	_test_reward_affix_candidates_are_family_filtered()
	_test_reward_affix_roll_stays_inside_family_pool()
	_test_affix_gameplay_effects_apply_to_card_data()
	_test_affix_discard_gold_bonus_is_reported()


func _build_combat_scene():
	var scene = COMBAT_SCENE_SCRIPT.new()
	scene.data_loader.build_card_registry()
	return scene


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _test_missing_boss_drop_table_fails_soft() -> void:
	var scene = _build_combat_scene()
	var missing_table: Dictionary = scene._load_boss_drop_table("boss_that_does_not_exist")
	_expect(missing_table.is_empty(), "Missing boss drop tables should return an empty dictionary without hard failure.")
	scene.free()


func _test_named_boss_drop_table_loads() -> void:
	var scene = _build_combat_scene()
	var table: Dictionary = scene._load_boss_drop_table("ossaran_lich")
	_expect(str(table.get("boss_id", "")) == "ossaran_lich", "Boss drop table loader should resolve ossaran_lich by naming convention.")
	_expect(int(table.get("drop_count", 0)) == 1, "Ossaran Lich boss drop table should expose drop_count 1 for Phase 2.")
	scene.free()


func _test_boss_drop_grant_creates_affixed_reward_instance() -> void:
	var scene = _build_combat_scene()
	scene.player_profile_data = {
		"owned_card_counts": {},
		"owned_card_instances": [],
		"next_card_instance_number": 1
	}
	scene.current_boss_drop_table = {
		"id": "test_boss_drops",
		"boss_id": "test_boss",
		"drop_count": 1,
		"grant_on_outcome": ["victory"],
		"entries": [
			{
				"card_id": "battle_focus",
				"weight": 1,
				"rarity": "uncommon"
			}
		]
	}

	var rewards: Array = scene._grant_boss_drop_rewards("victory")
	var owned_card_counts: Dictionary = scene.player_profile_data.get("owned_card_counts", {})
	var owned_card_instances = scene.player_profile_data.get("owned_card_instances", [])
	_expect(rewards.size() == 1, "Direct victory should grant one boss reward when drop_count is 1.")
	_expect(int(owned_card_counts.get("battle_focus", 0)) == 0, "Affixed boss rewards should be tracked as owned instances instead of base card counts.")
	_expect(owned_card_instances is Array and owned_card_instances.size() == 1, "Affixed boss rewards should create a single owned card instance.")
	if owned_card_instances is Array and owned_card_instances.size() == 1:
		var reward_instance = owned_card_instances[0]
		_expect(str(reward_instance.get("card_id", "")) == "battle_focus", "Affixed reward instance should keep the granted card id.")
		_expect(reward_instance.get("affix_ids", []) is Array and reward_instance.get("affix_ids", []).size() == 1, "Affixed reward instance should record exactly one affix id.")
		var reward_affix_ids = reward_instance.get("affix_ids", [])
		if reward_affix_ids is Array and reward_affix_ids.size() == 1:
			_expect(str(reward_affix_ids[0]) in ["golden", "overcharged", "quick"], "Spell reward affixes should roll from the spell-specific pool plus shared affixes.")
	scene.free()


func _test_nonmatching_outcome_does_not_grant_boss_drop() -> void:
	var scene = _build_combat_scene()
	scene.player_profile_data = {
		"owned_card_counts": {}
	}
	scene.current_boss_drop_table = {
		"id": "test_boss_drops",
		"boss_id": "test_boss",
		"drop_count": 1,
		"grant_on_outcome": ["victory"],
		"entries": [
			{
				"card_id": "short_sword",
				"weight": 1,
				"rarity": "common"
			}
		]
	}

	var rewards: Array = scene._grant_boss_drop_rewards("survival")
	var owned_card_counts: Dictionary = scene.player_profile_data.get("owned_card_counts", {})
	_expect(rewards.is_empty(), "Non-matching outcomes should not grant boss drop rewards.")
	_expect(int(owned_card_counts.get("short_sword", 0)) == 0, "Non-matching outcomes should not modify inventory counts.")
	scene.free()


func _test_reward_affix_candidates_are_family_filtered() -> void:
	var scene = _build_combat_scene()

	var weapon_candidates: Array = scene._get_reward_affix_roll_candidates("short_sword")
	var spell_candidates: Array = scene._get_reward_affix_roll_candidates("fire_bolt")
	var shield_candidates: Array = scene._get_reward_affix_roll_candidates("small_shield")
	var potion_candidates: Array = scene._get_reward_affix_roll_candidates("small_health_potion")

	_expect(_candidate_ids(weapon_candidates) == ["golden", "quick", "sharp"], "Weapon reward affix candidates should include Golden, Quick, and Sharp.")
	_expect(_candidate_ids(spell_candidates) == ["golden", "overcharged", "quick"], "Spell reward affix candidates should include Golden, Quick, and Overcharged.")
	_expect(_candidate_ids(shield_candidates) == ["golden", "hard", "quick"], "Shield reward affix candidates should include Golden, Quick, and Hard.")
	_expect(_candidate_ids(potion_candidates) == ["golden", "potent", "quick"], "Potion reward affix candidates should include Golden, Quick, and Potent.")
	scene.free()


func _test_reward_affix_roll_stays_inside_family_pool() -> void:
	var scene = _build_combat_scene()
	for _i in range(40):
		var weapon_affix: String = scene._roll_reward_affix_id("short_sword")
		var spell_affix: String = scene._roll_reward_affix_id("fire_bolt")
		var shield_affix: String = scene._roll_reward_affix_id("small_shield")
		var potion_affix: String = scene._roll_reward_affix_id("small_health_potion")

		_expect(weapon_affix in ["golden", "quick", "sharp"], "Weapon reward affix rolls should never leave the weapon pool.")
		_expect(spell_affix in ["golden", "overcharged", "quick"], "Spell reward affix rolls should never leave the spell pool.")
		_expect(shield_affix in ["golden", "hard", "quick"], "Shield reward affix rolls should never leave the shield pool.")
		_expect(potion_affix in ["golden", "potent", "quick"], "Potion reward affix rolls should never leave the potion pool.")
	scene.free()


func _test_affix_gameplay_effects_apply_to_card_data() -> void:
	var quick_card := {
		"id": "test_quick_weapon",
		"name": "Test Quick Weapon",
		"family": "weapon",
		"base_value": 3
	}
	CARD_AFFIX_LIBRARY_SCRIPT.apply_affixes_to_card_data(
		quick_card,
		quick_card.duplicate(true),
		"test_quick_weapon",
		["quick"]
	)
	_expect("rush" in quick_card.get("special_rules", []), "Quick affix should add the rush special rule to runtime card data.")
	_expect(int(quick_card.get("special_values", {}).get("rush", 0)) == 1, "Quick affix should add Rush 1 to runtime card data.")

	var sharp_card := {
		"id": "test_sharp_weapon",
		"name": "Test Sharp Weapon",
		"family": "weapon",
		"base_value": 3,
		"current_value": 3
	}
	CARD_AFFIX_LIBRARY_SCRIPT.apply_affixes_to_card_data(
		sharp_card,
		sharp_card.duplicate(true),
		"test_sharp_weapon",
		["sharp"]
	)
	_expect(int(sharp_card.get("base_value", 0)) == 4, "Sharp affix should increase base value by 1.")
	_expect(int(sharp_card.get("current_value", 0)) == 4, "Sharp affix should increase current value by 1 when present.")


func _test_affix_discard_gold_bonus_is_reported() -> void:
	var bonus_gold := CARD_AFFIX_LIBRARY_SCRIPT.get_on_discard_gold_bonus(["golden"], 7)
	_expect(bonus_gold == 7, "Golden affix should grant gold equal to card value on discard.")


func _candidate_ids(candidates: Array) -> Array[String]:
	var ids: Array[String] = []
	for candidate in candidates:
		if not (candidate is Dictionary):
			continue

		ids.append(str(candidate.get("id", "")).strip_edges())

	ids.sort()
	return ids
