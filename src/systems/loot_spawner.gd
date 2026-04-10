## LootSpawner — nasłuchuje sygnału loot_dropped i tworzy instancje LootDrop
extends Node

var loot_scene: PackedScene = preload("res://src/entities/loot/loot_drop.tscn")


func _ready() -> void:
	EventBus.loot_dropped.connect(_on_loot_dropped)


func _on_loot_dropped(position: Vector2, value: int) -> void:
	var drop: LootDrop = loot_scene.instantiate()
	drop.value = value
	drop.global_position = position
	get_tree().current_scene.add_child(drop)
