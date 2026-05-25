extends SceneTree

const COMBAT_SCENE = preload("res://combat/combat_scene.tscn")

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
	_test_boss_drop_grant_adds_missing_inventory_key()
	_test_nonmatching_outcome_does_not_grant_boss_drop()


func _build_combat_scene():
	var scene = COMBAT_SCENE.instantiate()
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


func _test_boss_drop_grant_adds_missing_inventory_key() -> void:
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
				"card_id": "battle_focus",
				"weight": 1,
				"rarity": "uncommon"
			}
		]
	}

	var rewards: Array = scene._grant_boss_drop_rewards("victory")
	var owned_card_counts: Dictionary = scene.player_profile_data.get("owned_card_counts", {})
	_expect(rewards.size() == 1, "Direct victory should grant one boss reward when drop_count is 1.")
	_expect(int(owned_card_counts.get("battle_focus", 0)) == 1, "Granted boss rewards should create the owned_card_counts entry when it did not already exist.")
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
