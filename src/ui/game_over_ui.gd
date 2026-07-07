## GameOverUI — ekran wygranej/przegranej
extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var stats_label: Label = $Panel/VBoxContainer/StatsLabel
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton


func _ready() -> void:
	visible = false
	restart_button.pressed.connect(_on_restart)
	EventBus.mission_won.connect(_show_win)
	EventBus.squad_wiped.connect(_show_lose)


func _show_win() -> void:
	title_label.text = "🏆 ZWYCIĘSTWO!"
	_unlock_next_arena()
	_show_stats()


func _show_lose() -> void:
	EventBus.mission_lost.emit()
	title_label.text = "💀 PORAŻKA"
	_show_stats()


func _show_stats() -> void:
	var resources_earned: int = 0
	if GameManager.current_arena:
		resources_earned = 10 * GameManager.current_arena.difficulty
	GameManager.resources += resources_earned
	stats_label.text = "Wrogów zabitych: %d\nZłoto zdobyte: $%d\nFala: %d/%d\nSurowce: +%d" % [
		GameManager.enemies_killed,
		GameManager.gold_earned,
		GameManager.current_wave,
		GameManager.total_waves,
		resources_earned,
	]
	visible = true
	get_tree().paused = true


func _unlock_next_arena() -> void:
	if GameManager.current_arena == null:
		return
	var arena_order: Array[String] = ["jungle", "desert", "bunker"]
	var current_id: String = GameManager.current_arena.arena_id
	var idx: int = arena_order.find(current_id)
	if idx >= 0 and idx + 1 < arena_order.size():
		var next_id: String = arena_order[idx + 1]
		if next_id not in GameManager.unlocked_arenas:
			GameManager.unlocked_arenas.append(next_id)


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/hub_screen.tscn")
