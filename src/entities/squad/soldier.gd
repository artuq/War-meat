## Soldier — pojedynczy żołnierz w oddziale
class_name Soldier
extends CharacterBody2D

@export var max_hp: int = 100
@export var move_speed: float = 80.0

var hp: int
var target: Node2D = null
var weapon: WeaponData = null
var soldier_class: SoldierClass = null
var damage_mult: float = 1.0
var luck: float = 10.0
var dodge_chance: float = 0.0
var armor: int = 0
var range_mult: float = 1.0
var fire_rate_mult: float = 1.0

@onready var detection_area: Area2D = $DetectionArea
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $AttackTimer
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var muzzle: Marker2D = $WeaponPivot/Muzzle


func _ready() -> void:
	if soldier_class == null:
		soldier_class = SoldierClass.create_assault()
	_apply_class()
	hp = max_hp
	add_to_group("squad")
	if weapon == null:
		weapon = SoldierClass.get_default_weapon(soldier_class)
	_apply_weapon()
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	detection_area.body_entered.connect(_on_body_entered_detection)
	detection_area.body_exited.connect(_on_body_exited_detection)


func configure_class(sc: SoldierClass) -> void:
	soldier_class = sc
	_apply_class()
	weapon = SoldierClass.get_default_weapon(sc)
	_apply_weapon()
	queue_redraw()


func _apply_class() -> void:
	max_hp = soldier_class.base_hp
	move_speed = soldier_class.base_speed
	damage_mult = soldier_class.damage_mult
	luck = soldier_class.base_luck


func _draw() -> void:
	var color := soldier_class.draw_color if soldier_class else Color(0.2, 0.8, 0.2)
	var radius := soldier_class.draw_radius if soldier_class else 6.0
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color.darkened(0.3), 1.0)
	# Orbiting weapon barrel
	if weapon_pivot:
		var gun_dir := Vector2.RIGHT.rotated(weapon_pivot.rotation)
		var gun_start := gun_dir * (radius - 1.0)
		var gun_end := gun_dir * (radius + 7.0)
		draw_line(gun_start, gun_end, Color(0.75, 0.75, 0.75), 2.0)
		# Muzzle dot
		draw_circle(gun_end, 1.5, Color(1.0, 0.95, 0.5))


func set_weapon(new_weapon: WeaponData) -> void:
	weapon = new_weapon
	_apply_weapon()


func _apply_weapon() -> void:
	attack_timer.wait_time = 1.0 / (weapon.fire_rate * fire_rate_mult)
	var det_shape: CircleShape2D = detection_area.get_child(0).shape
	det_shape.radius = weapon.attack_range * range_mult


func _physics_process(delta: float) -> void:
	if velocity != Vector2.ZERO:
		move_and_slide()
	_update_target()
	# Weapon orbit — rotate pivot toward target
	if is_instance_valid(target):
		weapon_pivot.look_at(target.global_position)
	queue_redraw()
	if soldier_class and soldier_class.class_type == SoldierClass.ClassType.MEDIC:
		_medic_heal(delta)


var _heal_timer: float = 0.0


func _medic_heal(delta: float) -> void:
	_heal_timer -= delta
	if _heal_timer > 0.0:
		return
	_heal_timer = 2.0
	var allies := get_tree().get_nodes_in_group("squad")
	for ally in allies:
		if ally is Soldier and ally != self and ally.hp < ally.max_hp:
			ally.hp = mini(ally.hp + 5, ally.max_hp)
			EventBus.soldier_damaged.emit(ally)


func take_damage(amount: int) -> void:
	if dodge_chance > 0.0 and randf() < dodge_chance:
		return  # Dodged!
	var final_amount: int = maxi(amount - armor, 1)
	hp -= final_amount
	EventBus.soldier_damaged.emit(self)
	_flash_damage()
	if hp <= 0:
		hp = 0
		_die()


func _flash_damage() -> void:
	var tween := create_tween()
	modulate = Color(1.0, 0.3, 0.3)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)


func _die() -> void:
	EventBus.soldier_died.emit(self)
	queue_free()


func _update_target() -> void:
	if is_instance_valid(target):
		return
	# Szukaj najbliższego wroga w zasięgu
	var enemies := detection_area.get_overlapping_bodies()
	var closest_dist := INF
	target = null
	for enemy in enemies:
		if enemy.is_in_group("enemies"):
			var dist := global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				target = enemy


func _on_attack_timer_timeout() -> void:
	if is_instance_valid(target):
		_shoot_at(target)


func _shoot_at(enemy: Node2D) -> void:
	var projectile_scene := preload("res://src/entities/projectiles/projectile.tscn")
	# Predictive aiming — celuj tam, gdzie wróg będzie za chwilę
	var to_enemy: Vector2 = enemy.global_position - global_position
	var dist: float = to_enemy.length()
	var time_to_hit: float = dist / weapon.projectile_speed
	var enemy_vel: Vector2 = enemy.velocity if enemy is CharacterBody2D else Vector2.ZERO
	var predicted_pos: Vector2 = enemy.global_position + enemy_vel * time_to_hit
	var base_dir: Vector2 = (predicted_pos - global_position).normalized()
	var crit_chance: float = clampf(luck / 200.0, 0.0, 0.5)
	for i in weapon.projectile_count:
		var proj: Projectile = projectile_scene.instantiate()
		var is_crit: bool = randf() < crit_chance
		var base_damage: int = int(weapon.damage * damage_mult)
		proj.damage = base_damage * 2 if is_crit else base_damage
		proj.is_crit = is_crit
		proj.speed = weapon.projectile_speed
		if weapon.projectile_count > 1:
			var offset: float = -weapon.spread_angle / 2.0 + weapon.spread_angle * (float(i) / maxf(float(weapon.projectile_count - 1), 1.0))
			proj.direction = base_dir.rotated(offset)
		else:
			var spread: float = randf_range(-weapon.spread_angle, weapon.spread_angle)
			proj.direction = base_dir.rotated(spread)
		proj.global_position = muzzle.global_position
		get_tree().current_scene.add_child(proj)


func _on_body_entered_detection(body: Node2D) -> void:
	if body.is_in_group("enemies") and not is_instance_valid(target):
		target = body


func _on_body_exited_detection(body: Node2D) -> void:
	if body == target:
		target = null
