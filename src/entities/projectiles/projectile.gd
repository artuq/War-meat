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
		# Crit: bright red-orange with white core — clearly dangerous
		draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.3, 0.1))
		draw_circle(Vector2.ZERO, 2.2, Color(1.0, 1.0, 0.8))
	else:
		# Normal: cyan-blue tracer — visually distinct from yellow coins
		draw_circle(Vector2.ZERO, 2.5, Color(0.3, 0.8, 1.0))
		draw_circle(Vector2.ZERO, 1.2, Color(0.9, 1.0, 1.0))


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		# Knockback — odpycha wroga od miejsca trafienia
		if body.has_method("_apply_knockback"):
			var kb_dir := (body.global_position - global_position).normalized()
			body._apply_knockback(kb_dir, 90.0)
		var sparks := ParticleFactory.create_hit_sparks(global_position)
		get_tree().current_scene.add_child(sparks)
		queue_free()
