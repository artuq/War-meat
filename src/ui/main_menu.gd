## MainMenu — ekran startowy
extends CanvasLayer

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var start_button: TextureButton = $Panel/VBoxContainer/StartButton
@onready var fade: ColorRect = $Fade

var _transitioning := false
var _continue_button: Button = null
var _settings_button: Button = null
var _confirm_popup: Control = null


func _ready() -> void:
	start_button.pressed.connect(_on_start)
	start_button.button_down.connect(_on_button_down)
	start_button.button_up.connect(_on_button_up)

	# Add Continue button
	var vbox: VBoxContainer = $Panel/VBoxContainer
	_continue_button = Button.new()
	_continue_button.text = "KONTYNUUJ MISJĘ"
	_continue_button.custom_minimum_size = Vector2(200, 36)
	_continue_button.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_continue_button)
	vbox.move_child(_continue_button, start_button.get_index() + 1)
	_continue_button.pressed.connect(_on_continue)

	if not SaveManager.has_active_run():
		_continue_button.disabled = true
		_continue_button.modulate.a = 0.5

	# Add Settings button
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	_settings_button = Button.new()
	_settings_button.text = "⚙ USTAWIENIA"
	_settings_button.custom_minimum_size = Vector2(200, 32)
	_settings_button.add_theme_font_size_override("font_size", 12)
	_settings_button.pressed.connect(_on_settings)
	vbox.add_child(_settings_button)

	# Fade in on scene load
	fade.color = Color(0, 0, 0, 1)
	var intro := create_tween()
	intro.tween_property(fade, "color:a", 0.0, 0.4)
	# Menu music
	SoundManager.play_music("menu")


func _on_button_down() -> void:
	if _transitioning:
		return
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(start_button, "scale", Vector2(0.93, 0.93), 0.08)


func _on_button_up() -> void:
	if _transitioning:
		return
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.25)


func _on_start() -> void:
	if _transitioning:
		return
	# Check if active run exists — confirm overwrite
	if SaveManager.has_active_run():
		_show_confirm_popup()
		return
	_do_start_transition()


func _do_start_transition() -> void:
	_transitioning = true
	start_button.disabled = true

	# Button shrink + title slide up + fade to black
	var tween := create_tween().set_parallel(true)
	tween.tween_property(start_button, "scale", Vector2(1.05, 1.05), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(start_button, "modulate:a", 0.0, 0.3).set_delay(0.1)
	tween.tween_property(title_label, "position:y", title_label.position.y - 30, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(title_label, "modulate:a", 0.0, 0.3).set_delay(0.1)
	tween.tween_property(fade, "color:a", 1.0, 0.35).set_delay(0.15)
	tween.chain().tween_callback(_go_to_hub)


func _on_continue() -> void:
	if _transitioning:
		return
	_transitioning = true
	# Load run state
	var data := SaveManager.load_run()
	GameManager.restoring_run = true
	GameManager.run_data = data
	# Set arena
	var arena_id: String = data.get("arena_id", "jungle")
	match arena_id:
		"jungle": GameManager.current_arena = ArenaModifier.create_jungle()
		"desert": GameManager.current_arena = ArenaModifier.create_desert()
		"bunker": GameManager.current_arena = ArenaModifier.create_bunker()
	# Fade and go to arena
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.35)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://src/maps/arena.tscn")
	)


func _on_settings() -> void:
	var ui := SettingsUI.new()
	add_child(ui)


func _show_confirm_popup() -> void:
	if _confirm_popup:
		return
	_confirm_popup = PanelContainer.new()
	_confirm_popup.anchor_left = 0.5
	_confirm_popup.anchor_right = 0.5
	_confirm_popup.anchor_top = 0.5
	_confirm_popup.anchor_bottom = 0.5
	_confirm_popup.offset_left = -140
	_confirm_popup.offset_right = 140
	_confirm_popup.offset_top = -60
	_confirm_popup.offset_bottom = 60
	var style: StyleBox
	var tex := load("res://assets/sprites/ui/Panel BG.svg") as Texture2D
	if tex:
		var style_tex := StyleBoxTexture.new()
		style_tex.texture = tex
		style_tex.texture_margin_left = 12
		style_tex.texture_margin_top = 12
		style_tex.texture_margin_right = 12
		style_tex.texture_margin_bottom = 12
		style_tex.content_margin_left = 12
		style_tex.content_margin_top = 12
		style_tex.content_margin_right = 12
		style_tex.content_margin_bottom = 12
		style = style_tex
	else:
		var style_flat := StyleBoxFlat.new()
		style_flat.bg_color = Color(0.12, 0.1, 0.1)
		style_flat.border_color = Color(1.0, 0.4, 0.2)
		style_flat.set_border_width_all(2)
		style_flat.set_corner_radius_all(4)
		style_flat.set_content_margin_all(12)
		style = style_flat
	_confirm_popup.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 2
	vbox.add_theme_constant_override("separation", 8)
	_confirm_popup.add_child(vbox)

	var msg := Label.new()
	msg.text = "Masz niezakończoną misję.\nRozpoczęcie nowej nadpisze\npostępy. Jesteś pewien?"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 11)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(msg)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var yes_btn := Button.new()
	yes_btn.text = "TAK"
	yes_btn.custom_minimum_size = Vector2(80, 32)
	yes_btn.pressed.connect(func():
		_confirm_popup.queue_free()
		_confirm_popup = null
		SaveManager.clear_run()
		_do_start_transition()
	)
	btn_row.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = "NIE"
	no_btn.custom_minimum_size = Vector2(80, 32)
	no_btn.pressed.connect(func():
		_confirm_popup.queue_free()
		_confirm_popup = null
	)
	btn_row.add_child(no_btn)

	add_child(_confirm_popup)


func _go_to_hub() -> void:
	get_tree().change_scene_to_file("res://src/ui/hub_screen.tscn")
