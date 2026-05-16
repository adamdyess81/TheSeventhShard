extends RefCounted
class_name OutcomeController

func check_outcome(match_state: MatchCombatState) -> String:
    if match_state.is_player_dead():
        return "failure"

    if match_state.is_boss_defeated():
        return "victory"

    if _is_survival_outcome(match_state):
        return "survival"

    return "ongoing"


func is_victory(match_state: MatchCombatState) -> bool:
    return check_outcome(match_state) == "victory"


func is_failure(match_state: MatchCombatState) -> bool:
    return check_outcome(match_state) == "failure"


func is_survival(match_state: MatchCombatState) -> bool:
    return check_outcome(match_state) == "survival"


func is_ongoing(match_state: MatchCombatState) -> bool:
    return check_outcome(match_state) == "ongoing"


func _is_survival_outcome(match_state: MatchCombatState) -> bool:
    if not match_state.is_shared_deck_empty():
        return false

    if match_state.board_state.active_count() > 0:
        return false

    if match_state.is_player_dead():
        return false

    if match_state.is_boss_defeated():
        return false

    return true
