extends RefCounted
class_name CombatController

var match_state: MatchCombatState
var resolution_controller: ResolutionController
var outcome_controller: OutcomeController


func setup(
    new_match_state: MatchCombatState,
    new_resolution_controller: ResolutionController,
    new_outcome_controller: OutcomeController
) -> void:
    match_state = new_match_state
    resolution_controller = new_resolution_controller
    outcome_controller = new_outcome_controller


func get_current_outcome() -> String:
    return outcome_controller.check_outcome(match_state)


func refill_board_if_needed() -> bool:
    return match_state.refill_board_if_allowed()


func resolve_enemy_to_player(board_index: int) -> bool:
    var success := resolution_controller.resolve_enemy_to_player(match_state, board_index)
    _post_action_update()
    return success


func resolve_gold_to_temporary_gold(board_index: int) -> bool:
    var success := resolution_controller.resolve_gold_to_temporary_gold(match_state, board_index)
    _post_action_update()
    return success


func move_player_card_to_left_hand(board_index: int) -> bool:
    var success := resolution_controller.move_player_card_to_left_hand(match_state, board_index)
    _post_action_update()
    return success


func move_player_card_to_right_hand(board_index: int) -> bool:
    var success := resolution_controller.move_player_card_to_right_hand(match_state, board_index)
    _post_action_update()
    return success


func move_player_card_to_backpack(board_index: int) -> bool:
    var success := resolution_controller.move_player_card_to_backpack(match_state, board_index)
    _post_action_update()
    return success


func trash_player_card_from_board(board_index: int) -> bool:
    var success := resolution_controller.trash_player_card_from_board(match_state, board_index)
    _post_action_update()
    return success


func use_left_hand_weapon_on_monster(board_index: int) -> bool:
    var success := resolution_controller.use_left_hand_weapon_on_monster(match_state, board_index)
    _post_action_update()
    return success


func use_right_hand_weapon_on_monster(board_index: int) -> bool:
    var success := resolution_controller.use_right_hand_weapon_on_monster(match_state, board_index)
    _post_action_update()
    return success


func resolve_monster_into_left_hand_shield(board_index: int) -> bool:
    var success := resolution_controller.resolve_monster_into_left_hand_shield(match_state, board_index)
    _post_action_update()
    return success


func resolve_monster_into_right_hand_shield(board_index: int) -> bool:
    var success := resolution_controller.resolve_monster_into_right_hand_shield(match_state, board_index)
    _post_action_update()
    return success


func use_left_hand_potion() -> bool:
    var success := resolution_controller.use_left_hand_potion(match_state)
    _post_action_update()
    return success


func use_right_hand_potion() -> bool:
    var success := resolution_controller.use_right_hand_potion(match_state)
    _post_action_update()
    return success


func _post_action_update() -> void:
    if get_current_outcome() == "ongoing":
        refill_board_if_needed()
