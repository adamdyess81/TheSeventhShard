extends SceneTree

const GAME_DATA_LOADER_SCRIPT = preload("res://core/GameDataLoader.gd")
const BOARD_STATE_SCRIPT = preload("res://combat/BoardState.gd")
const PLAYER_COMBAT_STATE_SCRIPT = preload("res://combat/PlayerCombatState.gd")
const BOSS_COMBAT_STATE_SCRIPT = preload("res://combat/BossCombatState.gd")
const SHARED_DECK_STATE_SCRIPT = preload("res://combat/SharedDeckState.gd")
const MATCH_COMBAT_STATE_SCRIPT = preload("res://combat/MatchCombatState.gd")
const COMBAT_SCENE_SCRIPT = preload("res://combat/combat_scene.gd")

const PLAYER_STARTING_HEALTH := 15
const PLAYER_MAX_DECK_SIZE := 15
const BACKPACK_CAPACITY := 1
const BOSS_STARTING_HEALTH := 12
const REWARD_PROFILE_PATH := "res://data/rewards/baseline_match_rewards.json"

var _loader = GAME_DATA_LOADER_SCRIPT.new()
var _failures: Array[String] = []


func _init() -> void:
	_loader.build_card_registry()
	_run_tests()
	if _failures.is_empty():
		print("PHASE 1 REWARD TESTS PASSED")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _run_tests() -> void:
	_test_reward_profile_gold_rules()
	_test_reward_summary_captures_phase_one_fields()
	_test_combat_scene_script_loads()


func _build_match_state() -> MatchCombatState:
	var board_state = BOARD_STATE_SCRIPT.new()
	board_state.setup(4)

	var player_state = PLAYER_COMBAT_STATE_SCRIPT.new()
	player_state.setup(PLAYER_STARTING_HEALTH, BACKPACK_CAPACITY, PLAYER_MAX_DECK_SIZE)

	var boss_state = BOSS_COMBAT_STATE_SCRIPT.new()
	boss_state.setup("ossaran_lich", "Ossaran Lich", BOSS_STARTING_HEALTH)

	var shared_deck = SHARED_DECK_STATE_SCRIPT.new()
	shared_deck.setup([])

	var match_state = MATCH_COMBAT_STATE_SCRIPT.new()
	match_state.setup(player_state, boss_state, board_state, shared_deck, 1)
	return match_state


func _card(card_id: String) -> Dictionary:
	return _loader.get_card(card_id).duplicate(true)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _test_reward_profile_gold_rules() -> void:
	var reward_profile := _loader.load_json(REWARD_PROFILE_PATH)
	var match_state := _build_match_state()

	_expect(match_state.should_keep_temporary_gold("victory", reward_profile), "Victory should bank temporary gold in the baseline reward profile.")
	_expect(match_state.should_keep_temporary_gold("survival", reward_profile), "Survival should bank temporary gold in the baseline reward profile.")
	_expect(not match_state.should_keep_temporary_gold("failure", reward_profile), "Failure should not bank temporary gold in the baseline reward profile.")


func _test_reward_summary_captures_phase_one_fields() -> void:
	var match_state := _build_match_state()
	match_state.player_state.add_temporary_gold(20)

	var left_hand_chest := _card("small_chest")
	var backpack_chest := _card("small_chest")
	var equipped := match_state.player_state.set_left_hand_card(left_hand_chest)
	var stashed := match_state.player_state.add_to_backpack(backpack_chest)
	match_state.boss_state.take_damage(999)

	var summary := match_state.build_battle_reward_summary("victory", 12, "baseline", 50, 20)
	var chest_carry_state: Dictionary = summary.get("chest_carry_state", {})

	_expect(equipped, "Phase 1 test should be able to equip a chest into the left hand.")
	_expect(stashed, "Phase 1 test should be able to stash a chest into the backpack.")
	_expect(summary.get("outcome", "") == "victory", "Reward summary should capture the battle outcome.")
	_expect(bool(summary.get("boss_kill", false)), "Reward summary should flag a direct boss kill on victory.")
	_expect(int(summary.get("player_level", 0)) == 12, "Reward summary should capture the player level.")
	_expect(str(summary.get("boss_difficulty", "")) == "baseline", "Reward summary should capture the boss difficulty.")
	_expect(int(summary.get("temporary_gold_collected", 0)) == 20, "Reward summary should capture temporary gold collected.")
	_expect(int(summary.get("persistent_gold_before", 0)) == 50, "Reward summary should capture persistent gold before payout.")
	_expect(int(summary.get("persistent_gold_awarded", 0)) == 20, "Reward summary should capture the persistent gold awarded.")
	_expect(int(summary.get("persistent_gold_after", 0)) == 70, "Reward summary should calculate persistent gold after payout.")
	_expect(bool(chest_carry_state.get("left_hand_has_chest", false)), "Reward summary should record a chest carried in hand.")
	_expect(int(chest_carry_state.get("backpack_chest_count", 0)) == 1, "Reward summary should record chest count carried in backpack.")
	_expect(int(chest_carry_state.get("total_carried_chest_count", 0)) == 2, "Reward summary should total all carried chests.")


func _test_combat_scene_script_loads() -> void:
	_expect(COMBAT_SCENE_SCRIPT != null, "Combat scene script should still preload after the Phase 1 reward changes.")
