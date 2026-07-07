## HealthComponent — zarządza HP jednostki (Brotato-clone pattern)
## Dodaj jako dziecko do CharacterBody2D, ustaw max_health w inspektorze.
## Soldier/Enemy/Boss używają tego komponentu przez property `hp` / `max_hp`.
class_name HealthComponent
extends Node

signal on_unit_hit
signal on_unit_died
signal on_health_changed(current: int, max_value: int)

@export var max_health: int = 100
var current_health: int = 100


func _ready() -> void:
	current_health = max_health


func setup(new_max: int, fill: bool = true) -> void:
	max_health = maxi(new_max, 1)
	if fill:
		current_health = max_health
	else:
		current_health = mini(current_health, max_health)
	on_health_changed.emit(current_health, max_health)


func set_max(new_max: int) -> void:
	## Ustaw max bez resetu current. Jeśli current > new_max → przytnij.
	max_health = maxi(new_max, 1)
	current_health = mini(current_health, max_health)
	on_health_changed.emit(current_health, max_health)


func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	on_unit_hit.emit()
	on_health_changed.emit(current_health, max_health)
	if current_health == 0:
		on_unit_died.emit()


func heal(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = mini(current_health + amount, max_health)
	on_health_changed.emit(current_health, max_health)


func is_alive() -> bool:
	return current_health > 0


func get_health_ratio() -> float:
	return float(current_health) / float(maxi(max_health, 1))
