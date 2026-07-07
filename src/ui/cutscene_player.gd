## CutscenePlayer — pełnoekranowe cutscenki z napisami kinowymi
## Użycie: CutscenePlayer.play(lines, image_path) → emituje finished po zakończeniu
class_name CutscenePlayer
extends CanvasLayer

signal finished

# Jedna linia cutscenki
# { "text": "...", "speaker": "NAZWA" (opcjonalnie), "duration": 3.0 (opcjonalnie) }

const TYPEWRITER_SPEED := 0.03   # sekundy na znak
const DEFAULT_LINE_DURATION := 4.0

@onready var _image: TextureRect    = $CutsceneImage
@onready var _speaker_label: Label  = $SubtitleBar/VBox/SpeakerLabel
@onready var _text_label: Label     = $SubtitleBar/VBox/TextLabel
@onready var _hint_label: Label     = $SubtitleBar/HintLabel
@onready var _fade: ColorRect       = $FadeRect

var _lines: Array = []
var _current: int = 0
var _full_text: String = ""
var _typewriter_timer: float = 0.0
var _char_index: int = 0
var _typing: bool = false
var _auto_timer: float = 0.0
var _auto_advance: bool = false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func play(lines: Array, image_path: String = "") -> void:
	if lines.is_empty():
		finished.emit()
		return
	_lines = lines
	_current = 0
	visible = true
	get_tree().paused = true

	# Ścisz muzykę gry podczas cutscenki
	SoundManager.fade_music_volume(-48.0, 0.5)

	# Załaduj obraz cutscenki
	if image_path != "" and ResourceLoader.exists(image_path):
		_image.texture = load(image_path) as Texture2D
		_image.visible = true
	else:
		_image.visible = false

	# Fade in
	_fade.modulate.a = 1.0
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 0.0, 0.5)
	await t.finished
	_show_line()


func _show_line() -> void:
	if _current >= _lines.size():
		_finish()
		return

	var line: Dictionary = _lines[_current]
	var speaker: String = line.get("speaker", "")
	_full_text = line.get("text", "")
	_auto_advance = line.has("duration")
	_auto_timer = line.get("duration", DEFAULT_LINE_DURATION)

	# Audio triggers
	var sfx: String = line.get("sfx", "")
	var music: String = line.get("music", "")
	if sfx != "":
		SoundManager.play_cutscene_sfx(sfx)
	if music != "":
		SoundManager.play_cutscene_music(music)

	_speaker_label.text = speaker
	_speaker_label.visible = speaker != ""
	_text_label.text = ""
	_hint_label.text = "▶ dotknij" if not _auto_advance else ""

	_char_index = 0
	_typewriter_timer = 0.0
	_typing = true


func _process(delta: float) -> void:
	if not visible:
		return

	# Typewriter
	if _typing:
		_typewriter_timer += delta
		while _typewriter_timer >= TYPEWRITER_SPEED and _char_index < _full_text.length():
			_typewriter_timer -= TYPEWRITER_SPEED
			_char_index += 1
			_text_label.text = _full_text.substr(0, _char_index)
		if _char_index >= _full_text.length():
			_typing = false
			_text_label.text = _full_text

	# Auto-advance po duration
	if not _typing and _auto_advance:
		_auto_timer -= delta
		if _auto_timer <= 0.0:
			_advance()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var tapped: bool = false
	if event is InputEventScreenTouch and event.pressed:
		tapped = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped = true
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]:
		tapped = true
	if not tapped:
		return

	if _typing:
		# Pokaż cały tekst od razu
		_char_index = _full_text.length()
		_text_label.text = _full_text
		_typing = false
	else:
		_advance()


func _advance() -> void:
	_current += 1
	if _current >= _lines.size():
		_finish()
	else:
		_show_line()


func _finish() -> void:
	SoundManager.stop_cutscene_audio(0.4)
	# Przywróć głośność muzyki gry
	SoundManager.fade_music_volume(-6.0, 0.8)
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 1.0, 0.4)
	await t.finished
	visible = false
	get_tree().paused = false
	_image.texture = null
	finished.emit()
