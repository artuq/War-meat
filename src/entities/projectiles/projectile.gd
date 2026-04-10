## Projectile — pocisk wystrzelony przez żołnierza
class_name Projectile
extends Area2D

@export var speed: float = 250.0
@export var lifetime: float = 2.0

var damage: int = 10
var direction: Vector2 = Vector2.UP
var is_crit: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)


func _draw() -> void:
	if is_crit:
		draw_circle(Vector2.ZERO, 3.5, Color(1.0, 0.2, 0.1))
		draw_circle(Vector2.ZERO, 2.0, Color(1.0, 0.85, 0.1))
	else:
		draw_circle(Vector2.ZERO, 2.0, Color(1.0, 0.95, 0.3))


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
