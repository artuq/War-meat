## ArenaSelect — ekran wyboru areny
extends CanvasLayer

@onready var arena_list: VBoxContainer = $Panel/VBoxContainer/ArenaList
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel

var _arenas: Array[ArenaModifier] = []


func _ready() -> void:
	_arenas = [
		ArenaModifier.create_jungle(),
		ArenaModifier.create_desert(),
		ArenaModifier.create_bunker(),
	]
	_build_list()


func _build_list() -> void:
	for child in arena_list.get_children():
		child.queue_free()

	for arena in _arenas:
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Info column
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label := Label.new()
		var stars := "⭐".repeat(arena.difficulty)
		name_label.text = "%s  %s" % [arena.arena_name, stars]
		name_label.add_theme_font_size_override("font_size", 14)
		info.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = arena.description
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info.add_child(desc_label)

		hbox.add_child(info)

		# Button
		var btn := Button.new()
		var is_unlocked: bool = arena.arena_id in GameManager.unlocked_arenas
		if is_unlocked:
			btn.text = "WALCZ"
			btn.pressed.connect(_on_arena_selected.bind(arena))
		else:
			btn.text = "🔒"
			btn.disabled = true
		btn.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(btn)

		arena_list.add_child(hbox)

		# Separator
		var sep := HSeparator.new()
		arena_list.add_child(sep)


func _on_arena_selected(arena: ArenaModifier) -> void:
	GameManager.current_arena = arena
	get_tree().change_scene_to_file("res://src/maps/arena.tscn")
