## ArenaNarrative — narratywny pipeline areny (briefing → walka → boss dialog → results)
class_name ArenaNarrative
extends Node

signal briefing_done
signal boss_dialog_done

@export var arena_id: String = "jungle"

var _dialog_box_scene: PackedScene = preload("res://src/ui/dialog_box.tscn")
var _cutscene_scene: PackedScene   = preload("res://src/ui/cutscene_player.tscn")
var _dialog_box: DialogBox = null
var _cutscene: CutscenePlayer = null

# Cutscenki do których wyzwalaczy jeszcze nie pokazano
var _shown_cutscenes: Array[String] = []


func _ready() -> void:
	# Podłącz trigger po fali 2
	EventBus.wave_started.connect(_on_wave_started)


func _on_wave_started(wave_number: int) -> void:
	if wave_number == 3 and not "after_wave_2" in _shown_cutscenes:
		_shown_cutscenes.append("after_wave_2")
		await get_tree().create_timer(1.0).timeout
		play_cutscene("after_wave_2")
	elif wave_number == 9 and not "after_wave_8" in _shown_cutscenes:
		_shown_cutscenes.append("after_wave_8")
		await get_tree().create_timer(1.0).timeout
		play_cutscene("after_wave_8")
	elif arena_id == "bunker" and wave_number == GameManager.total_waves \
			and not "before_boss_bunker" in _shown_cutscenes:
		_shown_cutscenes.append("before_boss_bunker")
		await get_tree().create_timer(1.0).timeout
		play_cutscene("before_boss_bunker")


# ── Cutsceny ─────────────────────────────────────────────────────────────────

func play_cutscene(id: String) -> void:
	var data := NarrativeData.get_cutscene(id)
	if data.is_empty():
		return
	_cutscene = _cutscene_scene.instantiate()
	get_parent().add_child(_cutscene)
	_cutscene.finished.connect(_on_cutscene_done.bind(id))
	_cutscene.play(data.get("lines", []), data.get("image", ""))


func _on_cutscene_done(_id: String) -> void:
	if _cutscene:
		_cutscene.queue_free()
		_cutscene = null


# ── Briefing ─────────────────────────────────────────────────────────────────

func show_briefing() -> void:
	# Intro cutscenka tylko przy pierwszej arenie (dżungla)
	if arena_id == "jungle" and not "intro" in _shown_cutscenes:
		_shown_cutscenes.append("intro")
		var data := NarrativeData.get_cutscene("intro")
		_cutscene = _cutscene_scene.instantiate()
		get_parent().add_child(_cutscene)
		_cutscene.finished.connect(_on_intro_done)
		_cutscene.play(data.get("lines", []), data.get("image", ""))
		return

	_start_briefing_dialog()


func _on_intro_done() -> void:
	if _cutscene:
		_cutscene.queue_free()
		_cutscene = null
	_start_briefing_dialog()


func _start_briefing_dialog() -> void:
	var lines: Array[Dictionary] = NarrativeData.get_briefing(arena_id)
	if lines.is_empty():
		briefing_done.emit()
		return
	_dialog_box = _dialog_box_scene.instantiate()
	get_parent().add_child(_dialog_box)
	_dialog_box.dialog_finished.connect(_on_briefing_done)
	_dialog_box.show_dialog(lines)


func _on_briefing_done() -> void:
	_close_dialog()
	briefing_done.emit()


# ── Boss dialog ───────────────────────────────────────────────────────────────

func show_boss_dialog() -> void:
	var cutscene_id := ""
	if arena_id == "jungle" and not "after_boss_jungle" in _shown_cutscenes:
		cutscene_id = "after_boss_jungle"
	elif arena_id == "desert" and not "after_boss_desert" in _shown_cutscenes:
		cutscene_id = "after_boss_desert"
	elif arena_id == "bunker" and not "victory" in _shown_cutscenes:
		cutscene_id = "victory"

	if cutscene_id != "":
		_shown_cutscenes.append(cutscene_id)
		var data := NarrativeData.get_cutscene(cutscene_id)
		_cutscene = _cutscene_scene.instantiate()
		get_parent().add_child(_cutscene)
		_cutscene.finished.connect(_on_boss_cutscene_done)
		_cutscene.play(data.get("lines", []), data.get("image", ""))
		return

	_start_boss_dialog()


func _on_boss_cutscene_done() -> void:
	if _cutscene:
		_cutscene.queue_free()
		_cutscene = null
	_start_boss_dialog()


func _start_boss_dialog() -> void:
	var lines: Array[Dictionary] = NarrativeData.get_boss_dialog(arena_id)
	if lines.is_empty():
		boss_dialog_done.emit()
		return
	_dialog_box = _dialog_box_scene.instantiate()
	get_parent().add_child(_dialog_box)
	_dialog_box.dialog_finished.connect(_on_boss_dialog_done)
	_dialog_box.show_dialog(lines)


func _on_boss_dialog_done() -> void:
	_close_dialog()
	boss_dialog_done.emit()


# ── Results ───────────────────────────────────────────────────────────────────

func show_results(won: bool) -> void:
	var rs := ResultsScreen.new()
	rs.setup(won, GameManager.enemies_killed, GameManager.gold_earned,
		GameManager.max_streak, GameManager.mission_time,
		GameManager.current_wave, GameManager.total_waves)
	get_parent().add_child(rs)


func _close_dialog() -> void:
	if _dialog_box:
		_dialog_box.queue_free()
		_dialog_box = null
