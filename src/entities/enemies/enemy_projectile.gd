## EnemyProjectile — pocisk wroga (Shooter)
class_name EnemyProjectile
extends Area2D

@export var speed: float = 180.0
@export var lifetime: float = 2.0

var damage: int = 6
var direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	collision_layer = 2  # enemy layer
	collision_mask = 1   # hits squad
	body_entered.connect(_on_body_entered)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 2.0, Color(1.0, 0.3, 0.3))


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body is Soldier:
		body.take_damage(damage)
		queue_free()
