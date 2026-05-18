extends Node

const DEFAULT_PLAYER_STARTING_HEALTH := 15
const DEFAULT_PLAYER_MAX_DECK_SIZE := 15
const BOSS_STARTING_HEALTH := 12
const STARTING_BACKPACK_CAPACITY := 1
const PLAYER_PROFILE_PATH := "res://profiles/player_main.json"

func _ready() -> void:
    var loader = GameDataLoader.new()
    loader.build_card_registry()
    var player_profile := loader.load_json(PLAYER_PROFILE_PATH)
    var player_starting_health := int(player_profile.get(
        "starting_health_base",
        DEFAULT_PLAYER_STARTING_HEALTH
    ))
    var player_max_deck_size := int(player_profile.get(
        "max_deck_size_base",
        DEFAULT_PLAYER_MAX_DECK_SIZE
    ))

    var controller_board_state := BoardState.new()
    controller_board_state.setup(4)

    var controller_player_state := PlayerCombatState.new()
    controller_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)

    var controller_boss_state := BossCombatState.new()
    controller_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var controller_shared_deck := SharedDeckState.new()
    controller_shared_deck.setup([
        loader.get_card("risen_bones").duplicate(true),
        loader.get_card("gold_10").duplicate(true)
    ])

    controller_board_state.get_active_cards().append(loader.get_card("grave_thrall").duplicate(true))
    controller_board_state.get_active_cards().append(loader.get_card("short_sword").duplicate(true))

    var controller_match_state := MatchCombatState.new()
    controller_match_state.setup(
        controller_player_state,
        controller_boss_state,
        controller_board_state,
        controller_shared_deck,
        1
    )

    var controller_resolution := ResolutionController.new()
    var controller_outcome := OutcomeController.new()

    var combat_controller := CombatController.new()
    combat_controller.setup(
        controller_match_state,
        controller_resolution,
        controller_outcome
    )

    print("\n=== TEST COMBAT CONTROLLER ===")
    print("Controller Test Board Start:")
    _print_card_list(combat_controller.match_state.get_active_board_cards())
    print("Controller Test Deck Remaining: ", combat_controller.match_state.shared_deck_state.remaining_count())
    print("Controller Test Round: ", combat_controller.match_state.round_number)
    print("Controller Test Outcome: ", combat_controller.get_current_outcome())

    var controller_monster_result := combat_controller.resolve_enemy_to_player(0)
    print("\nController resolved monster to player?: ", controller_monster_result)
    print("Player Health After Controller Monster Resolve: ", combat_controller.match_state.player_state.current_health, "/", combat_controller.match_state.player_state.max_health)
    print("Board After Controller Monster Resolve:")
    _print_card_list(combat_controller.match_state.get_active_board_cards())
    print("Deck Remaining After Auto-Refill: ", combat_controller.match_state.shared_deck_state.remaining_count())
    print("Round After Auto-Refill: ", combat_controller.match_state.round_number)

    var controller_left_hand_result := combat_controller.move_player_card_to_left_hand(0)
    print("\nController moved player card to left hand?: ", controller_left_hand_result)
    if combat_controller.match_state.player_state.left_hand_card is CardRuntimeState:
        print("Left Hand After Controller Move: ", combat_controller.match_state.player_state.left_hand_card.card_id)
        print("Left Hand Zone: ", combat_controller.match_state.player_state.left_hand_card.zone)
    elif combat_controller.match_state.player_state.left_hand_card is Dictionary:
        print("Left Hand After Controller Move: ", combat_controller.match_state.player_state.left_hand_card.get("id", "[none]"))
        print("Left Hand Zone: ", combat_controller.match_state.player_state.left_hand_card.get("zone", "[none]"))
    else:
        print("Left Hand After Controller Move: [none]")

    print("Board After Controller Left Hand Move:")
    _print_card_list(combat_controller.match_state.get_active_board_cards())
    print("Deck Remaining After Second Auto-Refill: ", combat_controller.match_state.shared_deck_state.remaining_count())
    print("Round After Second Auto-Refill: ", combat_controller.match_state.round_number)
    var backpack_board_state := BoardState.new()
    backpack_board_state.setup(4)

    var backpack_player_state := PlayerCombatState.new()
    backpack_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)

    var backpack_boss_state := BossCombatState.new()
    backpack_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var backpack_shared_deck := SharedDeckState.new()
    backpack_shared_deck.setup([
        loader.get_card("small_shield").duplicate(true)
    ])

    backpack_board_state.refill_from_deck(backpack_shared_deck)

    var backpack_match_state := MatchCombatState.new()
    backpack_match_state.setup(
        backpack_player_state,
        backpack_boss_state,
        backpack_board_state,
        backpack_shared_deck,
        1
    )

    var backpack_resolution := ResolutionController.new()
    var backpack_outcome := OutcomeController.new()

    var backpack_controller := CombatController.new()
    backpack_controller.setup(
        backpack_match_state,
        backpack_resolution,
        backpack_outcome
    )

    print("\n=== BACKPACK ZONE TEST ===")
    print("Backpack Test Board Start:")
    _print_card_list(backpack_controller.match_state.get_active_board_cards())

    var backpack_move_result := backpack_controller.move_player_card_to_backpack(0)
    print("Moved player card to backpack?: ", backpack_move_result)

    if backpack_controller.match_state.player_state.backpack_cards.size() > 0:
        var backpack_card = backpack_controller.match_state.player_state.backpack_cards[0]

        if backpack_card is CardRuntimeState:
            print("Backpack Card ID: ", backpack_card.card_id)
            print("Backpack Card Zone: ", backpack_card.zone)
        elif backpack_card is Dictionary:
            print("Backpack Card ID: ", backpack_card.get("id", "[none]"))
            print("Backpack Card Zone: ", backpack_card.get("zone", "[none]"))
    else:
        print("Backpack is empty.")
        print("\n=== RIGHT HAND ZONE TEST ===")

    var right_hand_board_state := BoardState.new()
    right_hand_board_state.setup(4)

    var right_hand_player_state := PlayerCombatState.new()
    right_hand_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)

    var right_hand_boss_state := BossCombatState.new()
    right_hand_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var right_hand_shared_deck := SharedDeckState.new()
    right_hand_shared_deck.setup([
        loader.get_card("short_sword").duplicate(true)
    ])

    right_hand_board_state.refill_from_deck(right_hand_shared_deck)

    var right_hand_match_state := MatchCombatState.new()
    right_hand_match_state.setup(
        right_hand_player_state,
        right_hand_boss_state,
        right_hand_board_state,
        right_hand_shared_deck,
        1
    )

    var right_hand_resolution := ResolutionController.new()
    var right_hand_outcome := OutcomeController.new()

    var right_hand_controller := CombatController.new()
    right_hand_controller.setup(
        right_hand_match_state,
        right_hand_resolution,
        right_hand_outcome
    )

    print("Right Hand Test Board Start:")
    _print_card_list(right_hand_controller.match_state.get_active_board_cards())

    var right_hand_move_result := right_hand_controller.move_player_card_to_right_hand(0)
    print("Moved player card to right hand?: ", right_hand_move_result)

    var right_hand_card = right_hand_controller.match_state.player_state.right_hand_card

    if right_hand_card is CardRuntimeState:
        print("Right Hand Card ID: ", right_hand_card.card_id)
        print("Right Hand Card Zone: ", right_hand_card.zone)
    elif right_hand_card is Dictionary:
        print("Right Hand Card ID: ", right_hand_card.get("id", "[none]"))
        print("Right Hand Card Zone: ", right_hand_card.get("zone", "[none]"))
    else:
        print("Right Hand is empty.")
        print("\n=== RUNTIME FLAG TESTS ===")

    var flag_board_state := BoardState.new()
    flag_board_state.setup(4)

    var flag_player_state := PlayerCombatState.new()
    flag_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)

    var flag_boss_state := BossCombatState.new()
    flag_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var flag_shared_deck := SharedDeckState.new()
    flag_shared_deck.setup([
        loader.get_card("short_sword").duplicate(true),
        loader.get_card("small_health_potion").duplicate(true)
    ])

    flag_board_state.refill_from_deck(flag_shared_deck)

    var flag_match_state := MatchCombatState.new()
    flag_match_state.setup(
        flag_player_state,
        flag_boss_state,
        flag_board_state,
        flag_shared_deck,
        1
    )

    var flag_resolution := ResolutionController.new()
    var flag_outcome := OutcomeController.new()

    var flag_controller := CombatController.new()
    flag_controller.setup(
        flag_match_state,
        flag_resolution,
        flag_outcome
    )

    print("Flag Test Board Start:")
    _print_card_list(flag_controller.match_state.get_active_board_cards())

    var flag_move_result := flag_controller.move_player_card_to_left_hand(0)
    print("Moved first card to left hand?: ", flag_move_result)

    var left_flag_card = flag_controller.match_state.player_state.left_hand_card
    if left_flag_card is CardRuntimeState:
        print("Left Hand Card ID: ", left_flag_card.card_id)
        print("Left Hand Card Resolved?: ", left_flag_card.is_resolved)
        print("Left Hand Card Exhausted?: ", left_flag_card.is_exhausted)
        print("Left Hand Card Destroyed?: ", left_flag_card.is_destroyed)

    flag_controller.match_state.player_state.take_damage(5)
    print("Player Health Before Potion Hand Drop: ", flag_controller.match_state.player_state.current_health, "/", flag_controller.match_state.player_state.max_health)

    var potion_move_result := flag_controller.move_player_card_to_right_hand(0)
    print("Moved second card to right hand?: ", potion_move_result)
    print("Player Health After Potion Hand Drop: ", flag_controller.match_state.player_state.current_health, "/", flag_controller.match_state.player_state.max_health)

    var right_flag_card = flag_controller.match_state.player_state.right_hand_card
    print("Right Hand Card After Potion Hand Drop: ", right_flag_card)
    print("Right Hand Exhausted After Potion Hand Drop?: ", flag_controller.match_state.player_state.right_hand_exhausted)

    print("\n=== OCCUPIED HAND BLOCK TEST ===")

    var occupied_board_state := BoardState.new()
    occupied_board_state.setup(4)

    var occupied_player_state := PlayerCombatState.new()
    occupied_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)

    var occupied_boss_state := BossCombatState.new()
    occupied_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var occupied_shared_deck := SharedDeckState.new()
    occupied_shared_deck.setup([])

    occupied_board_state.get_active_cards().append(loader.get_card("small_health_potion").duplicate(true))
    occupied_board_state.get_active_cards().append(loader.get_card("gold_10").duplicate(true))

    var occupied_match_state := MatchCombatState.new()
    occupied_match_state.setup(
        occupied_player_state,
        occupied_boss_state,
        occupied_board_state,
        occupied_shared_deck,
        1
    )

    occupied_match_state.player_state.set_left_hand_card(loader.get_card("short_sword").duplicate(true))
    occupied_match_state.player_state.set_right_hand_card(loader.get_card("small_shield").duplicate(true))
    occupied_match_state.player_state.take_damage(5)

    var occupied_resolution := ResolutionController.new()
    var occupied_outcome := OutcomeController.new()

    var occupied_controller := CombatController.new()
    occupied_controller.setup(
        occupied_match_state,
        occupied_resolution,
        occupied_outcome
    )

    var health_before_block_test := occupied_controller.match_state.player_state.current_health
    var left_hand_before_block_test = occupied_controller.match_state.player_state.left_hand_card
    var right_hand_before_block_test = occupied_controller.match_state.player_state.right_hand_card

    var blocked_potion_result := occupied_controller.move_player_card_to_left_hand(0)
    var blocked_coin_result := occupied_controller.move_player_card_to_right_hand(1)

    print("Blocked potion into occupied left hand?: ", blocked_potion_result)
    print("Blocked coin into occupied right hand?: ", blocked_coin_result)
    print("Player Health After Block Test: ", occupied_controller.match_state.player_state.current_health, "/", occupied_controller.match_state.player_state.max_health)
    print("Left Hand Unchanged?: ", left_hand_before_block_test == occupied_controller.match_state.player_state.left_hand_card)
    print("Right Hand Unchanged?: ", right_hand_before_block_test == occupied_controller.match_state.player_state.right_hand_card)
    print("Health Unchanged?: ", health_before_block_test == occupied_controller.match_state.player_state.current_health)
    print("Board Count After Block Test: ", occupied_controller.match_state.board_state.active_count())

    print("\n=== BACKPACK POTION STASH TEST ===")

    var stash_board_state := BoardState.new()
    stash_board_state.setup(4)

    var stash_player_state := PlayerCombatState.new()
    stash_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)
    stash_player_state.take_damage(4)

    var stash_boss_state := BossCombatState.new()
    stash_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var stash_shared_deck := SharedDeckState.new()
    stash_shared_deck.setup([])
    stash_board_state.get_active_cards().append(loader.get_card("small_health_potion").duplicate(true))

    var stash_match_state := MatchCombatState.new()
    stash_match_state.setup(
        stash_player_state,
        stash_boss_state,
        stash_board_state,
        stash_shared_deck,
        1
    )

    var stash_resolution := ResolutionController.new()
    var stash_outcome := OutcomeController.new()

    var stash_controller := CombatController.new()
    stash_controller.setup(
        stash_match_state,
        stash_resolution,
        stash_outcome
    )

    var stash_move_result := stash_controller.move_player_card_to_backpack(0)
    print("Moved potion to backpack?: ", stash_move_result)
    print("Player Health After Backpack Stash: ", stash_controller.match_state.player_state.current_health, "/", stash_controller.match_state.player_state.max_health)
    print("Backpack Count After Stash: ", stash_controller.match_state.player_state.backpack_cards.size())

    if stash_controller.match_state.player_state.backpack_cards.size() > 0:
        var stashed_card = stash_controller.match_state.player_state.backpack_cards[0]
        if stashed_card is CardRuntimeState:
            print("Stashed Card ID: ", stashed_card.card_id)
            print("Stashed Card Zone: ", stashed_card.zone)
            print("Stashed Card Resolved?: ", stashed_card.is_resolved)
            print("Stashed Card Destroyed?: ", stashed_card.is_destroyed)

    print("\n=== PARTIAL WEAPON DAMAGE TEST ===")

    var partial_board_state := BoardState.new()
    partial_board_state.setup(4)

    var partial_player_state := PlayerCombatState.new()
    partial_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)

    var partial_boss_state := BossCombatState.new()
    partial_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var partial_shared_deck := SharedDeckState.new()
    partial_shared_deck.setup([])
    partial_board_state.get_active_cards().append(loader.get_card("sepulcher_guard").duplicate(true))

    var weakened_weapon = loader.get_card("short_sword").duplicate(true)
    if weakened_weapon is CardRuntimeState:
        weakened_weapon.current_value = 2
    elif weakened_weapon is Dictionary:
        weakened_weapon["current_value"] = 2

    var partial_match_state := MatchCombatState.new()
    partial_match_state.setup(
        partial_player_state,
        partial_boss_state,
        partial_board_state,
        partial_shared_deck,
        1
    )
    partial_match_state.player_state.set_left_hand_card(weakened_weapon)

    var partial_resolution := ResolutionController.new()
    var partial_outcome := OutcomeController.new()

    var partial_controller := CombatController.new()
    partial_controller.setup(
        partial_match_state,
        partial_resolution,
        partial_outcome
    )

    var partial_result := partial_controller.use_left_hand_weapon_on_monster(0)
    print("Partial weapon attack succeeded?: ", partial_result)
    print("Left Hand After Partial Attack: ", partial_controller.match_state.player_state.left_hand_card)
    print("Left Hand Exhausted After Partial Attack?: ", partial_controller.match_state.player_state.left_hand_exhausted)
    print("Board Count After Partial Attack: ", partial_controller.match_state.board_state.active_count())

    if partial_controller.match_state.board_state.active_count() > 0:
        var remaining_monster = partial_controller.match_state.board_state.get_active_cards()[0]
        if remaining_monster is CardRuntimeState:
            print("Remaining Monster ID: ", remaining_monster.card_id)
            print("Remaining Monster Value: ", remaining_monster.current_value)
        elif remaining_monster is Dictionary:
            print("Remaining Monster ID: ", remaining_monster.get("id", "[none]"))
            print("Remaining Monster Value: ", remaining_monster.get("current_value", remaining_monster.get("base_value", "[none]")))

    print("\n=== BACKPACK HAND TRANSFER TEST ===")

    var transfer_board_state := BoardState.new()
    transfer_board_state.setup(4)

    var transfer_player_state := PlayerCombatState.new()
    transfer_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)

    var transfer_boss_state := BossCombatState.new()
    transfer_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var transfer_shared_deck := SharedDeckState.new()
    transfer_shared_deck.setup([])

    var transfer_match_state := MatchCombatState.new()
    transfer_match_state.setup(
        transfer_player_state,
        transfer_boss_state,
        transfer_board_state,
        transfer_shared_deck,
        1
    )

    transfer_match_state.player_state.add_to_backpack(loader.get_card("short_sword").duplicate(true))

    var backpack_transfer_card = transfer_match_state.player_state.remove_backpack_card_at(0)
    var backpack_to_hand_result := transfer_match_state.player_state.set_left_hand_card(backpack_transfer_card)
    print("Backpack to left hand succeeded?: ", backpack_to_hand_result)
    print("Backpack Count After Move To Hand: ", transfer_match_state.player_state.backpack_cards.size())
    if transfer_match_state.player_state.left_hand_card is CardRuntimeState:
        print("Left Hand Card After Backpack Move: ", transfer_match_state.player_state.left_hand_card.card_id)
        print("Left Hand Zone After Backpack Move: ", transfer_match_state.player_state.left_hand_card.zone)

    var hand_transfer_card = transfer_match_state.player_state.left_hand_card
    transfer_match_state.player_state.clear_left_hand_card()
    var hand_to_backpack_result := transfer_match_state.player_state.add_to_backpack(hand_transfer_card)
    print("Left hand back to backpack succeeded?: ", hand_to_backpack_result)
    print("Left Hand After Return To Backpack: ", transfer_match_state.player_state.left_hand_card)
    print("Backpack Count After Return: ", transfer_match_state.player_state.backpack_cards.size())
    if transfer_match_state.player_state.backpack_cards.size() > 0:
        var returned_backpack_card = transfer_match_state.player_state.backpack_cards[0]
        if returned_backpack_card is CardRuntimeState:
            print("Returned Backpack Card ID: ", returned_backpack_card.card_id)
            print("Returned Backpack Card Zone: ", returned_backpack_card.zone)

    print("\n=== BOARD GAP TEST ===")

    var gap_board_state := BoardState.new()
    gap_board_state.setup(4)
    gap_board_state.get_active_cards()[0] = loader.get_card("crypt_hound").duplicate(true)
    gap_board_state.get_active_cards()[1] = loader.get_card("grave_thrall").duplicate(true)
    gap_board_state.get_active_cards()[2] = loader.get_card("risen_bones").duplicate(true)
    gap_board_state.get_active_cards()[3] = loader.get_card("sepulcher_guard").duplicate(true)

    var removed_gap_card = gap_board_state.remove_card_at(1)
    print("Removed Gap Card Exists?: ", removed_gap_card != null)
    print("Board Count After Gap Remove: ", gap_board_state.active_count())
    print("Board Slot 0 Empty?: ", gap_board_state.get_active_cards()[0] == null)
    print("Board Slot 1 Empty?: ", gap_board_state.get_active_cards()[1] == null)
    print("Board Slot 2 Empty?: ", gap_board_state.get_active_cards()[2] == null)
    print("Board Slot 3 Empty?: ", gap_board_state.get_active_cards()[3] == null)

    print("\nController Final Outcome: ", combat_controller.get_current_outcome())


func _print_card_list(cards: Array) -> void:
    if cards.is_empty():
        print("- [none]")
        return

    for card in cards:
        if card is CardRuntimeState:
            print("- %s | family: %s | value: %s | zone: %s" % [
                card.card_id,
                card.get_family(),
                str(card.current_value),
                card.zone
            ])
        elif card is Dictionary:
            var card_id := str(card.get("id", "UNKNOWN"))
            var family := str(card.get("family", "UNKNOWN"))
            var base_value = card.get("base_value", null)

            var value_text := "null"
            if base_value != null:
                value_text = str(base_value)

            print("- %s | family: %s | value: %s" % [card_id, family, value_text])
        else:
            print("- [unknown card type]")
