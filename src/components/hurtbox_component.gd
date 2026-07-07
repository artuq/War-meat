## HurtboxComponent — Area2D otrzymująca obrażenia (cel ataku)
## Brotato-clone pattern: jednostki (Soldier/Enemy/Boss) mają HurtboxComponent jako dziecko.
## Wykrywa wejście HitboxComponent → emituje on_damaged(hitbox).
## Pełne wpięcie przyjdzie wraz z #3 (enemy refactor) i #4 (weapon refactor).
class_name HurtboxComponent
extends Area2D

signal on_damaged(hitbox: Node)


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is HitboxComponent:
		on_damaged.emit(area)
