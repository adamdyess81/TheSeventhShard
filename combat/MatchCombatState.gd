extends RefCounted
class_name MatchCombatState

var player_state: PlayerCombatState
var boss_state: BossCombatState
var board_state: BoardState
var shared_deck_state: SharedDeckState

var round_number: int = 1
var pending_round_events: Array = []
var battle_xp_earned: int = 0
var battle_xp_multiplier: int = 1
var battle_xp_awarded: int = 0
var battle_xp_persisted: bool = false


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
 pending_round_events.clear()
 battle_xp_earned = 0
 battle_xp_multiplier = 1
 battle_xp_awarded = 0
 battle_xp_persisted = false


func advance_round() -> void:
 round_number += 1
 pending_round_events.clear()
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


func consume_pending_round_events() -> Array:
 var events = pending_round_events.duplicate(true)
 pending_round_events.clear()
 return events


func add_battle_xp(amount: int) -> void:
 if amount <= 0:
  return

 battle_xp_earned += amount


func finalize_battle_xp(outcome: String) -> int:
 if battle_xp_awarded > 0:
  return battle_xp_awarded

 if outcome == "survival":
  battle_xp_multiplier = 3
 elif outcome == "victory":
  battle_xp_multiplier = 2
 else:
  battle_xp_multiplier = 1

 battle_xp_awarded = battle_xp_earned * battle_xp_multiplier
 return battle_xp_awarded


func trigger_boss_on_player_monster_kill() -> void:
 if boss_state == null or shared_deck_state == null:
  return

 if not boss_state.has_special_rule("summon"):
  return

 var summon_card_data = boss_state.get_special_value("summon_card_data", null)
 if not (summon_card_data is Dictionary):
  return

 var summon_data = summon_card_data.duplicate(true)
 if summon_data.is_empty():
  return

 var summon_value = boss_state.get_special_value("summon_value", null)
 if summon_value != null:
  summon_data["base_value"] = int(summon_value)

 var summon_rush = int(boss_state.get_special_value("summon_rush", 0))
 if summon_rush > 0:
  var special_rules = summon_data.get("special_rules", [])
  if not (special_rules is Array):
   special_rules = []
  if "rush" not in special_rules:
   special_rules.append("rush")
  summon_data["special_rules"] = special_rules

  var special_values = summon_data.get("special_values", {})
  if not (special_values is Dictionary):
   special_values = {}
  special_values["rush"] = summon_rush
  summon_data["special_values"] = special_values

 var summoned_card = shared_deck_state.insert_card_at_random(summon_data)
 pending_round_events.append({
  "type": "boss_summon",
  "boss_id": boss_state.boss_id,
  "card_id": summoned_card.card_id
 })
