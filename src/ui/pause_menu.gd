## PauseMenu — overlay shown when pause button pressed
extends CanvasLayer

@onready var resume_btn: Button = $Panel/VBox/ResumeButton
@onready var restart_btn: Button = $Panel/VBox/RestartButton
@onready var quit_btn: Button = $Panel/VBox/QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	quit_btn.pressed.connect(_on_quit)
	# Add Settings button (between Restart and Quit)
	var settings_btn := Button.new()
	settings_btn.text = "⚙ USTAWIENIA"
	settings_btn.custom_minimum_size = Vector2(160, 48)
	settings_btn.add_theme_font_size_override("font_size", 14)
	settings_btn.pressed.connect(_on_settings)
	var vbox: VBoxContainer = $Panel/VBox
	vbox.add_child(settings_btn)
	vbox.move_child(settings_btn, quit_btn.get_index())


func _on_resume() -> void:
	get_tree().paused = false
	queue_free()


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")


func _on_settings() -> void:
	var ui := SettingsUI.new()
	add_child(ui)
