## VirtualJoystick — floating joystick (pojawia się w miejscu dotyku)
## Zakrywa lewą połowę ekranu; baza i gałka są niewidoczne aż do pierwszego dotyku.
class_name VirtualJoystick
extends Control

@export var max_distance: float = 40.0
@export var deadzone: float = 12.0  ## px; QA: 5px za mało na dotyk — palec dryfuje

const _MOUSE_IDX := -2  # odróżnia mysz od touch index 0

var _touch_index: int = -1
var _active: bool = false
var _center: Vector2 = Vector2.ZERO
var _current: Vector2 = Vector2.ZERO


func _ready() -> void:
	if get_node_or_null("/root/SettingsManager") != null:
		var sm: Node = get_node("/root/SettingsManager")
		if "joystick_deadzone" in sm:
			deadzone = float(sm.joystick_deadzone)


func _draw() -> void:
	if not _active:
		return
	# Baza
	draw_circle(_center, max_distance, Color(1, 1, 1, 0.15))
	draw_arc(_center, max_distance, 0, TAU, 64, Color(1, 1, 1, 0.3), 2.0)
	# Gałka
	draw_circle(_current, 14.0, Color(1, 1, 1, 0.55))
	draw_arc(_current, 14.0, 0, TAU, 32, Color(1, 1, 1, 0.7), 1.5)


func _gui_input(event: InputEvent) -> void:
	# Touch
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_activate(event.position)
		elif not event.pressed and event.index == _touch_index:
			_reset()
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_stick(event.position)
	# Mysz (testowanie na desktopie)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _touch_index == -1:
			_touch_index = _MOUSE_IDX
			_activate(event.position)
		elif not event.pressed and _touch_index == _MOUSE_IDX:
			_reset()
	elif event is InputEventMouseMotion and _touch_index == _MOUSE_IDX:
		_update_stick(event.position)


func get_direction() -> Vector2:
	if not _active:
		return Vector2.ZERO
	var diff := _current - _center
	if diff.length() < deadzone:
		return Vector2.ZERO
	return diff.normalized()


func _activate(pos: Vector2) -> void:
	_active = true
	_center = pos
	_current = pos
	queue_redraw()


func _update_stick(pos: Vector2) -> void:
	var diff := pos - _center
	if diff.length() > max_distance:
		diff = diff.normalized() * max_distance
	_current = _center + diff
	queue_redraw()


func _reset() -> void:
	_touch_index = -1
	_active = false
	_center = Vector2.ZERO
	_current = Vector2.ZERO
	queue_redraw()
