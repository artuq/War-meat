## ResultsScreen — ekran wyników po misji (animated counting + grade)
class_name ResultsScreen
extends CanvasLayer

var _won: bool = false
var _kills: int = 0
var _gold: int = 0
var _max_streak: int = 0
var _time: float = 0.0
var _wave: int = 0
var _total_waves: int = 5
var _grade: String = "C"

var _kill_label: Label
var _gold_label: Label
var _streak_label: Label
var _time_label: Label
var _score_label: Label
var _grade_label: Label


func setup(won: bool, kills: int, gold: int, max_streak: int, time_secs: float, wave: int, total_waves: int) -> void:
	_won = won
	_kills = kills
	_gold = gold
	_max_streak = max_streak
	_time = time_secs
	_wave = wave
	_total_waves = total_waves
	_calculate_grade()


func _calculate_grade() -> void:
	var score: int = _kills * 10 + _max_streak * 50 + _gold * 5
	if _won and score >= 1500:
		_grade = "S"
	elif _won:
		_grade = "A"
	elif _wave >= 4:
		_grade = "B"
	else:
		_grade = "C"


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	# Dimmer
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.85)
	dimmer.anchors_preset = Control.PRESET_FULL_RECT
	dimmer.anchor_right = 1.0
	dimmer.anchor_bottom = 1.0
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	# Center panel
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -150
	panel.offset_right = 150
	panel.offset_top = -130
	panel.offset_bottom = 130
	var style: StyleBox
	var tex := load("res://assets/sprites/ui/Panel BG.svg") as Texture2D
	if tex:
		var style_tex := StyleBoxTexture.new()
		style_tex.texture = tex
		style_tex.texture_margin_left = 12
		style_tex.texture_margin_top = 12
		style_tex.texture_margin_right = 12
		style_tex.texture_margin_bottom = 12
		style_tex.content_margin_left = 16
		style_tex.content_margin_top = 16
		style_tex.content_margin_right = 16
		style_tex.content_margin_bottom = 16
		style = style_tex
	else:
		var style_flat := StyleBoxFlat.new()
		style_flat.bg_color = Color(0.1, 0.1, 0.12)
		style_flat.border_color = Color(0.3, 0.3, 0.35)
		style_flat.set_border_width_all(2)
		style_flat.set_corner_radius_all(4)
		style_flat.set_content_margin_all(16)
		style = style_flat
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 2
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "MISJA ZAKOŃCZONA" if _won else "MISJA PRZEGRANA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	if _won:
		title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	else:
		title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Stats rows
	_kill_label = _add_stat_row(vbox, "Zabici", "0")
	_gold_label = _add_stat_row(vbox, "Złoto", "$0")
	_streak_label = _add_stat_row(vbox, "Najlepsza seria", "×0")
	_time_label = _add_stat_row(vbox, "Czas", "0:00")
	_score_label = _add_stat_row(vbox, "Wynik", "0")

	# Wave reached
	var wave_lbl := Label.new()
	wave_lbl.text = "Fala: %d/%d" % [_wave, _total_waves]
	wave_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_lbl.add_theme_font_size_override("font_size", 10)
	wave_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(wave_lbl)

	vbox.add_child(HSeparator.new())

	# Grade
	_grade_label = Label.new()
	_grade_label.text = ""
	_grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_grade_label.add_theme_font_size_override("font_size", 32)
	_grade_label.modulate.a = 0.0
	vbox.add_child(_grade_label)

	# Resource gain info
	var resource_gain: int = _gold / 4 if not _won else _gold / 2
	var res_lbl := Label.new()
	res_lbl.text = "+%d surowców" % resource_gain
	res_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	res_lbl.add_theme_font_size_override("font_size", 10)
	res_lbl.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
	vbox.add_child(res_lbl)

	# Continue button
	var btn := Button.new()
	btn.text = "KONTYNUUJ"
	btn.custom_minimum_size = Vector2(160, 40)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(_on_continue.bind(resource_gain))
	vbox.add_child(btn)

	# Animate
	_animate_stats()


func _add_stat_row(parent: VBoxContainer, stat_name: String, initial_value: String) -> Label:
	var row := HBoxContainer.new()

	var name_lbl := Label.new()
	name_lbl.text = stat_name
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)

	var val_lbl := Label.new()
	val_lbl.text = initial_value
	val_lbl.add_theme_font_size_override("font_size", 12)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_lbl)

	parent.add_child(row)
	return val_lbl


func _animate_stats() -> void:
	var score: int = _kills * 10 + _max_streak * 50 + _gold * 5
	var tween := create_tween()

	# Kills count up
	tween.tween_method(func(v: int): _kill_label.text = str(v), 0, _kills, 0.6)
	# Gold count up
	tween.tween_method(func(v: int): _gold_label.text = "$%d" % v, 0, _gold, 0.5)
	# Streak
	tween.tween_method(func(v: int): _streak_label.text = "×%d" % v, 0, _max_streak, 0.3)
	# Time (instant)
	tween.tween_callback(func():
		var secs := int(_time)
		_time_label.text = "%d:%02d" % [secs / 60, secs % 60]
	)
	# Score count up
	tween.tween_method(func(v: int): _score_label.text = str(v), 0, score, 0.6)
	# Grade reveal
	tween.tween_callback(func():
		_grade_label.text = _grade
		var color: Color
		match _grade:
			"S": color = Color(1.0, 0.85, 0.0)
			"A": color = Color(0.3, 1.0, 0.4)
			"B": color = Color(0.4, 0.7, 1.0)
			_: color = Color(0.6, 0.6, 0.6)
		_grade_label.add_theme_color_override("font_color", color)
	)
	tween.tween_property(_grade_label, "modulate:a", 1.0, 0.3)


func _on_continue(resource_gain: int) -> void:
	GameManager.resources += resource_gain
	GameManager.save_game()
	SaveManager.clear_run()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/hub_screen.tscn")
