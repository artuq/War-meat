## ShootBehavior — wróg strzela na dystans (Shooter)
## Brotato-clone ref: scenes/unit/enemy/shooting_behavior.gd
## Dodawane jako child enemy w configure(SHOOTER, ...).
class_name ShootBehavior
extends Node2D

const _PROJECTILE := preload("res://src/entities/enemies/enemy_projectile.tscn")

@export var shoot_range: float = 120.0
@export var cooldown_max: float = 1.2

var _enemy: Enemy
var _cooldown: float = 0.0


func _ready() -> void:
	_enemy = get_parent() as Enemy


## Wywoływane przez enemy._physics_process. Zwraca true jeśli przejęło sterowanie ruchem.
func process_attack(direction: Vector2, dist: float, separation: Vector2, knockback: Vector2, delta: float) -> bool:
	if _enemy == null:
		return false
	_cooldown -= delta
	if dist > shoot_range:
		# Out of range — chase
		_enemy.velocity = direction * _enemy.move_speed + separation + knockback
		_enemy.move_and_slide()
	else:
		# In range — stop and shoot
		_enemy.velocity = separation + knockback
		_enemy.move_and_slide()
		if _cooldown <= 0.0:
			_shoot(direction)
			_cooldown = cooldown_max
	return true


func _shoot(direction: Vector2) -> void:
	var proj: EnemyProjectile = _PROJECTILE.instantiate()
	proj.damage = _enemy.attack_damage
	proj.direction = direction
	proj.global_position = _enemy.global_position + direction * 8.0
	_enemy.get_tree().current_scene.add_child(proj)
