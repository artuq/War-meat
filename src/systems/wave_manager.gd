## WaveManager — zarządza falami wrogów (Brotato-style timed survival)
extends Node

@export var total_waves: int = 5
@export var base_wave_duration: float = 30.0  ## seconds per wave
@export var wave_duration_increase: float = 5.0  ## extra seconds per wave
@export var base_spawn_interval: float = 1.5  ## seconds between spawns at wave start
@export var min_spawn_interval: float = 0.4  ## fastest spawn rate
@export var spawn_acceleration: float = 0.05  ## interval decreases by this per second

var current_wave: int = 0
var enemies_alive: int = 0
var is_wave_active: bool = false
var wave_time_left: float = 0.0
var _current_spawn_interval: float = 1.5
var _spawn_cooldown: float = 0.0

var enemy_scene: PackedScene = preload("res://src/entities/enemies/enemy.tscn")
var boss_scene: PackedScene = preload("res://src/entities/enemies/boss.tscn")

@onready var spawn_timer: Timer = $SpawnTimer
var _arena: ArenaMap = null
var _modifier: ArenaModifier = null
var _is_boss_wave: bool = false
var _boss_alive: bool = false


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.shop_closed.connect(_start_next_wave)


func _process(delta: float) -> void:
	if not is_wave_active:
		return

	# Wave timer countdown
	wave_time_left -= delta
	if wave_time_left <= 0.0:
		wave_time_left = 0.0
		_on_wave_timer_done()
		return

	# Continuous spawning with accelerating rate
	_spawn_cooldown -= delta
	if _spawn_cooldown <= 0.0:
		_spawn_enemy()
		_current_spawn_interval = maxf(_current_spawn_interval - spawn_acceleration * delta * 10.0, min_spawn_interval)
		_spawn_cooldown = _current_spawn_interval


func setup(arena: ArenaMap) -> void:
	_arena = arena


func set_modifier(mod: ArenaModifier) -> void:
	_modifier = mod


func start() -> void:
	current_wave = 0
	GameManager.total_waves = total_waves
	_start_next_wave()


func _start_next_wave() -> void:
	current_wave += 1
	GameManager.current_wave = current_wave

	if current_wave > total_waves:
		EventBus.all_waves_cleared.emit()
		EventBus.mission_won.emit()
		return

	wave_time_left = base_wave_duration + (current_wave - 1) * wave_duration_increase
	if _modifier:
		wave_time_left *= _modifier.wave_duration_mult
	_current_spawn_interval = base_spawn_interval
	if _modifier:
		_current_spawn_interval *= _modifier.spawn_rate_mult
	_spawn_cooldown = 0.3  # small initial delay
	enemies_alive = 0
	_is_boss_wave = (current_wave == total_waves)
	_boss_alive = false
	is_wave_active = true
	EventBus.wave_started.emit(current_wave)

	# Spawn boss on final wave
	if _is_boss_wave:
		_spawn_boss()


func get_wave_duration() -> float:
	return base_wave_duration + (current_wave - 1) * wave_duration_increase


func _spawn_enemy() -> void:
	if _arena == null:
		return
	var type: Enemy.EnemyType = _pick_enemy_type(current_wave)
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.configure(type, current_wave)
	# Apply arena modifiers to enemy stats
	if _modifier:
		enemy.max_hp = int(enemy.max_hp * _modifier.enemy_hp_mult)
		enemy.hp = enemy.max_hp
		enemy.move_speed *= _modifier.enemy_speed_mult
	enemy.global_position = _arena.get_edge_spawn_position()
	get_tree().current_scene.add_child(enemy)
	enemies_alive += 1
	EventBus.enemy_spawned.emit(enemy)


func _pick_enemy_type(wave: int) -> Enemy.EnemyType:
	if _modifier:
		# Use modifier weights + add Shooter/Grenadier in later waves
		var roll := randf()
		var shooter_chance: float = 0.15 if wave >= 3 else 0.0
		var grenadier_chance: float = 0.10 if wave >= 4 else 0.0
		if roll < grenadier_chance:
			return Enemy.EnemyType.GRENADIER
		elif roll < grenadier_chance + shooter_chance:
			return Enemy.EnemyType.SHOOTER
		elif roll < grenadier_chance + shooter_chance + _modifier.tank_weight and wave >= 2:
			return Enemy.EnemyType.TANK
		elif roll < grenadier_chance + shooter_chance + _modifier.tank_weight + _modifier.rusher_weight:
			return Enemy.EnemyType.RUSHER
		return Enemy.EnemyType.GRUNT
	# Default fallback (no modifier)
	var roll := randf()
	if wave >= 4 and roll < 0.10:
		return Enemy.EnemyType.GRENADIER
	elif wave >= 3 and roll < 0.25:
		return Enemy.EnemyType.SHOOTER
	elif wave >= 4 and roll < 0.40:
		return Enemy.EnemyType.TANK
	elif wave >= 2 and roll < 0.55:
		return Enemy.EnemyType.RUSHER
	return Enemy.EnemyType.GRUNT


func _on_wave_timer_done() -> void:
	if _is_boss_wave and _boss_alive:
		# Boss wave: stop spawning but don't end — wait for boss death
		is_wave_active = false
		# Kill non-boss enemies
		for e in get_tree().get_nodes_in_group("enemies"):
			if e is Enemy and is_instance_valid(e):
				e.queue_free()
		return

	_complete_wave()


func _complete_wave() -> void:
	is_wave_active = false
	# Kill remaining non-boss enemies
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy and is_instance_valid(e):
			e.queue_free()
	enemies_alive = 0
	# Wave completion bonus
	var wave_bonus: int = 25 + current_wave * 15
	GameManager.gold += wave_bonus
	GameManager.gold_earned += wave_bonus
	EventBus.wave_cleared.emit(current_wave)
	if current_wave < total_waves:
		EventBus.shop_opened.emit()
	else:
		_start_next_wave()


func _spawn_boss() -> void:
	if _arena == null:
		return
	var boss_node: Boss = boss_scene.instantiate()
	var boss_type: Boss.BossType = Boss.BossType.JUNGLE
	if _modifier:
		match _modifier.arena_id:
			"jungle":
				boss_type = Boss.BossType.JUNGLE
			"desert":
				boss_type = Boss.BossType.DESERT
			"bunker":
				boss_type = Boss.BossType.BUNKER
	boss_node.configure(boss_type, current_wave)
	boss_node.global_position = _arena.get_edge_spawn_position()
	get_tree().current_scene.add_child(boss_node)
	_boss_alive = true
	enemies_alive += 1


func _on_enemy_killed(enemy: Node2D, _position: Vector2) -> void:
	enemies_alive = maxi(enemies_alive - 1, 0)
	if enemy is Boss:
		_boss_alive = false
		# Boss killed during boss wave = wave complete
		if _is_boss_wave:
			_complete_wave()
