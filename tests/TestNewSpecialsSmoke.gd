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
	_test_ward_of_ash_prevents_damage_until_spent()
	_test_stasis_hex_only_lowers_current_round_threshold()
	_test_fire_bolt_hits_monster_and_consumes_spell()
	_test_energy_burst_hits_board_and_boss()
	_test_recall_returns_monster_to_deck()
	_test_banishing_sigil_removes_matching_monster_from_deck()
	_test_battle_focus_refreshes_hands()
	_test_shift_fate_consumes_spell_on_player_use()
	_test_shift_fate_selected_cards_move_to_top_in_order()


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


func _test_ward_of_ash_prevents_damage_until_spent() -> void:
	var match_state := _build_match_state()
	match_state.player_state.set_left_hand_card(_card("ward_of_ash"))

	var used := _resolution.use_left_hand_spell_on_player(match_state)

	_expect(used, "Ward of Ash should be castable on the player.")
	_expect(match_state.player_state.damage_ward == 2, "Ward of Ash should add its prevention value as ward.")
	match_state.player_state.take_damage(1)
	_expect(match_state.player_state.current_health == PLAYER_STARTING_HEALTH, "Ward of Ash should prevent incoming damage while ward remains.")
	_expect(match_state.player_state.damage_ward == 1, "Ward of Ash should spend only the damage it prevented.")
	match_state.player_state.take_damage(2)
	_expect(match_state.player_state.current_health == PLAYER_STARTING_HEALTH - 1, "Ward of Ash should allow overflow damage through after the ward is spent.")
	_expect(match_state.player_state.damage_ward == 0, "Ward of Ash should fully deplete after absorbing its full value.")


func _test_stasis_hex_only_lowers_current_round_threshold() -> void:
	var match_state := _build_match_state()
	_place_on_board(match_state, [_card("risen_bones"), _card("gold_10"), null, null])
	match_state.player_state.set_left_hand_card(_card("stasis_hex"))

	var used := _resolution.use_left_hand_spell_on_player(match_state)

	_expect(used, "Stasis Hex should be castable on the player.")
	_expect(match_state.board_state.get_current_resolve_threshold() == 2, "Stasis Hex should lower the current round threshold by 1.")
	_expect(match_state.board_state.can_refill(), "Stasis Hex should immediately make the board eligible for the next round when the reduced threshold is met.")
	match_state.advance_round()
	_expect(match_state.board_state.get_current_resolve_threshold() == 3, "Stasis Hex should reset after the round advances.")


func _test_fire_bolt_hits_monster_and_consumes_spell() -> void:
	var match_state := _build_match_state()
	match_state.player_state.set_left_hand_card(_card("fire_bolt"))
	_place_on_board(match_state, [_card("risen_bones")])

	var used := _resolution.use_left_hand_spell_on_monster(match_state, 0)

	_expect(used, "Fire Bolt should cast on a monster.")
	_expect(match_state.board_state.active_count() == 0, "Fire Bolt should remove a monster it kills.")
	_expect(match_state.player_state.left_hand_card == null, "Fire Bolt should be consumed after casting.")
	_expect(match_state.player_state.left_hand_exhausted, "Fire Bolt should exhaust the casting hand.")


func _test_energy_burst_hits_board_and_boss() -> void:
	var match_state := _build_match_state()
	match_state.player_state.set_left_hand_card(_card("energy_burst"))
	_place_on_board(match_state, [_card("risen_bones"), _card("risen_bones")])

	var used := _resolution.use_left_hand_spell_on_boss(match_state)

	_expect(used, "Energy Burst should be castable at an enemy target.")
	_expect(match_state.board_state.active_count() == 0, "Energy Burst should hit every monster on the board.")
	_expect(match_state.boss_state.current_health == BOSS_STARTING_HEALTH - 1, "Energy Burst should also damage the boss.")
	_expect(match_state.player_state.current_health == PLAYER_STARTING_HEALTH, "Energy Burst should not deal player damage unless the current boss actually has retaliation.")


func _test_recall_returns_monster_to_deck() -> void:
	var match_state := _build_match_state()
	match_state.player_state.set_left_hand_card(_card("recall"))
	_place_on_board(match_state, [_card("risen_bones")])

	var used := _resolution.use_left_hand_spell_on_monster(match_state, 0)

	_expect(used, "Recall should cast on a monster.")
	_expect(match_state.board_state.active_count() == 0, "Recall should remove the target from the board.")
	_expect(match_state.shared_deck_state.remaining_count() == 1, "Recall should place the target back into the deck.")


func _test_banishing_sigil_removes_matching_monster_from_deck() -> void:
	var match_state := _build_match_state()
	match_state.shared_deck_state.setup([
		_card("risen_bones"),
		_card("crypt_hound")
	])
	match_state.player_state.set_left_hand_card(_card("banishing_sigil"))
	_place_on_board(match_state, [_card("risen_bones")])

	var used := _resolution.use_left_hand_spell_on_monster(match_state, 0)

	_expect(used, "Banishing Sigil should cast on a monster.")
	_expect(match_state.shared_deck_state.remaining_count() == 1, "Banishing Sigil should remove one matching copy from the deck.")
	var remaining = match_state.shared_deck_state.draw_card()
	_expect(remaining != null and remaining.card_id == "crypt_hound", "Banishing Sigil should remove the matching monster copy, not a random card.")
	_expect(match_state.board_state.active_count() == 1, "Banishing Sigil should leave the targeted monster on the board.")


func _test_battle_focus_refreshes_hands() -> void:
	var match_state := _build_match_state()
	match_state.player_state.set_left_hand_card(_card("battle_focus"))
	match_state.player_state.right_hand_exhausted = true

	var used := _resolution.use_left_hand_spell_on_player(match_state)

	_expect(used, "Battle Focus should be castable on the player.")
	_expect(not match_state.player_state.left_hand_exhausted, "Battle Focus should refresh the left hand.")
	_expect(not match_state.player_state.right_hand_exhausted, "Battle Focus should refresh the right hand.")
	_expect(match_state.player_state.left_hand_card == null, "Battle Focus should still consume the spell.")


func _test_shift_fate_consumes_spell_on_player_use() -> void:
	var match_state := _build_match_state()
	match_state.player_state.set_left_hand_card(_card("shift_fate"))

	var used := _resolution.use_left_hand_spell_on_player(match_state)

	_expect(used, "Shift Fate should resolve as a castable player spell.")
	_expect(match_state.player_state.left_hand_card == null, "Shift Fate should consume itself on cast.")
	_expect(match_state.player_state.left_hand_exhausted, "Shift Fate should exhaust the casting hand.")


func _test_shift_fate_selected_cards_move_to_top_in_order() -> void:
	var shared_deck := SHARED_DECK_STATE_SCRIPT.new()
	shared_deck.setup([
		_card("risen_bones"),
		_card("crypt_hound"),
		_card("gold_10"),
		_card("banshee"),
		_card("small_chest"),
		_card("short_sword")
	])

	var preview := shared_deck.peek(6)
	var selected := [preview[4], preview[1], preview[5]]
	var reordered_count := shared_deck.reorder_with_selected_top(selected)

	_expect(reordered_count == 3, "Shift Fate deck reorder should keep all selected cards.")
	var first = shared_deck.draw_card()
	var second = shared_deck.draw_card()
	var third = shared_deck.draw_card()
	_expect(first == selected[0], "Shift Fate should place the first clicked card on top.")
	_expect(second == selected[1], "Shift Fate should place the second clicked card next.")
	_expect(third == selected[2], "Shift Fate should place the third clicked card third.")
