## DebrisLayer — single Node2D rysujący tło z 300 ColorRect-ów w jednym _draw().
## Eliminuje 300 instancji ColorRect z drzewa sceny → mniej node'ów, czystsza struktura.
## Pre-generuje pozycje i kolory raz, draw je za każdym razem (cache GPU).
class_name DebrisLayer
extends Node2D

const _DEFAULT_COLORS: Array[Color] = [
	Color(0.42, 0.42, 0.38),
	Color(0.48, 0.46, 0.40),
	Color(0.38, 0.36, 0.33),
	Color(0.50, 0.48, 0.44),
]

var _debris: Array = []  # [{pos, size, color, rotation}, ...]


func generate(arena_size: Vector2, count: int = 300, colors: Array = []) -> void:
	_debris.clear()
	var palette: Array = colors if colors.size() > 0 else _DEFAULT_COLORS
	var half := arena_size / 2.0
	for i in count:
		var size_val := randf_range(2.0, 6.0)
		_debris.append({
			"pos": Vector2(
				randf_range(-half.x + 40, half.x - 40),
				randf_range(-half.y + 40, half.y - 40)
			),
			"size": Vector2(size_val, size_val * randf_range(0.6, 1.4)),
			"color": palette[randi() % palette.size()],
			"rotation": randf_range(0, TAU),
		})
	z_index = -9
	queue_redraw()


func _draw() -> void:
	for d in _debris:
		# Rotated rect — emulujemy `rotation` per-rect przez transformę manualną
		var pos: Vector2 = d["pos"]
		var sz: Vector2 = d["size"]
		var rot: float = d["rotation"]
		var col: Color = d["color"]
		# Transform local: translate to pos, rotate, draw centered rect
		draw_set_transform(pos, rot, Vector2.ONE)
		draw_rect(Rect2(-sz / 2.0, sz), col)
	# Reset transform
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
