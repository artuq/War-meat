## GrenadeBehavior — wróg rzuca granaty AoE (Grenadier)
## Dodawane jako child enemy w configure(GRENADIER, ...).
class_name GrenadeBehavior
extends Node2D

@export var throw_range: float = 100.0
@export var cooldown_max: float = 2.5
@export var explode_radius: float = 40.0
@export var fuse_time: float = 0.5
@export var grenade_speed: float = 150.0

var _enemy: Enemy
var _cooldown: float = 0.0


func _ready() -> void:
	_enemy = get_parent() as Enemy


## Wywoływane przez enemy._physics_process. Zawsze przejmuje sterowanie.
func process_attack(direction: Vector2, dist: float, separation: Vector2, knockback: Vector2, delta: float) -> bool:
	if _enemy == null:
		return false
	_cooldown -= delta
	# Zwolnij blisko targetu
	var current_speed := _enemy.move_speed
	if dist <= throw_range * 0.8:
		current_speed *= 0.3
	_enemy.velocity = direction * current_speed + separation + knockback
	_enemy.move_and_slide()
	# Throw if in range
	if dist < throw_range and _cooldown <= 0.0 and is_instance_valid(_enemy.target):
		_throw_grenade(_enemy.target.global_position)
		_cooldown = cooldown_max
	return true


func _throw_grenade(target_pos: Vector2) -> void:
	var grenade := _Grenade.new()
	grenade.damage = _enemy.attack_damage
	grenade.target_pos = target_pos
	grenade.speed = grenade_speed
	grenade.explode_radius = explode_radius
	grenade.fuse_time = fuse_time
	grenade.global_position = _enemy.global_position
	_enemy.get_tree().current_scene.add_child(grenade)


## Inner class — granat lecący do celu, eksploduje po fuse
class _Grenade extends Area2D:
	var damage: int = 12
	var target_pos: Vector2 = Vector2.ZERO
	var speed: float = 150.0
	var explode_radius: float = 40.0
	var fuse_time: float = 0.5
	var _arrived: bool = false
	var _fuse_timer: float = 0.0


	func _ready() -> void:
		collision_layer = 0
		collision_mask = 0
		var timer := get_tree().create_timer(3.0)
		timer.timeout.connect(queue_free)


	func _draw() -> void:
		if not _arrived:
			# Granat — mała kulka
			draw_circle(Vector2.ZERO, 4.0, Color(0.9, 0.7, 0.1))
			draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.95, 0.5))


	func _physics_process(delta: float) -> void:
		if not _arrived:
			var dist := global_position.distance_to(target_pos)
			if dist < 5.0:
				_arrived = true
				global_position = target_pos
				queue_redraw()
			else:
				var dir := (target_pos - global_position).normalized()
				global_position += dir * speed * delta
		else:
			_fuse_timer += delta
			queue_redraw()
			if _fuse_timer >= fuse_time:
				_explode()


	func _explode() -> void:
		for s in get_tree().get_nodes_in_group("squad"):
			if is_instance_valid(s) and s.has_method("take_damage"):
				if global_position.distance_to(s.global_position) < explode_radius:
					s.take_damage(damage)
		# Particles
		var p := CPUParticles2D.new()
		p.position = global_position
		p.z_index = 3
		p.one_shot = true
		p.explosiveness = 0.9
		p.amount = 20
		p.lifetime = 0.5
		p.direction = Vector2(0, 0)
		p.spread = 180.0
		p.gravity = Vector2.ZERO
		p.initial_velocity_min = 40.0
		p.initial_velocity_max = 90.0
		p.scale_amount_min = 4.0
		p.scale_amount_max = 10.0
		p.color = Color(1.0, 0.45, 0.1, 0.9)
		get_tree().current_scene.add_child(p)
		get_tree().create_timer(0.8).timeout.connect(p.queue_free)
		queue_free()
