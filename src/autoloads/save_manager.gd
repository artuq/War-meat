## SaveManager — zarządza zapisem stanu mid-run
extends Node

const RUN_SAVE_PATH := "user://warmeat_run.json"


func has_active_run() -> bool:
	if not FileAccess.file_exists(RUN_SAVE_PATH):
		return false
	var data := _load_data()
	return data.get("active", false)


func save_run() -> void:
	var data := {
		"active": true,
		"arena_id": GameManager.current_arena.arena_id if GameManager.current_arena else "jungle",
		"current_wave": GameManager.current_wave,
		"gold": GameManager.gold,
		"xp": GameManager.xp,
		"level": GameManager.level,
		"enemies_killed": GameManager.enemies_killed,
		"gold_earned": GameManager.gold_earned,
		"max_streak": GameManager.max_streak,
		"passive_ids": _get_passive_ids(),
	}
	_save_data(data)


func load_run() -> Dictionary:
	return _load_data()


func clear_run() -> void:
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(RUN_SAVE_PATH)


func _get_passive_ids() -> Array:
	var ids: Array = []
	for p in GameManager.passive_items:
		ids.append(p.id)
	return ids


func _save_data(data: Dictionary) -> void:
	var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func _load_data() -> Dictionary:
	if not FileAccess.file_exists(RUN_SAVE_PATH):
		return {}
	var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}
