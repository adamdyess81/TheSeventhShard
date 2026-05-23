extends RefCounted
class_name RunContext

const DEFAULT_BOSS_ID := "ossaran_lich"
const DEFAULT_MONSTER_DECK_ID := "ossaran_lich_deck"

static var selected_boss_id: String = DEFAULT_BOSS_ID
static var selected_monster_deck_id: String = DEFAULT_MONSTER_DECK_ID


static func set_battle_selection(boss_id: String, monster_deck_id: String) -> void:
	selected_boss_id = boss_id.strip_edges()
	selected_monster_deck_id = monster_deck_id.strip_edges()

	if selected_boss_id == "":
		selected_boss_id = DEFAULT_BOSS_ID
	if selected_monster_deck_id == "":
		selected_monster_deck_id = DEFAULT_MONSTER_DECK_ID


static func get_battle_selection() -> Dictionary:
	return {
		"boss_id": selected_boss_id,
		"monster_deck_id": selected_monster_deck_id
	}
