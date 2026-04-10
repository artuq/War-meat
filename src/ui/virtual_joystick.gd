## VirtualJoystick — wirtualny joystick do sterowania oddziałem na mobile
class_name VirtualJoystick
extends Control

@export var max_distance: float = 40.0
@export var deadzone: float = 5.0

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _current: Vector2 = Vector2.ZERO


func _ready() -> void:
	_center = size / 2.0
	_current = _center


func _draw() -> void:
	# Baza joysticka
	draw_circle(_center, max_distance, Color(1, 1, 1, 0.15))
	draw_arc(_center, max_distance, 0, TAU, 64, Color(1, 1, 1, 0.3), 2.0)
	# Gałka
	draw_circle(_current, 12.0, Color(1, 1, 1, 0.5))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_update_stick(event.position)
		elif not event.pressed and event.index == _touch_index:
			_reset()
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_stick(event.position)


func get_direction() -> Vector2:
	var diff := _current - _center
	if diff.length() < deadzone:
		return Vector2.ZERO
	return diff.normalized()


func _update_stick(pos: Vector2) -> void:
	var diff := pos - _center
	if diff.length() > max_distance:
		diff = diff.normalized() * max_distance
	_current = _center + diff
	queue_redraw()


func _reset() -> void:
	_touch_index = -1
	_current = _center
	queue_redraw()
