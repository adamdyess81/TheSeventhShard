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
var battle_reward_summary: Dictionary = {}
var battle_rewards_persisted: bool = false


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
 battle_reward_summary = {}
 battle_rewards_persisted = false


func advance_round() -> void:
 _process_end_of_round_effects()
 _remove_active_round_buffs_from_cards()
 board_state.clear_round_resolve_threshold_modifiers()
 round_number += 1
 player_state.reset_hand_exhaustion()
 player_state.clear_stun()
 player_state.advance_round_buffs()
 shared_deck_state.advance_round_specials()
 _trigger_round_start_boss_specials()
 _apply_active_round_buffs_to_cards()


func refill_board_if_allowed() -> bool:
 if board_state.can_refill():
  advance_round()
  board_state.refill_from_deck(shared_deck_state)
  _apply_active_round_buffs_to_cards()
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


func queue_event(event_type: String, payload: Dictionary = {}) -> void:
 var event := payload.duplicate(true)
 event["type"] = event_type
 pending_round_events.append(event)


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


func should_keep_temporary_gold(outcome: String, reward_profile: Dictionary = {}) -> bool:
 var reward_rule := _get_reward_rule_for_outcome(outcome, reward_profile)
 if reward_rule.is_empty():
  return outcome in ["victory", "survival"]

 return bool(reward_rule.get("keep_temporary_gold", false))


func build_battle_reward_summary(
 outcome: String,
 player_level: int,
 boss_difficulty: String,
 persistent_gold_before: int,
 persistent_gold_awarded: int
) -> Dictionary:
 var chest_carry_state := _build_chest_carry_state()
 var boss_kill := outcome == "victory"
 var boss_id := ""
 var boss_name := ""
 var temporary_gold_collected := 0

 if boss_state != null:
  boss_id = boss_state.boss_id
  boss_name = boss_state.boss_name

 if player_state != null:
  temporary_gold_collected = player_state.temporary_gold

 return {
  "outcome": outcome,
  "boss_kill": boss_kill,
  "boss_id": boss_id,
  "boss_name": boss_name,
  "boss_difficulty": boss_difficulty,
  "player_level": player_level,
  "round_number": round_number,
  "temporary_gold_collected": temporary_gold_collected,
  "persistent_gold_before": persistent_gold_before,
  "persistent_gold_awarded": persistent_gold_awarded,
  "persistent_gold_after": persistent_gold_before + persistent_gold_awarded,
  "chest_carry_state": chest_carry_state
 }


func trigger_boss_on_player_monster_kill(killed_monster = null) -> void:
 if boss_state == null or shared_deck_state == null:
  return

 if not boss_state.has_special_rule("reanimation"):
  return

 _trigger_boss_reanimation("player_monster_kill", killed_monster)


func trigger_boss_special(trigger_reason: String = "", source_card = null) -> void:
 if boss_state == null:
  return

 for special_rule in boss_state.special_rules:
  var key := str(special_rule).strip_edges().to_lower()
  match key:
   "reanimation":
    _trigger_boss_reanimation(trigger_reason, source_card)
   "retaliation":
    _trigger_boss_retaliation(trigger_reason)
   "blight":
    _trigger_boss_blight(trigger_reason, source_card)


func _trigger_boss_reanimation(trigger_reason: String = "", source_card = null) -> void:
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
 queue_event("boss_reanimation", {
  "boss_id": boss_state.boss_id,
  "card_id": reanimated_card.card_id,
  "reason": trigger_reason,
  "source_card_id": _get_source_card_id(source_card)
 })


func trigger_boss_retaliation_on_player_attack() -> int:
 return _trigger_boss_retaliation("player_attacked_boss")


func _trigger_boss_retaliation(trigger_reason: String = "") -> int:
 if boss_state == null or player_state == null:
  return 0

 if not boss_state.has_special_rule("retaliation"):
  return 0

 var retaliation_damage := int(boss_state.get_special_value("retaliation", 0))
 if retaliation_damage <= 0:
  return 0

 player_state.take_damage(retaliation_damage)
 queue_event("boss_retaliation", {
  "boss_id": boss_state.boss_id,
  "damage": retaliation_damage,
  "reason": trigger_reason
 })
 return retaliation_damage


func _trigger_boss_blight(trigger_reason: String = "", source_card = null) -> void:
 if boss_state == null or shared_deck_state == null:
  return

 var blight_card_data = boss_state.get_special_value("blight_card_data", null)
 if not (blight_card_data is Dictionary):
  return

 var blight_data = blight_card_data.duplicate(true)
 if blight_data.is_empty():
  return

 var inserted_card = shared_deck_state.insert_card_at_random(blight_data)
 queue_event("boss_blight", {
  "boss_id": boss_state.boss_id,
  "card_id": inserted_card.card_id,
  "reason": trigger_reason,
  "source_card_id": _get_source_card_id(source_card)
 })


func _get_reward_rule_for_outcome(outcome: String, reward_profile: Dictionary) -> Dictionary:
 if reward_profile.is_empty():
  return {}

 match outcome:
  "victory":
   return reward_profile.get("defeat_victory", {})
  "survival":
   return reward_profile.get("survival_outcome", {})
  "failure":
   return reward_profile.get("failure", {})

 return {}


func _build_chest_carry_state() -> Dictionary:
 var left_hand_card = null
 var right_hand_card = null
 var backpack_chest_ids: Array[String] = []
 var tracked_carried_chest_count := 0

 if player_state != null:
  left_hand_card = player_state.left_hand_card
  right_hand_card = player_state.right_hand_card
  tracked_carried_chest_count = player_state.carried_chests.size()

 var left_hand_chest := _is_chest_card(left_hand_card)
 var right_hand_chest := _is_chest_card(right_hand_card)
 if player_state != null:
  for card in player_state.backpack_cards:
   if _is_chest_card(card):
    backpack_chest_ids.append(_get_card_id(card))

 var total_carried_chest_count := backpack_chest_ids.size()
 if left_hand_chest:
  total_carried_chest_count += 1
 if right_hand_chest:
  total_carried_chest_count += 1

 return {
  "has_carried_chest": left_hand_chest or right_hand_chest or not backpack_chest_ids.is_empty(),
  "left_hand_has_chest": left_hand_chest,
  "right_hand_has_chest": right_hand_chest,
  "backpack_chest_count": backpack_chest_ids.size(),
  "backpack_chest_ids": backpack_chest_ids,
  "tracked_carried_chest_count": tracked_carried_chest_count,
  "total_carried_chest_count": total_carried_chest_count
 }


func _is_chest_card(card) -> bool:
 return _get_card_family(card) == "chest"


func _get_card_id(card) -> String:
 if card is Dictionary:
  return str(card.get("id", ""))
 if card != null and card.has_method("get_name"):
  return str(card.card_id)
 return ""


func _process_end_of_round_effects() -> void:
 if player_state == null:
  return

 var poison_damage := player_state.process_end_of_round_poison()
 if poison_damage > 0:
  queue_event("poison_tick", {
   "damage": poison_damage,
   "remaining_poison": player_state.poison_counters
  })


func _trigger_round_start_boss_specials() -> void:
 if boss_state == null:
  return

 if boss_state.has_special_rule("blight"):
  var blight_interval := int(boss_state.get_special_value("blight_interval", 0))
  if blight_interval > 0 and round_number % blight_interval == 0:
   _trigger_boss_blight("round_start")


func _get_source_card_id(source_card) -> String:
 if source_card is CardRuntimeState:
  return source_card.card_id
 if source_card is Dictionary:
  return str(source_card.get("id", ""))
 return ""


func _apply_active_round_buffs_to_cards() -> void:
 if player_state == null:
  return

 for card in _get_player_owned_cards():
  _apply_round_bonus_to_card(card, "weapon", player_state.active_weapon_bonus, "weapon_round_bonus")
  _apply_round_bonus_to_card(card, "shield", player_state.active_shield_bonus, "shield_round_bonus")


func _remove_active_round_buffs_from_cards() -> void:
 if player_state == null:
  return

 for card in _get_player_owned_cards():
  _clear_round_bonus_from_card(card, "weapon_round_bonus")
  _clear_round_bonus_from_card(card, "shield_round_bonus")


func _get_player_owned_cards() -> Array:
 var cards: Array = []
 if player_state.left_hand_card != null:
  cards.append(player_state.left_hand_card)
 if player_state.right_hand_card != null:
  cards.append(player_state.right_hand_card)
 for backpack_card in player_state.backpack_cards:
  if backpack_card != null:
   cards.append(backpack_card)
 if board_state != null:
  for board_card in board_state.get_active_cards():
   if board_card != null and _is_player_owned_card(board_card):
    cards.append(board_card)
 return cards


func _apply_round_bonus_to_card(card, family: String, bonus: int, state_key: String) -> void:
 if bonus <= 0:
  return
 if _get_card_family(card) != family:
  return
 if not _is_player_owned_card(card):
  return

 var existing_bonus := _get_round_bonus_state(card, state_key)
 if existing_bonus == bonus:
  return

 _adjust_card_runtime_value(card, bonus - existing_bonus)
 _set_round_bonus_state(card, state_key, bonus)


func _clear_round_bonus_from_card(card, state_key: String) -> void:
 var existing_bonus := _get_round_bonus_state(card, state_key)
 if existing_bonus == 0:
  return

 _adjust_card_runtime_value(card, -existing_bonus)
 _set_round_bonus_state(card, state_key, 0)


func _get_round_bonus_state(card, state_key: String) -> int:
 if card is CardRuntimeState:
  return int(card.get_special_state(state_key, 0))
 if card is Dictionary:
  return int(card.get(state_key, 0))
 return 0


func _set_round_bonus_state(card, state_key: String, value: int) -> void:
 if card is CardRuntimeState:
  if value == 0:
   card.special_state.erase(state_key)
  else:
   card.set_special_state(state_key, value)
 elif card is Dictionary:
  if value == 0:
   card.erase(state_key)
  else:
   card[state_key] = value


func _adjust_card_runtime_value(card, delta: int) -> void:
 if delta == 0:
  return
 if card is CardRuntimeState:
  card.current_value += delta
 elif card is Dictionary:
  var current_value := int(card.get("current_value", card.get("base_value", 0)))
  card["current_value"] = current_value + delta


func _get_card_family(card) -> String:
 if card is CardRuntimeState:
  return card.get_family()
 if card is Dictionary:
  return str(card.get("family", ""))
 return ""


func _is_player_owned_card(card) -> bool:
 if card is CardRuntimeState:
  return card.owner_source == "player_deck"
 if card is Dictionary:
  var family := str(card.get("family", ""))
  return family not in ["monster", "coin", "chest"]
 return false
