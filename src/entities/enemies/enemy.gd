## Enemy — bazowy wróg z wariantami (Brotato-style)
class_name Enemy
extends CharacterBody2D

enum EnemyType { GRUNT, RUSHER, TANK, SHOOTER, GRENADIER }

@export var max_hp: int = 30
@export var move_speed: float = 40.0
@export var attack_damage: int = 5
@export var gold_value: int = 10
@export var contact_cooldown: float = 0.5
@export var enemy_type: EnemyType = EnemyType.GRUNT

var hp: int
var target: Node2D = null
var _contact_timer: float = 0.0
var xp_value: int = 10

# Shooter variables
var _shoot_range: float = 120.0
var _shoot_cooldown_max: float = 1.2
var _shoot_cooldown: float = 0.0

# Grenadier variables
var _grenade_range: float = 100.0
var _grenade_cooldown_max: float = 2.5
var _grenade_cooldown: float = 0.0

var _enemy_projectile_scene: PackedScene = preload("res://src/entities/enemies/enemy_projectile.tscn")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	_apply_visual()


func _draw() -> void:
	var radius := 5.0
	var color := Color(0.9, 0.2, 0.2)  # red grunt
	match enemy_type:
		EnemyType.GRUNT:
			radius = 5.0
			color = Color(0.9, 0.2, 0.2)
		EnemyType.RUSHER:
			radius = 4.0
			color = Color(1.0, 0.6, 0.3)
		EnemyType.TANK:
			radius = 7.0
			color = Color(0.6, 0.3, 0.8)
		EnemyType.SHOOTER:
			radius = 5.0
			color = Color(0.2, 0.6, 0.9)
		EnemyType.GRENADIER:
			radius = 6.0
			color = Color(0.9, 0.8, 0.2)
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color.darkened(0.3), 1.0)
	# Shooter crosshair indicator
	if enemy_type == EnemyType.SHOOTER:
		draw_line(Vector2(-3, 0), Vector2(3, 0), Color.WHITE, 1.0)
		draw_line(Vector2(0, -3), Vector2(0, 3), Color.WHITE, 1.0)
	# Grenadier warning ring
	if enemy_type == EnemyType.GRENADIER:
		draw_arc(Vector2.ZERO, 8.0, 0, TAU, 16, Color(1, 0.4, 0.1, 0.4), 1.0)


## Konfiguruj wariant wroga — wywoływane PRZED add_child
func configure(type: EnemyType, wave: int) -> void:
	enemy_type = type
	var wave_mult := 1.0 + (wave - 1) * 0.15  # +15% stats per wave
	match type:
		EnemyType.GRUNT:
			max_hp = int(30 * wave_mult)
			move_speed = 40.0 + wave * 2.0
			attack_damage = int(5 * wave_mult)
			gold_value = 15 + wave * 3
			xp_value = 10
		EnemyType.RUSHER:
			max_hp = int(15 * wave_mult)
			move_speed = 75.0 + wave * 3.0
			attack_damage = int(3 * wave_mult)
			gold_value = 12 + wave * 2
			contact_cooldown = 0.3
			xp_value = 8
		EnemyType.TANK:
			max_hp = int(80 * wave_mult)
			move_speed = 20.0 + wave * 1.0
			attack_damage = int(10 * wave_mult)
			gold_value = 30 + wave * 5
			xp_value = 25
		EnemyType.SHOOTER:
			max_hp = int(20 * wave_mult)
			move_speed = 25.0 + wave * 1.0
			attack_damage = int(6 * wave_mult)
			gold_value = 18 + wave * 3
			xp_value = 15
			_shoot_range = 120.0 + wave * 5.0
			_shoot_cooldown_max = 1.2
		EnemyType.GRENADIER:
			max_hp = int(35 * wave_mult)
			move_speed = 22.0 + wave * 1.0
			attack_damage = int(12 * wave_mult)
			gold_value = 25 + wave * 4
			xp_value = 20
			_grenade_range = 100.0 + wave * 5.0
			_grenade_cooldown_max = 2.5


func _apply_visual() -> void:
	match enemy_type:
		EnemyType.RUSHER:
			var shape: CircleShape2D = collision_shape.shape
			shape.radius = 4.0
		EnemyType.TANK:
			var shape: CircleShape2D = collision_shape.shape
			shape.radius = 7.0
		EnemyType.GRENADIER:
			var shape: CircleShape2D = collision_shape.shape
			shape.radius = 6.0
	queue_redraw()


func _physics_process(delta: float) -> void:
	_find_target()
	if not is_instance_valid(target):
		return

	var dist_to_target := global_position.distance_to(target.global_position)
	var direction := (target.global_position - global_position).normalized()

	match enemy_type:
		EnemyType.SHOOTER:
			_shoot_cooldown -= delta
			if dist_to_target > _shoot_range:
				velocity = direction * move_speed
				move_and_slide()
			else:
				velocity = Vector2.ZERO
				if _shoot_cooldown <= 0.0:
					_shoot_at_target(direction)
					_shoot_cooldown = _shoot_cooldown_max
		EnemyType.GRENADIER:
			_grenade_cooldown -= delta
			if dist_to_target > _grenade_range * 0.8:
				velocity = direction * move_speed
				move_and_slide()
			else:
				velocity = direction * move_speed * 0.3
				move_and_slide()
			if dist_to_target < _grenade_range and _grenade_cooldown <= 0.0:
				_throw_grenade(target.global_position)
				_grenade_cooldown = _grenade_cooldown_max
		_:
			velocity = direction * move_speed
			move_and_slide()
			_check_contact_damage(delta)


func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		hp = 0
		_die()


func _die() -> void:
	EventBus.enemy_killed.emit(self, global_position)
	EventBus.loot_dropped.emit(global_position, gold_value)
	GameManager.add_xp(xp_value)
	queue_free()


func _find_target() -> void:
	if is_instance_valid(target):
		return
	var squad_members := get_tree().get_nodes_in_group("squad")
	var closest_dist := INF
	for member in squad_members:
		var dist := global_position.distance_to(member.global_position)
		if dist < closest_dist:
			closest_dist = dist
			target = member


func _check_contact_damage(delta: float) -> void:
	_contact_timer -= delta
	if _contact_timer > 0.0:
		return
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is Soldier:
			collider.take_damage(attack_damage)
			_contact_timer = contact_cooldown
			break


func _shoot_at_target(direction: Vector2) -> void:
	var proj: EnemyProjectile = _enemy_projectile_scene.instantiate()
	proj.damage = attack_damage
	proj.direction = direction
	proj.global_position = global_position + direction * 8.0
	get_tree().current_scene.add_child(proj)


func _throw_grenade(target_pos: Vector2) -> void:
	var grenade := _EnemyGrenade.new()
	grenade.damage = attack_damage
	grenade.target_pos = target_pos
	grenade.global_position = global_position
	get_tree().current_scene.add_child(grenade)


## Grenade inner class — flies to target, shows warning, explodes
class _EnemyGrenade extends Area2D:
	var damage: int = 12
	var target_pos: Vector2 = Vector2.ZERO
	var _speed: float = 150.0
	var _explode_radius: float = 40.0
	var _arrived: bool = false
	var _fuse_time: float = 0.5
	var _fuse_timer: float = 0.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = 0
		var timer := get_tree().create_timer(3.0)
		timer.timeout.connect(queue_free)

	func _draw() -> void:
		if _arrived:
			# Warning circle (pulsing red)
			var alpha: float = 0.3 + 0.4 * sin(_fuse_timer * 12.0)
			draw_circle(Vector2.ZERO, _explode_radius, Color(1, 0.2, 0.1, alpha))
			draw_arc(Vector2.ZERO, _explode_radius, 0, TAU, 24, Color(1, 0.3, 0.1, 0.8), 1.5)
		else:
			draw_circle(Vector2.ZERO, 3.0, Color(0.9, 0.8, 0.2))

	func _physics_process(delta: float) -> void:
		if not _arrived:
			var dist := global_position.distance_to(target_pos)
			if dist < 5.0:
				_arrived = true
				global_position = target_pos
				queue_redraw()
			else:
				var dir := (target_pos - global_position).normalized()
				global_position += dir * _speed * delta
		else:
			_fuse_timer += delta
			queue_redraw()
			if _fuse_timer >= _fuse_time:
				_explode()

	func _explode() -> void:
		for s in get_tree().get_nodes_in_group("squad"):
			if is_instance_valid(s) and s is Soldier:
				if global_position.distance_to(s.global_position) < _explode_radius:
					s.take_damage(damage)
		queue_free()
