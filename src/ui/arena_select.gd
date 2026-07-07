## ArenaSelect — tile-based arena picker
extends CanvasLayer

const TILE_FRAME_TEX := preload("res://assets/kenney_ui-pack-space-expansion/PNG/Extra/Default/button_square_depth.png")
const LOCKED_COLOR := Color(0.3, 0.3, 0.3, 0.8)

@onready var tile_row: HBoxContainer = $PanelBG/TileRow
@onready var title_label: Label = $PanelBG/TitleLabel

var _arenas: Array[ArenaModifier] = []


func _ready() -> void:
	_arenas = [
		ArenaModifier.create_jungle(),
		ArenaModifier.create_desert(),
		ArenaModifier.create_bunker(),
	]
	_build_tiles()


func _build_tiles() -> void:
	for child in tile_row.get_children():
		child.queue_free()

	for arena in _arenas:
		var is_unlocked: bool = arena.arena_id in GameManager.unlocked_arenas

		# Outer container: tile + label underneath
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		# Tile button — TextureButton with frame as texture
		var tile := TextureButton.new()
		tile.texture_normal = TILE_FRAME_TEX
		tile.ignore_texture_size = true
		tile.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tile.custom_minimum_size = Vector2(110, 110)
		tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		if is_unlocked:
			tile.pressed.connect(_on_arena_selected.bind(arena))
		else:
			tile.modulate = LOCKED_COLOR
			tile.disabled = true

		# Preview image placeholder inside tile
		var preview := ColorRect.new()
		preview.set_anchors_preset(Control.PRESET_FULL_RECT)
		preview.offset_left = 8.0
		preview.offset_top = 8.0
		preview.offset_right = -8.0
		preview.offset_bottom = -8.0
		preview.color = _arena_preview_color(arena.arena_id)
		tile.add_child(preview)

		# Lock icon overlay
		if not is_unlocked:
			var lock := Label.new()
			lock.text = "🔒"
			lock.set_anchors_preset(Control.PRESET_CENTER)
			lock.add_theme_font_size_override("font_size", 24)
			lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tile.add_child(lock)

		vbox.add_child(tile)

		# Arena name
		var name_label := Label.new()
		name_label.text = arena.arena_name
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(name_label)

		# Difficulty stars
		var stars_label := Label.new()
		stars_label.text = "⭐".repeat(arena.difficulty)
		stars_label.add_theme_font_size_override("font_size", 9)
		stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(stars_label)

		tile_row.add_child(vbox)


func _arena_preview_color(arena_id: String) -> Color:
	## Placeholder colors until real map thumbnails are added
	match arena_id:
		"jungle":
			return Color(0.2, 0.4, 0.15, 0.9)
		"desert":
			return Color(0.6, 0.5, 0.25, 0.9)
		"bunker":
			return Color(0.3, 0.3, 0.35, 0.9)
		_:
			return Color(0.2, 0.2, 0.2, 0.9)


func _on_arena_selected(arena: ArenaModifier) -> void:
	GameManager.current_arena = arena
	get_tree().change_scene_to_file("res://src/maps/arena.tscn")
