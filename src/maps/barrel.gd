## Barrel — wybuchająca beczka (Bunker hazard)
## Wyciągnięte z arena.gd._BarrelVisual jako pełnoprawna scena.
class_name ExplodingBarrel
extends Area2D

@export var explode_radius: float = 60.0
@export var explosion_damage: int = 30
@export var soldier_damage: int = 15

var _alive: bool = true


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4  # projectiles
	add_to_group("barrels")
	# Collision shape via inner setup (no .tscn file needed)
	if get_child_count() == 0:
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 12.0
		shape.shape = circle
		add_child(shape)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	# Procedural beczka — czerwona z pomarańczowym rdzeniem
	draw_circle(Vector2.ZERO, 12.0, Color(0.7, 0.2, 0.1))
	draw_circle(Vector2.ZERO, 8.0, Color(0.9, 0.4, 0.1))
	draw_circle(Vector2.ZERO, 3.0, Color(0.2, 0.2, 0.2))


func _on_area_entered(_area: Area2D) -> void:
	_explode()


func _on_body_entered(_body: Node2D) -> void:
	_explode()


func _explode() -> void:
	if not _alive:
		return
	_alive = false
	var explosion_fx := ParticleFactory.create_explosion(global_position, explode_radius)
	get_tree().current_scene.add_child(explosion_fx)
	# Damage nearby enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			if global_position.distance_to(enemy.global_position) < explode_radius:
				enemy.take_damage(explosion_damage)
	# Damage nearby soldiers
	for s in get_tree().get_nodes_in_group("squad"):
		if is_instance_valid(s) and s.has_method("take_damage"):
			if global_position.distance_to(s.global_position) < explode_radius:
				s.take_damage(soldier_damage)
	queue_free()
