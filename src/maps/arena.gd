## ArenaMap — dynamicznie generowana arena (Brotato-style)
class_name ArenaMap
extends Node2D

@export var arena_size: Vector2 = Vector2(2500, 1500)

var modifier: ArenaModifier = null

@onready var squad: Squad = $Squad
@onready var wave_manager: Node = $WaveManager
@onready var camera: Camera2D = $Squad/Camera2D

var _dialog_box_scene: PackedScene = preload("res://src/ui/dialog_box.tscn")
var _dialog_box: DialogBox = null


func _ready() -> void:
	if modifier == null:
		modifier = GameManager.current_arena
	if modifier:
		arena_size = modifier.arena_size
	_create_floor()
	_create_debris()
	_create_boundaries()
	if modifier and modifier.has_exploding_barrels:
		_create_barrels()
	GameManager.start_mission(wave_manager.total_waves)
	wave_manager.setup(self)
	if modifier:
		wave_manager.set_modifier(modifier)
	# Apply player speed modifier
	if modifier and modifier.player_speed_mult != 1.0:
		for s in get_tree().get_nodes_in_group("squad"):
			if s is Soldier:
				s.move_speed *= modifier.player_speed_mult
	# Show briefing before starting waves
	_show_briefing()
	# Connect boss dialog
	EventBus.all_waves_cleared.connect(_on_all_waves_cleared)


func _create_floor() -> void:
	var floor_color: Color = modifier.floor_color if modifier else Color(0.55, 0.55, 0.50)
	var floor_rect := ColorRect.new()
	floor_rect.color = floor_color
	floor_rect.position = -arena_size / 2.0
	floor_rect.size = arena_size
	floor_rect.z_index = -10
	add_child(floor_rect)


func _create_debris() -> void:
	var half := arena_size / 2.0
	var debris_count: int = modifier.debris_count if modifier else 300
	var debris_colors: Array = []
	if modifier and not modifier.debris_colors.is_empty():
		debris_colors = modifier.debris_colors
	else:
		debris_colors = [
			Color(0.42, 0.42, 0.38),
			Color(0.48, 0.46, 0.40),
			Color(0.38, 0.36, 0.33),
			Color(0.50, 0.48, 0.44),
		]
	for i in debris_count:
		var debris := ColorRect.new()
		var size_val := randf_range(2.0, 6.0)
		debris.size = Vector2(size_val, size_val * randf_range(0.6, 1.4))
		debris.color = debris_colors[randi() % debris_colors.size()]
		debris.position = Vector2(
			randf_range(-half.x + 40, half.x - 40),
			randf_range(-half.y + 40, half.y - 40)
		)
		debris.z_index = -9
		debris.rotation = randf_range(0, TAU)
		add_child(debris)


func _create_boundaries() -> void:
	var half := arena_size / 2.0
	var wall_color: Color = modifier.wall_color if modifier else Color(0.3, 0.3, 0.3)
	var walls_data := [
		{"pos": Vector2(0, -half.y), "size": Vector2(arena_size.x + 64, 32)},  # top
		{"pos": Vector2(0, half.y),  "size": Vector2(arena_size.x + 64, 32)},  # bottom
		{"pos": Vector2(-half.x, 0), "size": Vector2(32, arena_size.y + 64)},  # left
		{"pos": Vector2(half.x, 0),  "size": Vector2(32, arena_size.y + 64)},  # right
	]
	for data in walls_data:
		var body := StaticBody2D.new()
		body.position = data["pos"]
		body.collision_layer = 16
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = data["size"]
		shape.shape = rect
		body.add_child(shape)
		# Visual
		var vis := ColorRect.new()
		vis.color = wall_color
		vis.size = data["size"]
		vis.position = -data["size"] / 2.0
		body.add_child(vis)
		add_child(body)


func get_edge_spawn_position() -> Vector2:
	var half := arena_size / 2.0
	var margin := 40.0
	var side := randi() % 4
	match side:
		0: return Vector2(randf_range(-half.x + margin, half.x - margin), -half.y + margin)
		1: return Vector2(randf_range(-half.x + margin, half.x - margin), half.y - margin)
		2: return Vector2(-half.x + margin, randf_range(-half.y + margin, half.y - margin))
		3: return Vector2(half.x - margin, randf_range(-half.y + margin, half.y - margin))
	return Vector2.ZERO


func get_random_spawn_position() -> Vector2:
	var half := arena_size / 2.0
	var margin := 80.0
	return Vector2(
		randf_range(-half.x + margin, half.x - margin),
		randf_range(-half.y + margin, half.y - margin)
	)


func _create_barrels() -> void:
	var half := arena_size / 2.0
	var count: int = modifier.barrel_count if modifier else 0
	for i in count:
		var barrel := Area2D.new()
		barrel.collision_layer = 0
		barrel.collision_mask = 4  # projectiles
		barrel.position = Vector2(
			randf_range(-half.x + 80, half.x - 80),
			randf_range(-half.y + 80, half.y - 80)
		)
		barrel.add_to_group("barrels")
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 12.0
		shape.shape = circle
		barrel.add_child(shape)
		barrel.area_entered.connect(_on_barrel_hit.bind(barrel))
		barrel.body_entered.connect(_on_barrel_hit_body.bind(barrel))
		add_child(barrel)
		barrel.set_meta("alive", true)
		# Visual — red/orange barrel
		var vis := _BarrelVisual.new()
		barrel.add_child(vis)


func _on_barrel_hit(_area: Area2D, barrel: Area2D) -> void:
	_explode_barrel(barrel)


func _on_barrel_hit_body(_body: Node2D, barrel: Area2D) -> void:
	_explode_barrel(barrel)


func _explode_barrel(barrel: Area2D) -> void:
	if not barrel.get_meta("alive", false):
		return
	barrel.set_meta("alive", false)
	# Damage nearby enemies
	var explosion_radius := 60.0
	var explosion_damage := 30
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy is Enemy:
			if barrel.global_position.distance_to(enemy.global_position) < explosion_radius:
				enemy.take_damage(explosion_damage)
	# Damage nearby soldiers
	for s in get_tree().get_nodes_in_group("squad"):
		if is_instance_valid(s) and s is Soldier:
			if barrel.global_position.distance_to(s.global_position) < explosion_radius:
				s.take_damage(15)
	barrel.queue_free()


## Simple barrel visual (red circle with orange outline)
class _BarrelVisual extends Node2D:
	func _draw() -> void:
		draw_circle(Vector2.ZERO, 12.0, Color(0.7, 0.2, 0.1))
		draw_circle(Vector2.ZERO, 8.0, Color(0.9, 0.4, 0.1))
		draw_circle(Vector2.ZERO, 3.0, Color(0.2, 0.2, 0.2))


# --- Narracja ---

func _show_briefing() -> void:
	var arena_id: String = modifier.arena_id if modifier else "jungle"
	var lines: Array[Dictionary] = NarrativeData.get_briefing(arena_id)
	if lines.is_empty():
		wave_manager.start()
		return
	_dialog_box = _dialog_box_scene.instantiate()
	add_child(_dialog_box)
	_dialog_box.dialog_finished.connect(_on_briefing_done)
	_dialog_box.show_dialog(lines)


func _on_briefing_done() -> void:
	if _dialog_box:
		_dialog_box.queue_free()
		_dialog_box = null
	wave_manager.start()


func _on_all_waves_cleared() -> void:
	show_boss_dialog()


func show_boss_dialog() -> void:
	var arena_id: String = modifier.arena_id if modifier else "jungle"
	var lines: Array[Dictionary] = NarrativeData.get_boss_dialog(arena_id)
	if lines.is_empty():
		return
	_dialog_box = _dialog_box_scene.instantiate()
	add_child(_dialog_box)
	_dialog_box.show_dialog(lines)
