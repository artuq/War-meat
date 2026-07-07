## SpawnTelegraph — krótka animacja pokazująca gdzie pojawi się wróg
## Daje graczowi ~0.4s na reakcję — fairness + game feel.
## Brotato-clone ref: scenes/effects/enemy_spawn_effect.tscn
class_name SpawnTelegraph
extends Node2D

signal finished

@export var duration: float = 0.4
@export var marker_color: Color = Color(1.0, 0.25, 0.15)

var _t: float = 0.0


func _ready() -> void:
	z_index = 5
	var tween := create_tween()
	tween.tween_method(_set_t, 0.0, 1.0, duration)
	tween.tween_callback(_emit_finished)


func _set_t(v: float) -> void:
	_t = v
	queue_redraw()


func _emit_finished() -> void:
	finished.emit()
	queue_free()


func _draw() -> void:
	# Outer expanding ring — wzrok gracza idzie do miejsca spawnu
	var ring_r: float = lerpf(6.0, 24.0, _t)
	var ring_a: float = (1.0 - _t) * 0.7
	var ring_color := marker_color
	ring_color.a = ring_a
	draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 32, ring_color, 3.0)
	# Migający centralny X — niezostawia wątpliwości że to ostrzeżenie
	var blink: float = sin(_t * TAU * 4.0) * 0.5 + 0.5  # 0..1, szybki pulse
	var x_alpha: float = blink * 0.85 + 0.15
	var x_color := marker_color
	x_color.a = x_alpha
	var cs := 6.0
	draw_line(Vector2(-cs, -cs), Vector2(cs, cs), x_color, 2.0)
	draw_line(Vector2(-cs, cs), Vector2(cs, -cs), x_color, 2.0)
