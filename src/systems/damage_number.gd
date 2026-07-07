## DamageNumber — floating damage text (spawned by DamageNumberSpawner)
extends Node2D

var value: int = 0
var is_crit: bool = false
var is_player: bool = false  ## true = damage TO player (red bg)

func _ready() -> void:
	var label := Label.new()
	label.text = str(value)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-20, -10)
	# Support override text (for crate rewards)
	var override_text: String = get_meta("override_text", "")
	if override_text != "":
		label.text = override_text
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		label.add_theme_font_size_override("font_size", 12)
	elif is_player:
		label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		label.add_theme_font_size_override("font_size", 10)
	elif is_crit:
		label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.1))
		label.add_theme_font_size_override("font_size", 14)
		label.text = str(value) + "!"
	else:
		label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3))
		label.add_theme_font_size_override("font_size", 9)

	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)

	# Float up and fade out
	# Tween musi działać w real-time (TWEEN_PROCESS_IDLE), inaczej slow-mo
	# na koniec fali (Engine.time_scale=0.3) sprawia, że liczby "zamarzają"
	# tuż przed cutem do sklepu — QA flag.
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.set_parallel(true)
	var offset_x := randf_range(-8.0, 8.0)
	tween.tween_property(self, "position", position + Vector2(offset_x, -16.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.1)
	tween.chain().tween_callback(queue_free)
