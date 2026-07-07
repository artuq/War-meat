## ScreenShake — kamera z obsługą screen shake (dodawana jako child Camera2D)
extends Node

var _camera: Camera2D = null
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_timer: float = 0.0
var _original_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	_camera = get_parent() as Camera2D
	if _camera:
		_original_offset = _camera.offset
	EventBus.screen_shake_requested.connect(_on_shake_requested)
	EventBus.enemy_killed_at.connect(_on_enemy_killed)
	EventBus.wave_cleared.connect(_on_wave_cleared)
	EventBus.all_waves_cleared.connect(_on_all_waves_cleared)


func _on_shake_requested(intensity: float, duration: float) -> void:
	if not SettingsManager.screen_shake_enabled:
		return
	if intensity > _shake_intensity:
		_shake_intensity = intensity
		_shake_duration = duration
		_shake_timer = duration


func _on_enemy_killed(_pos: Vector2) -> void:
	_on_shake_requested(1.5, 0.08)


func shake_boss() -> void:
	_on_shake_requested(4.0, 0.25)


func zoom_pulse(amount: float = 0.08, duration: float = 0.3) -> void:
	if not _camera:
		return
	var original_zoom: Vector2 = _camera.zoom
	var target_zoom: Vector2 = original_zoom * (1.0 + amount)
	var tween := create_tween()
	tween.tween_property(_camera, "zoom", target_zoom, duration * 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_camera, "zoom", original_zoom, duration * 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)


func _process(delta: float) -> void:
	if not _camera:
		return
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var progress: float = _shake_timer / _shake_duration
		var current_intensity: float = _shake_intensity * progress
		_camera.offset = _original_offset + Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
	else:
		_camera.offset = _original_offset
		_shake_intensity = 0.0


func _on_wave_cleared(_wave: int) -> void:
	zoom_pulse(0.06, 0.3)


func _on_all_waves_cleared() -> void:
	zoom_pulse(0.12, 0.5)
	shake_boss()
