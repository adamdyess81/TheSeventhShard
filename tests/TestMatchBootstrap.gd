extends Node

const DEFAULT_PLAYER_STARTING_HEALTH := 15
const DEFAULT_PLAYER_MAX_DECK_SIZE := 15
const BOSS_STARTING_HEALTH := 12
const ACTIVE_BOARD_CAP := 4
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

    var starter_deck := loader.load_deck("res://data/decks/starter_knight_deck.json")
    var resolved_player_cards := loader.resolve_deck_cards(starter_deck)

    var monster_deck := loader.load_deck("res://data/decks/ossara_baseline_monster_deck.json")
    var resolved_monster_cards := loader.resolve_monster_deck(monster_deck)

    var merged_cards := loader.build_shared_deck(resolved_player_cards, resolved_monster_cards)

    var shared_deck := SharedDeckState.new()
    shared_deck.setup(merged_cards)

    var board_state := BoardState.new()
    board_state.setup(ACTIVE_BOARD_CAP)
    board_state.refill_from_deck(shared_deck)

    var player_state := PlayerCombatState.new()
    player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)

    var boss_state := BossCombatState.new()
    boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var match_state := MatchCombatState.new()
    match_state.setup(player_state, boss_state, board_state, shared_deck, 1)

    var resolution := ResolutionController.new()

    print("\n=== MATCH BOOTSTRAP TEST ===")
    print("Player Health: ", match_state.player_state.current_health, "/", match_state.player_state.max_health)
    print("Boss Health: ", match_state.boss_state.current_health, "/", match_state.boss_state.max_health)
    print("Boss ID: ", match_state.boss_state.boss_id)
    print("Boss Name: ", match_state.boss_state.boss_name)
    print("Boss Rules Count: ", match_state.boss_state.special_rules.size())
    print("Round Number: ", match_state.round_number)
    print("Temporary Gold: ", match_state.player_state.temporary_gold)
    print("Backpack Capacity: ", match_state.player_state.backpack_capacity)
    print("Carried Chests: ", match_state.player_state.carried_chests.size())

    print("\nACTIVE BOARD CARD COUNT:")
    print(match_state.board_state.active_count())

    print("\nACTIVE BOARD CARDS:")
    _print_card_list(match_state.get_active_board_cards())

    print("\nREMAINING SHARED DECK COUNT:")
    print(match_state.shared_deck_state.remaining_count())

    print("\nNEXT 10 CARDS IN SHARED DECK:")
    _print_card_list(match_state.shared_deck_state.peek(10))

    print("\n=== BASIC RESOLUTION TESTS ===")

    var basic_board_state := BoardState.new()
    basic_board_state.setup(4)

    var basic_player_state := PlayerCombatState.new()
    basic_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)

    var basic_boss_state := BossCombatState.new()
    basic_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var basic_shared_deck := SharedDeckState.new()
    basic_shared_deck.setup([])

    var basic_match_state := MatchCombatState.new()
    basic_match_state.setup(basic_player_state, basic_boss_state, basic_board_state, basic_shared_deck, 1)

    basic_board_state.get_active_cards().append(loader.get_card("grave_thrall").duplicate(true))
    basic_board_state.get_active_cards().append(loader.get_card("gold_10").duplicate(true))
    basic_board_state.get_active_cards().append(loader.get_card("short_sword").duplicate(true))
    basic_board_state.get_active_cards().append(loader.get_card("small_shield").duplicate(true))

    print("\nBASIC TEST BOARD START:")
    _print_card_list(basic_match_state.get_active_board_cards())
    print("Player Health: ", basic_match_state.player_state.current_health, "/", basic_match_state.player_state.max_health)
    print("Temporary Gold: ", basic_match_state.player_state.temporary_gold)

    var monster_result := resolution.resolve_enemy_to_player(basic_match_state, 0)
    print("\nResolved monster to player?: ", monster_result)
    print("Player Health After Monster: ", basic_match_state.player_state.current_health, "/", basic_match_state.player_state.max_health)
    print("Board After Monster Resolve:")
    _print_card_list(basic_match_state.get_active_board_cards())

    var gold_result := resolution.resolve_gold_to_temporary_gold(basic_match_state, 0)
    print("\nResolved gold to temp gold?: ", gold_result)
    print("Temporary Gold After Gold Resolve: ", basic_match_state.player_state.temporary_gold)
    print("Board After Gold Resolve:")
    _print_card_list(basic_match_state.get_active_board_cards())

    var left_hand_result := resolution.move_player_card_to_left_hand(basic_match_state, 0)
    print("\nMoved player card to left hand?: ", left_hand_result)
    print("Left Hand Card: ", basic_match_state.player_state.left_hand_card.get("id", "[none]"))
    print("Board After Left Hand Move:")
    _print_card_list(basic_match_state.get_active_board_cards())

    var backpack_result := resolution.move_player_card_to_backpack(basic_match_state, 0)
    print("\nMoved player card to backpack?: ", backpack_result)
    print("Backpack Count: ", basic_match_state.player_state.backpack_cards.size())
    if basic_match_state.player_state.backpack_cards.size() > 0:
        print("Backpack Card 0: ", basic_match_state.player_state.backpack_cards[0].get("id", "[none]"))
    print("Board After Backpack Move:")
    _print_card_list(basic_match_state.get_active_board_cards())

    print("\n=== WEAPON TEST ===")

    var weapon_board_state := BoardState.new()
    weapon_board_state.setup(4)

    var weapon_player_state := PlayerCombatState.new()
    weapon_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)

    var weapon_boss_state := BossCombatState.new()
    weapon_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var weapon_shared_deck := SharedDeckState.new()
    weapon_shared_deck.setup([])

    var weapon_match_state := MatchCombatState.new()
    weapon_match_state.setup(weapon_player_state, weapon_boss_state, weapon_board_state, weapon_shared_deck, 1)

    weapon_match_state.player_state.set_left_hand_card(loader.get_card("short_sword").duplicate(true))
    weapon_board_state.get_active_cards().append(loader.get_card("risen_bones").duplicate(true))

    print("Weapon Test Board Start:")
    _print_card_list(weapon_match_state.get_active_board_cards())
    print("Left Hand Before Weapon Use: ", weapon_match_state.player_state.left_hand_card.get("id", "[none]"))

    var weapon_result := resolution.use_left_hand_weapon_on_monster(weapon_match_state, 0)
    print("Weapon used successfully?: ", weapon_result)
    print("Left Hand After Weapon Use: ", weapon_match_state.player_state.left_hand_card.get("id", "[none]"))
    print("Left Hand Exhausted?: ", weapon_match_state.player_state.left_hand_exhausted)
    print("Board After Weapon Use:")
    _print_card_list(weapon_match_state.get_active_board_cards())

    print("\n=== SHIELD TEST ===")

    var shield_board_state := BoardState.new()
    shield_board_state.setup(4)

    var shield_player_state := PlayerCombatState.new()
    shield_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)

    var shield_boss_state := BossCombatState.new()
    shield_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var shield_shared_deck := SharedDeckState.new()
    shield_shared_deck.setup([])

    var shield_match_state := MatchCombatState.new()
    shield_match_state.setup(shield_player_state, shield_boss_state, shield_board_state, shield_shared_deck, 1)

    shield_match_state.player_state.set_left_hand_card(loader.get_card("small_shield").duplicate(true))
    shield_board_state.get_active_cards().append(loader.get_card("grave_thrall").duplicate(true))

    print("Shield Test Board Start:")
    _print_card_list(shield_match_state.get_active_board_cards())
    print("Left Hand Shield Before Resolve: ", shield_match_state.player_state.left_hand_card.get("id", "[none]"))
    print("Shield Value Before Resolve: ", shield_match_state.player_state.left_hand_card.get("base_value", "null"))

    var shield_result := resolution.resolve_monster_into_left_hand_shield(shield_match_state, 0)
    print("Shield resolve successful?: ", shield_result)
    print("Player Health After Shield Resolve: ", shield_match_state.player_state.current_health, "/", shield_match_state.player_state.max_health)
    print("Left Hand Shield After Resolve: ", shield_match_state.player_state.left_hand_card.get("id", "[none]"))
    print("Shield Value After Resolve: ", shield_match_state.player_state.left_hand_card.get("base_value", "null"))
    print("Board After Shield Resolve:")
    _print_card_list(shield_match_state.get_active_board_cards())

    print("\n=== SHIELD OVERFLOW TEST ===")

    var overflow_board_state := BoardState.new()
    overflow_board_state.setup(4)

    var overflow_player_state := PlayerCombatState.new()
    overflow_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)

    var overflow_boss_state := BossCombatState.new()
    overflow_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var overflow_shared_deck := SharedDeckState.new()
    overflow_shared_deck.setup([])

    var overflow_match_state := MatchCombatState.new()
    overflow_match_state.setup(overflow_player_state, overflow_boss_state, overflow_board_state, overflow_shared_deck, 1)

    var weakened_shield := loader.get_card("small_shield").duplicate(true)
    weakened_shield["current_value"] = 1

    overflow_match_state.player_state.set_left_hand_card(weakened_shield)

    print("Shield Current Value Before Overflow Test: ", overflow_match_state.player_state.left_hand_card.get("current_value", "null"))
    print("Shield Base Value Before Overflow Test: ", overflow_match_state.player_state.left_hand_card.get("base_value", "null"))

    overflow_board_state.get_active_cards().append(loader.get_card("crypt_hound").duplicate(true))

    print("Overflow Test Board Start:")
    _print_card_list(overflow_match_state.get_active_board_cards())
    print("Player Health Before Overflow Test: ", overflow_match_state.player_state.current_health, "/", overflow_match_state.player_state.max_health)
    print("Shield Runtime Value Before Overflow Test: ", overflow_match_state.player_state.left_hand_card.get("current_value", "null"))
    print("Shield Base Value Before Overflow Test: ", overflow_match_state.player_state.left_hand_card.get("base_value", "null"))


    var overflow_result := resolution.resolve_monster_into_left_hand_shield(overflow_match_state, 0)
    print("Overflow shield resolve successful?: ", overflow_result)
    print("Player Health After Overflow Test: ", overflow_match_state.player_state.current_health, "/", overflow_match_state.player_state.max_health)
    print("Left Hand After Overflow Test: ", overflow_match_state.player_state.left_hand_card.get("id", "[none]"))
    print("Left Hand Exhausted After Overflow Test?: ", overflow_match_state.player_state.left_hand_exhausted)
    print("Board After Overflow Test:")
    _print_card_list(overflow_match_state.get_active_board_cards())

    print("\n=== POTION TEST ===")

    var potion_board_state := BoardState.new()
    potion_board_state.setup(4)

    var potion_player_state := PlayerCombatState.new()
    potion_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)
    potion_player_state.take_damage(5)

    var potion_boss_state := BossCombatState.new()
    potion_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var potion_shared_deck := SharedDeckState.new()
    potion_shared_deck.setup([])

    var potion_match_state := MatchCombatState.new()
    potion_match_state.setup(potion_player_state, potion_boss_state, potion_board_state, potion_shared_deck, 1)

    potion_match_state.player_state.set_left_hand_card(loader.get_card("small_health_potion").duplicate(true))

    print("Potion Test Start:")
    print("Player Health Before Potion: ", potion_match_state.player_state.current_health, "/", potion_match_state.player_state.max_health)
    print("Left Hand Before Potion Use: ", potion_match_state.player_state.left_hand_card.get("id", "[none]"))

    var potion_result := resolution.use_left_hand_potion(potion_match_state)
    print("Potion used successfully?: ", potion_result)
    print("Player Health After Potion: ", potion_match_state.player_state.current_health, "/", potion_match_state.player_state.max_health)
    print("Left Hand After Potion Use: ", potion_match_state.player_state.left_hand_card.get("id", "[none]"))
    print("Left Hand Exhausted After Potion Use?: ", potion_match_state.player_state.left_hand_exhausted)

    print("\n=== INVALID ACTION TESTS ===")
    var invalid_gold_on_empty_board := resolution.resolve_gold_to_temporary_gold(basic_match_state, 0)
    print("Resolve gold on empty/invalid board slot?: ", invalid_gold_on_empty_board)

    print("\n=== LIVE MATCH STATUS CHECK ===")
    print("Player dead?: ", match_state.is_player_dead())
    print("Boss defeated?: ", match_state.is_boss_defeated())
    print("Shared deck empty?: ", match_state.is_shared_deck_empty())

    print("\n=== OUTCOME CONTROLLER TESTS ===")

    var outcome := OutcomeController.new()

    var ongoing_board_state := BoardState.new()
    ongoing_board_state.setup(4)
    ongoing_board_state.get_active_cards().append(loader.get_card("risen_bones").duplicate(true))

    var ongoing_player_state := PlayerCombatState.new()
    ongoing_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)

    var ongoing_boss_state := BossCombatState.new()
    ongoing_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var ongoing_shared_deck := SharedDeckState.new()
    ongoing_shared_deck.setup([loader.get_card("grave_thrall").duplicate(true)])

    var ongoing_match_state := MatchCombatState.new()
    ongoing_match_state.setup(ongoing_player_state, ongoing_boss_state, ongoing_board_state, ongoing_shared_deck, 1)

    print("Ongoing Outcome: ", outcome.check_outcome(ongoing_match_state))

    var victory_board_state := BoardState.new()
    victory_board_state.setup(4)

    var victory_player_state := PlayerCombatState.new()
    victory_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)

    var victory_boss_state := BossCombatState.new()
    victory_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)
    victory_boss_state.take_damage(999)

    var victory_shared_deck := SharedDeckState.new()
    victory_shared_deck.setup([])

    var victory_match_state := MatchCombatState.new()
    victory_match_state.setup(victory_player_state, victory_boss_state, victory_board_state, victory_shared_deck, 1)

    print("Victory Outcome: ", outcome.check_outcome(victory_match_state))

    var failure_board_state := BoardState.new()
    failure_board_state.setup(4)

    var failure_player_state := PlayerCombatState.new()
    failure_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)
    failure_player_state.take_damage(999)

    var failure_boss_state := BossCombatState.new()
    failure_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var failure_shared_deck := SharedDeckState.new()
    failure_shared_deck.setup([])

    var failure_match_state := MatchCombatState.new()
    failure_match_state.setup(failure_player_state, failure_boss_state, failure_board_state, failure_shared_deck, 1)

    print("Failure Outcome: ", outcome.check_outcome(failure_match_state))

    var survival_board_state := BoardState.new()
    survival_board_state.setup(4)

    var survival_player_state := PlayerCombatState.new()
    survival_player_state.setup(player_starting_health, STARTING_BACKPACK_CAPACITY, player_max_deck_size)

    var survival_boss_state := BossCombatState.new()
    survival_boss_state.setup("gravebound_warden", "Gravebound Warden", BOSS_STARTING_HEALTH)

    var survival_shared_deck := SharedDeckState.new()
    survival_shared_deck.setup([])

    var survival_match_state := MatchCombatState.new()
    survival_match_state.setup(survival_player_state, survival_boss_state, survival_board_state, survival_shared_deck, 1)

    print("Survival Outcome: ", outcome.check_outcome(survival_match_state))

    print("\n=== COMBAT CONTROLLER TESTS ===")

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
    print("Left Hand After Controller Move: ", combat_controller.match_state.player_state.left_hand_card.get("id", "[none]"))
    print("Board After Controller Left Hand Move:")
    _print_card_list(combat_controller.match_state.get_active_board_cards())
    print("Deck Remaining After Second Auto-Refill: ", combat_controller.match_state.shared_deck_state.remaining_count())
    print("Round After Second Auto-Refill: ", combat_controller.match_state.round_number)

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
