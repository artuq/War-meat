## HitStop — krótkie freeze-frame przy zabójstwie wroga
extends Node

var _is_stopping: bool = false


func _ready() -> void:
	EventBus.enemy_killed_at.connect(_on_enemy_killed)


func _on_enemy_killed(_pos: Vector2) -> void:
	if _is_stopping:
		return
	_do_hitstop(0.04)


func hitstop_boss() -> void:
	_do_hitstop(0.12)


func _do_hitstop(duration: float) -> void:
	_is_stopping = true
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_is_stopping = false
