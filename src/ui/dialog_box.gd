## DialogBox — prosty system dialogowy (portret + tekst + Dalej)
class_name DialogBox
extends CanvasLayer

signal dialog_finished

@onready var panel: PanelContainer = $Panel
@onready var portrait_label: Label = $Panel/HBoxContainer/PortraitLabel
@onready var text_label: Label = $Panel/HBoxContainer/VBoxContainer/TextLabel
@onready var next_button: Button = $Panel/HBoxContainer/VBoxContainer/NextButton
@onready var skip_button: Button = $Panel/SkipButton

var _lines: Array[Dictionary] = []  # [{"speaker": "...", "text": "..."}]
var _current_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	next_button.pressed.connect(_next_line)
	skip_button.pressed.connect(_skip)


func show_dialog(lines: Array[Dictionary]) -> void:
	if lines.is_empty():
		dialog_finished.emit()
		return
	_lines = lines
	_current_index = 0
	visible = true
	get_tree().paused = true
	_display_current()


func _display_current() -> void:
	if _current_index >= _lines.size():
		_close()
		return
	var line: Dictionary = _lines[_current_index]
	portrait_label.text = line.get("speaker", "???")
	text_label.text = line.get("text", "...")
	if _current_index >= _lines.size() - 1:
		next_button.text = "ZAMKNIJ"
	else:
		next_button.text = "DALEJ ▶"


func _next_line() -> void:
	_current_index += 1
	if _current_index >= _lines.size():
		_close()
	else:
		_display_current()


func _skip() -> void:
	_close()


func _close() -> void:
	visible = false
	get_tree().paused = false
	dialog_finished.emit()
