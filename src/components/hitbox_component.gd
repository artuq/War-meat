## HitboxComponent — Area2D zadająca obrażenia (źródło ataku)
## Brotato-clone pattern: pociski/melee mają HitboxComponent, jednostki mają HurtboxComponent.
## HitboxComponent wykrywa wejście w HurtboxComponent → emituje on_hit_hurtbox.
## Pełne wpięcie w pociski przyjdzie wraz z #4 (Weapon refactor).
class_name HitboxComponent
extends Area2D

signal on_hit_hurtbox(hurtbox: Node)

var damage: int = 1
var critical: bool = false
var knockback_power: float = 0.0
var source: Node2D = null


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func enable() -> void:
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)


func disable() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)


func setup(p_damage: int, p_critical: bool, p_knockback: float, p_source: Node2D) -> void:
	damage = p_damage
	critical = p_critical
	knockback_power = p_knockback
	source = p_source


func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		on_hit_hurtbox.emit(area)
