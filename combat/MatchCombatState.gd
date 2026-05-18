extends RefCounted
class_name MatchCombatState

var player_state: PlayerCombatState
var boss_state: BossCombatState
var board_state: BoardState
var shared_deck_state: SharedDeckState

var round_number: int = 1


func setup(
 player: PlayerCombatState,
 boss: BossCombatState,
 board: BoardState,
 shared_deck: SharedDeckState,
 starting_round: int = 1
) -> void:
 player_state = player
 boss_state = boss
 board_state = board
 shared_deck_state = shared_deck
 round_number = starting_round


func advance_round() -> void:
 round_number += 1
 player_state.reset_hand_exhaustion()
 player_state.clear_stun()
 shared_deck_state.advance_round_specials()


func refill_board_if_allowed() -> bool:
 if board_state.can_refill():
  advance_round()
  board_state.refill_from_deck(shared_deck_state)
  return true

 return false


func is_player_dead() -> bool:
 return player_state.is_dead()


func is_boss_defeated() -> bool:
 return boss_state.is_defeated()


func is_shared_deck_empty() -> bool:
 return shared_deck_state.is_empty()


func get_active_board_cards() -> Array:
 return board_state.get_active_cards()
