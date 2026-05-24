extends SceneTree

const GAME_DATA_LOADER_SCRIPT = preload("res://core/GameDataLoader.gd")
const BOARD_STATE_SCRIPT = preload("res://combat/BoardState.gd")
const PLAYER_COMBAT_STATE_SCRIPT = preload("res://combat/PlayerCombatState.gd")
const BOSS_COMBAT_STATE_SCRIPT = preload("res://combat/BossCombatState.gd")
const SHARED_DECK_STATE_SCRIPT = preload("res://combat/SharedDeckState.gd")
const MATCH_COMBAT_STATE_SCRIPT = preload("res://combat/MatchCombatState.gd")
const RESOLUTION_CONTROLLER_SCRIPT = preload("res://combat/ResolutionController.gd")

const PLAYER_STARTING_HEALTH := 15
const PLAYER_MAX_DECK_SIZE := 15
const BACKPACK_CAPACITY := 1
const BOSS_STARTING_HEALTH := 12

var _loader = GAME_DATA_LOADER_SCRIPT.new()
var _resolution = RESOLUTION_CONTROLLER_SCRIPT.new()
var _failures: Array[String] = []


func _init() -> void:
	_loader.build_card_registry()
	_run_tests()
	if _failures.is_empty():
		print("ALL NEW SPECIALS SMOKE TESTS PASSED")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _run_tests() -> void:
	_test_adrenaline_potion()
	_test_defense_potion_next_round_buff()
	_test_power_potion_next_round_buff()
	_test_thorns_reduces_monster_before_block()
	_test_second_strike_resolves_on_second_use()
	_test_spite_triggers_when_monster_dies()
	_test_sweep_hits_adjacent_monsters()
	_test_split_spends_weapon_value_one_point_at_a_time()
	_test_pierce_carries_over_to_second_target()


func _build_match_state() -> MatchCombatState:
	var board_state = BOARD_STATE_SCRIPT.new()
	board_state.setup(4)

	var player_state = PLAYER_COMBAT_STATE_SCRIPT.new()
	player_state.setup(PLAYER_STARTING_HEALTH, BACKPACK_CAPACITY, PLAYER_MAX_DECK_SIZE)

	var boss_state = BOSS_COMBAT_STATE_SCRIPT.new()
	boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

	var shared_deck = SHARED_DECK_STATE_SCRIPT.new()
	shared_deck.setup([])

	var match_state = MATCH_COMBAT_STATE_SCRIPT.new()
	match_state.setup(player_state, boss_state, board_state, shared_deck, 1)
	return match_state


func _card(card_id: String) -> Dictionary:
	return _loader.get_card(card_id).duplicate(true)


func _set_value(card: Dictionary, value: int) -> Dictionary:
	card["current_value"] = value
	return card


func _runtime_value(card: Dictionary) -> int:
	if card.has("current_value"):
		return int(card.get("current_value", 0))
	return int(card.get("base_value", 0))


func _place_on_board(match_state: MatchCombatState, cards: Array) -> void:
	var active_cards := match_state.board_state.get_active_cards()
	for i in range(active_cards.size()):
		active_cards[i] = null
	for i in range(mini(cards.size(), active_cards.size())):
		var card = cards[i]
		if card is Dictionary:
			card["zone"] = "board"
		active_cards[i] = card


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _test_adrenaline_potion() -> void:
	var match_state := _build_match_state()
	match_state.player_state.take_damage(2)
	match_state.player_state.set_left_hand_card(_card("adrenaline_potion"))

	var used := _resolution.use_left_hand_potion(match_state)

	_expect(used, "Adrenaline Potion should be usable from hand.")
	_expect(match_state.player_state.base_max_health == 16, "Adrenaline Potion should raise base max health by 1.")
	_expect(match_state.player_state.max_health == 16, "Adrenaline Potion should raise max health by 1.")
	_expect(match_state.player_state.current_health == 14, "Adrenaline Potion should raise current health by the added capacity.")


func _test_defense_potion_next_round_buff() -> void:
	var match_state := _build_match_state()
	var shield := _card("small_shield")
	match_state.player_state.set_right_hand_card(shield)
	match_state.player_state.set_left_hand_card(_card("defense_potion"))

	var used := _resolution.use_left_hand_potion(match_state)

	_expect(used, "Defense Potion should be usable from hand.")
	_expect(match_state.player_state.pending_shield_bonus == 1, "Defense Potion should queue a shield bonus for next round.")
	_expect(_runtime_value(shield) == 3, "Defense Potion should not immediately change shield value.")

	match_state.advance_round()
	_expect(match_state.player_state.active_shield_bonus == 1, "Defense Potion should activate on the next round.")
	_expect(_runtime_value(shield) == 4, "Defense Potion should give shields +1 value during the next round.")

	match_state.advance_round()
	_expect(match_state.player_state.active_shield_bonus == 0, "Defense Potion bonus should expire after the round.")
	_expect(_runtime_value(shield) == 3, "Defense Potion bonus should be removed after the round ends.")


func _test_power_potion_next_round_buff() -> void:
	var match_state := _build_match_state()
	var weapon := _card("short_sword")
	match_state.player_state.set_right_hand_card(weapon)
	match_state.player_state.set_left_hand_card(_card("power_potion"))

	var used := _resolution.use_left_hand_potion(match_state)

	_expect(used, "Power Potion should be usable from hand.")
	_expect(match_state.player_state.pending_weapon_bonus == 1, "Power Potion should queue a weapon bonus for next round.")
	_expect(_runtime_value(weapon) == int(weapon.get("base_value", 0)), "Power Potion should not immediately change weapon value.")

	match_state.advance_round()
	_expect(match_state.player_state.active_weapon_bonus == 1, "Power Potion should activate on the next round.")
	_expect(_runtime_value(weapon) == int(weapon.get("base_value", 0)) + 1, "Power Potion should give weapons +1 value during the next round.")

	match_state.advance_round()
	_expect(match_state.player_state.active_weapon_bonus == 0, "Power Potion bonus should expire after the round.")
	_expect(_runtime_value(weapon) == int(weapon.get("base_value", 0)), "Power Potion bonus should be removed after the round ends.")


func _test_thorns_reduces_monster_before_block() -> void:
	var match_state := _build_match_state()
	var shield := _card("spiked_shield")
	var monster := _set_value(_card("risen_bones"), 2)
	match_state.player_state.set_left_hand_card(shield)
	_place_on_board(match_state, [monster])

	var resolved := _resolution.resolve_monster_into_left_hand_shield(match_state, 0)

	_expect(resolved, "Shield should be able to block a monster.")
	_expect(match_state.player_state.current_health == PLAYER_STARTING_HEALTH, "Thorns block should prevent player damage when shield survives.")
	_expect(match_state.player_state.left_hand_card != null, "Thorns block should leave the shield equipped if it has value remaining.")
	_expect(int(match_state.player_state.left_hand_card.get("current_value", 0)) == 1, "Thorns should reduce the incoming monster value before defense is calculated.")


func _test_second_strike_resolves_on_second_use() -> void:
	var match_state := _build_match_state()
	match_state.player_state.set_left_hand_card(_card("dagger"))
	_place_on_board(match_state, [_card("risen_bones"), _card("risen_bones")])

	var first_use := _resolution.use_left_hand_weapon_on_monster(match_state, 0)

	_expect(first_use, "Second Strike weapon should be usable on the first hit.")
	_expect(match_state.player_state.left_hand_card != null, "Second Strike should return the weapon to the hand it came from after the first use.")
	_expect(str(match_state.player_state.left_hand_card.get("id", "")) == "dagger", "Second Strike should keep the same weapon in hand after the first use.")
	_expect(not match_state.player_state.left_hand_exhausted, "Second Strike should not exhaust the hand on the first use.")
	_expect(match_state.board_state.active_count() == 1, "Second Strike should still resolve the first target monster.")

	var second_use := _resolution.use_left_hand_weapon_on_monster(match_state, 1)

	_expect(second_use, "Second Strike weapon should be usable on the second hit.")
	_expect(match_state.player_state.left_hand_card == null, "Second Strike should resolve the weapon after the second use.")
	_expect(match_state.player_state.left_hand_exhausted, "Second Strike should exhaust the hand after the second use.")
	_expect(match_state.board_state.active_count() == 0, "Second Strike should still resolve the second target monster.")


func _test_spite_triggers_when_monster_dies() -> void:
	var match_state := _build_match_state()
	match_state.player_state.set_left_hand_card(_card("spear"))
	_place_on_board(match_state, [_set_value(_card("frenzied_abomination"), 1)])

	var used := _resolution.use_left_hand_weapon_on_monster(match_state, 0)

	_expect(used, "A weapon should be able to kill a spite monster.")
	_expect(match_state.player_state.current_health == PLAYER_STARTING_HEALTH - 1, "Spite should trigger when the monster dies and leaves the board.")
	_expect(match_state.board_state.active_count() == 0, "The spite monster should still be removed from the board on death.")


func _test_sweep_hits_adjacent_monsters() -> void:
	var match_state := _build_match_state()
	match_state.player_state.set_left_hand_card(_card("axe"))
	_place_on_board(match_state, [_card("risen_bones"), _card("crypt_hound"), _card("risen_bones")])

	var used := _resolution.use_left_hand_weapon_on_monster(match_state, 1)

	_expect(used, "Sweep weapon should be usable.")
	_expect(match_state.board_state.active_count() == 0, "Sweep should damage both adjacent monsters while killing the primary target.")
	_expect(match_state.player_state.left_hand_card == null, "Sweep weapon should still be consumed normally after use.")
	_expect(match_state.player_state.left_hand_exhausted, "Sweep weapon should exhaust the hand after use.")


func _test_split_spends_weapon_value_one_point_at_a_time() -> void:
	var match_state := _build_match_state()
	match_state.player_state.set_left_hand_card(_card("short_bow"))
	_place_on_board(match_state, [_card("risen_bones"), _card("risen_bones")])

	var first_use := _resolution.use_left_hand_weapon_on_monster(match_state, 0)

	_expect(first_use, "Split weapon should be usable on the first target.")
	_expect(match_state.player_state.left_hand_card != null, "Split weapon should remain in hand while it has value left.")
	_expect(int(match_state.player_state.left_hand_card.get("current_value", 0)) == 1, "Split weapon should spend only 1 value per attack.")
	_expect(not match_state.player_state.left_hand_exhausted, "Split weapon should not exhaust the hand until all value is spent.")
	_expect(match_state.board_state.active_count() == 1, "Split weapon should remove only the first target on the first use.")

	var second_use := _resolution.use_left_hand_weapon_on_monster(match_state, 1)

	_expect(second_use, "Split weapon should be usable on the second target.")
	_expect(match_state.player_state.left_hand_card == null, "Split weapon should be consumed after spending its last point of value.")
	_expect(match_state.player_state.left_hand_exhausted, "Split weapon should exhaust the hand after its final use.")
	_expect(match_state.board_state.active_count() == 0, "Split weapon should be able to finish a second legal target.")


func _test_pierce_carries_over_to_second_target() -> void:
	var match_state := _build_match_state()
	match_state.player_state.set_left_hand_card(_card("spear"))
	_place_on_board(match_state, [_card("risen_bones")])

	var first_use := _resolution.use_left_hand_weapon_on_monster(match_state, 0)

	_expect(first_use, "Pierce weapon should be usable on the first target.")
	_expect(match_state.player_state.left_hand_card != null, "Pierce weapon should remain in hand when overflow damage exists.")
	_expect(int(match_state.player_state.left_hand_card.get("current_value", 0)) == 2, "Pierce weapon should keep the overflow damage as its follow-up value.")
	_expect(not match_state.player_state.left_hand_exhausted, "Pierce follow-up should not exhaust the hand before the second target.")

	var second_use := _resolution.use_left_hand_weapon_on_boss(match_state)

	_expect(second_use, "Pierce weapon should be able to spend its follow-up damage on the boss.")
	_expect(match_state.boss_state.current_health == BOSS_STARTING_HEALTH - 2, "Pierce overflow should damage the second target.")
	_expect(match_state.player_state.left_hand_card == null, "Pierce weapon should be consumed after the follow-up attack.")
	_expect(match_state.player_state.left_hand_exhausted, "Pierce weapon should exhaust the hand after the follow-up attack.")
