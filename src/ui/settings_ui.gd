## SettingsUI — overlay ekranu ustawień
class_name SettingsUI
extends CanvasLayer

signal settings_closed


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Dimmer
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.7)
	dimmer.anchors_preset = Control.PRESET_FULL_RECT
	dimmer.anchor_right = 1.0
	dimmer.anchor_bottom = 1.0
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	# Panel
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -160
	panel.offset_right = 160
	panel.offset_top = -140
	panel.offset_bottom = 140
	var style: StyleBox
	var tex := load("res://assets/sprites/ui/Panel BG.svg") as Texture2D
	if tex:
		var style_tex := StyleBoxTexture.new()
		style_tex.texture = tex
		style_tex.texture_margin_left = 12
		style_tex.texture_margin_top = 12
		style_tex.texture_margin_right = 12
		style_tex.texture_margin_bottom = 12
		style = style_tex
	else:
		var style_flat := StyleBoxFlat.new()
		style_flat.bg_color = Color(0.1, 0.1, 0.12)
		style_flat.border_color = Color(0.3, 0.3, 0.35)
		style_flat.set_border_width_all(2)
		style_flat.set_corner_radius_all(4)
		style_flat.set_content_margin_all(12)
		style = style_flat
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.layout_mode = 2
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "⚙ USTAWIENIA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	# --- Audio ---
	_add_section_header(vbox, "🔊 AUDIO")
	_add_slider(vbox, "Głośność", SettingsManager.master_volume, func(v: float):
		SettingsManager.master_volume = v
		SettingsManager.apply_audio()
	)
	_add_slider(vbox, "SFX", SettingsManager.sfx_volume, func(v: float):
		SettingsManager.sfx_volume = v
		SettingsManager.apply_audio()
	)
	_add_slider(vbox, "Muzyka", SettingsManager.music_volume, func(v: float):
		SettingsManager.music_volume = v
		SettingsManager.apply_audio()
	)

	vbox.add_child(HSeparator.new())

	# --- Gameplay ---
	_add_section_header(vbox, "🎮 ROZGRYWKA")
	_add_toggle(vbox, "Screen Shake", SettingsManager.screen_shake_enabled, func(v: bool):
		SettingsManager.screen_shake_enabled = v
	)
	_add_toggle(vbox, "Damage Numbers", SettingsManager.damage_numbers_enabled, func(v: bool):
		SettingsManager.damage_numbers_enabled = v
	)
	_add_toggle(vbox, "Wibracje", SettingsManager.vibrations_enabled, func(v: bool):
		SettingsManager.vibrations_enabled = v
	)
	_add_slider(vbox, "Czułość joysticka", SettingsManager.joystick_sensitivity, func(v: float):
		SettingsManager.joystick_sensitivity = v
	, 0.5, 2.0)
	_add_slider(vbox, "Deadzone joysticka (px)", SettingsManager.joystick_deadzone, func(v: float):
		SettingsManager.joystick_deadzone = v
	, 4.0, 25.0)

	vbox.add_child(HSeparator.new())

	# --- Performance ---
	_add_section_header(vbox, "⚡ WYDAJNOŚĆ")
	_add_toggle(vbox, "60 FPS", SettingsManager.target_fps == 60, func(v: bool):
		SettingsManager.target_fps = 60 if v else 30
		SettingsManager.apply_fps()
	)
	_add_toggle(vbox, "Tryb baterii", SettingsManager.battery_saver, func(v: bool):
		SettingsManager.set_battery_saver_mode(v)
	)

	vbox.add_child(HSeparator.new())

	# Close button
	var close_btn := Button.new()
	close_btn.text = "ZAMKNIJ"
	close_btn.custom_minimum_size = Vector2(160, 40)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_on_close)
	vbox.add_child(close_btn)


func _add_section_header(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.5))
	parent.add_child(lbl)


func _add_slider(parent: VBoxContainer, label_text: String, initial: float, on_change: Callable, min_val: float = 0.0, max_val: float = 1.0) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.custom_minimum_size = Vector2(80, 0)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = 0.05
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(100, 20)
	slider.value_changed.connect(on_change)
	row.add_child(slider)

	parent.add_child(row)


func _add_toggle(parent: VBoxContainer, label_text: String, initial: bool, on_change: Callable) -> void:
	var row := HBoxContainer.new()

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var toggle := CheckButton.new()
	toggle.button_pressed = initial
	toggle.toggled.connect(on_change)
	row.add_child(toggle)

	parent.add_child(row)


func _on_close() -> void:
	SettingsManager.save_settings()
	settings_closed.emit()
	queue_free()
