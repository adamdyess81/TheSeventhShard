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

 if not boss_state.has_special_rule("reanimation"):
  return

 var reanimation_card_data = boss_state.get_special_value("reanimation_card_data", null)
 if not (reanimation_card_data is Dictionary):
  return

 var reanimation_data = reanimation_card_data.duplicate(true)
 if reanimation_data.is_empty():
  return

 var reanimation_value = boss_state.get_special_value("reanimation_value", null)
 if reanimation_value != null:
  reanimation_data["base_value"] = int(reanimation_value)

 var reanimation_rush = int(boss_state.get_special_value("reanimation_rush", 0))
 if reanimation_rush > 0:
  var special_rules = reanimation_data.get("special_rules", [])
  if not (special_rules is Array):
   special_rules = []
  if "rush" not in special_rules:
   special_rules.append("rush")
  reanimation_data["special_rules"] = special_rules

  var special_values = reanimation_data.get("special_values", {})
  if not (special_values is Dictionary):
   special_values = {}
  special_values["rush"] = reanimation_rush
  reanimation_data["special_values"] = special_values

 var reanimated_card = shared_deck_state.insert_card_at_random(reanimation_data)
 pending_round_events.append({
  "type": "boss_reanimation",
  "boss_id": boss_state.boss_id,
  "card_id": reanimated_card.card_id
 })


func trigger_boss_retaliation_on_player_attack() -> int:
 if boss_state == null or player_state == null:
  return 0

 if not boss_state.has_special_rule("retaliation"):
  return 0

 var retaliation_damage := int(boss_state.get_special_value("retaliation", 0))
 if retaliation_damage <= 0:
  return 0

 player_state.take_damage(retaliation_damage)
 pending_round_events.append({
  "type": "boss_retaliation",
  "boss_id": boss_state.boss_id,
  "damage": retaliation_damage
 })
 return retaliation_damage
