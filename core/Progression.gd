extends RefCounted
class_name Progression

const LEVEL_1_XP_TO_NEXT := 20
const EARLY_LEVEL_CAP := 10
const MID_LEVEL_CAP := 25
const LATE_LEVEL_CAP := 40
const EARLY_LEVEL_GROWTH := 1.22
const MID_LEVEL_GROWTH := 1.14
const LATE_LEVEL_GROWTH := 1.12
const ENDGAME_LEVEL_GROWTH := 1.10


static func calculate_level_from_total_xp(total_xp: int) -> int:
	if total_xp <= 0:
		return 1

	var level: int = 1
	var remaining_xp: int = total_xp
	var xp_to_next: int = LEVEL_1_XP_TO_NEXT

	while remaining_xp >= xp_to_next:
		remaining_xp -= xp_to_next
		level += 1
		xp_to_next = get_xp_to_next_level(level)

	return level


static func get_xp_to_next_level(level: int) -> int:
	if level <= 1:
		return LEVEL_1_XP_TO_NEXT

	var xp_to_next: int = LEVEL_1_XP_TO_NEXT

	for current_level in range(1, level):
		var growth: float = get_level_growth_multiplier(current_level)
		xp_to_next = int(ceil(float(xp_to_next) * growth))

	return xp_to_next


static func get_level_growth_multiplier(level: int) -> float:
	if level < EARLY_LEVEL_CAP:
		return EARLY_LEVEL_GROWTH
	if level < MID_LEVEL_CAP:
		return MID_LEVEL_GROWTH
	if level < LATE_LEVEL_CAP:
		return LATE_LEVEL_GROWTH
	return ENDGAME_LEVEL_GROWTH


static func get_current_level_progress(total_xp: int) -> Dictionary:
	var level: int = 1
	var remaining_xp: int = max(total_xp, 0)
	var xp_to_next: int = LEVEL_1_XP_TO_NEXT

	while remaining_xp >= xp_to_next:
		remaining_xp -= xp_to_next
		level += 1
		xp_to_next = get_xp_to_next_level(level)

	return {
		"level": level,
		"xp_into_level": remaining_xp,
		"xp_to_next_level": xp_to_next
	}
