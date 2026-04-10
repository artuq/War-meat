## MainMenu — ekran startowy
extends CanvasLayer

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var start_button: Button = $Panel/VBoxContainer/StartButton


func _ready() -> void:
	start_button.pressed.connect(_on_start)


func _on_start() -> void:
	get_tree().change_scene_to_file("res://src/ui/hub_screen.tscn")
