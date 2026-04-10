## LootDrop — loot upuszczony przez wroga (złoto)
class_name LootDrop
extends Area2D

var value: int = 10
var _can_pickup: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(0.3).timeout.connect(func(): _can_pickup = true)


func _draw() -> void:
	# Gold coin placeholder
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.85, 0.1))
	draw_arc(Vector2.ZERO, 3.0, 0, TAU, 24, Color(0.8, 0.65, 0.0), 1.0)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("squad") and _can_pickup:
		EventBus.loot_collected.emit(value)
		queue_free()
