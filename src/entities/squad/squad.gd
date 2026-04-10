## Squad — kontroler oddziału, joystick-controlled (Brotato-style)
class_name Squad
extends Node2D

@export var formation_spacing: float = 16.0
@export var move_speed: float = 200.0

const MAX_SOLDIERS: int = 4
var soldier_scene: PackedScene = preload("res://src/entities/squad/soldier.tscn")
var soldiers: Array[Soldier] = []
var _joystick: VirtualJoystick = null


func _ready() -> void:
	_collect_soldiers()
	EventBus.soldier_died.connect(_on_soldier_died)
	call_deferred("_find_joystick")


func _find_joystick() -> void:
	var hud := get_tree().current_scene.get_node_or_null("HUD")
	if hud and hud.has_method("get_joystick"):
		_joystick = hud.get_joystick()


func _physics_process(delta: float) -> void:
	if _joystick:
		var direction := _joystick.get_direction()
		if direction != Vector2.ZERO:
			_move_squad(direction, delta)
	_position_soldiers()


func _collect_soldiers() -> void:
	soldiers.clear()
	for child in get_children():
		if child is Soldier:
			soldiers.append(child)


func _move_squad(direction: Vector2, delta: float) -> void:
	global_position += direction * move_speed * delta
	# Clamp to arena boundaries
	var arena := get_parent() as ArenaMap
	if arena:
		var half: Vector2 = arena.arena_size / 2.0
		var margin: float = 16.0
		global_position.x = clampf(global_position.x, -half.x + margin, half.x - margin)
		global_position.y = clampf(global_position.y, -half.y + margin, half.y - margin)


func _position_soldiers() -> void:
	var offsets := _get_formation_offsets(soldiers.size())
	for i in soldiers.size():
		if not is_instance_valid(soldiers[i]):
			continue
		var destination := global_position + offsets[i]
		var diff := destination - soldiers[i].global_position
		if diff.length() > 2.0:
			soldiers[i].velocity = diff.normalized() * soldiers[i].move_speed
		else:
			soldiers[i].velocity = Vector2.ZERO


func _get_formation_offsets(count: int) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	var start_x := -(count - 1) * formation_spacing / 2.0
	for i in count:
		offsets.append(Vector2(start_x + i * formation_spacing, 0))
	return offsets


func _on_soldier_died(soldier: Node2D) -> void:
	soldiers.erase(soldier)
	if soldiers.is_empty():
		EventBus.squad_wiped.emit()


func add_soldier(sc: SoldierClass) -> bool:
	if soldiers.size() >= MAX_SOLDIERS:
		return false
	var s: Soldier = soldier_scene.instantiate()
	s.soldier_class = sc
	add_child(s)
	soldiers.append(s)
	return true


func get_soldier_count() -> int:
	return soldiers.size()
