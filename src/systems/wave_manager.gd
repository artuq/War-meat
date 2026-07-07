## WaveManager — zarządza falami wrogów (Brotato-style timed survival)
## Konfiguracja jedzie z WaveData (.tres) — designer edytuje wartości w inspektorze.
class_name WaveManager
extends Node

@export var wave_data: WaveData = preload("res://src/data/waves/wave_default.tres")

# Compatibility property — arena.gd używa wave_manager.total_waves
var total_waves: int:
	get:
		return wave_data.to_wave if wave_data else 5

var current_wave: int = 0
var enemies_alive: int = 0
var is_wave_active: bool = false
var wave_time_left: float = 0.0
var _current_spawn_interval: float = 0.5
var _spawn_cooldown: float = 0.0
var _rng := RandomNumberGenerator.new()

## Osobna scena per typ wroga — brotato-clone pattern.
## Każda scena dziedziczy z enemy.tscn, ma własny sprite/radius/behavior child.
const _ENEMY_SCENES: Dictionary = {
	Enemy.EnemyType.GRUNT:     preload("res://src/entities/enemies/enemy_grunt.tscn"),
	Enemy.EnemyType.RUSHER:    preload("res://src/entities/enemies/enemy_rusher.tscn"),
	Enemy.EnemyType.TANK:      preload("res://src/entities/enemies/enemy_tank.tscn"),
	Enemy.EnemyType.SHOOTER:   preload("res://src/entities/enemies/enemy_shooter.tscn"),
	Enemy.EnemyType.GRENADIER: preload("res://src/entities/enemies/enemy_grenadier.tscn"),
}
var boss_scene: PackedScene = preload("res://src/entities/enemies/boss.tscn")

@onready var spawn_timer: Timer = $SpawnTimer
var _arena: ArenaMap = null
var _modifier: ArenaModifier = null
var _is_boss_wave: bool = false
var _boss_alive: bool = false


func _ready() -> void:
	_rng.randomize()
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
		_current_spawn_interval = maxf(
			_current_spawn_interval - wave_data.spawn_acceleration * delta * 10.0,
			wave_data.min_spawn_interval
		)
		_spawn_cooldown = _current_spawn_interval


func setup(arena: ArenaMap) -> void:
	_arena = arena


func set_modifier(mod: ArenaModifier) -> void:
	_modifier = mod


func start() -> void:
	current_wave = 0
	GameManager.total_waves = wave_data.to_wave
	_start_next_wave()


func start_from_wave(wave: int) -> void:
	## Resume from a mid-run save — skip to saved wave's shop
	current_wave = wave
	GameManager.current_wave = wave
	GameManager.total_waves = wave_data.to_wave
	# Open shop directly so player can continue from where they left off
	EventBus.wave_cleared.emit(wave)
	EventBus.shop_opened.emit()


func _start_next_wave() -> void:
	current_wave += 1
	GameManager.current_wave = current_wave

	if current_wave > wave_data.to_wave:
		EventBus.all_waves_cleared.emit()
		EventBus.mission_won.emit()
		return

	wave_time_left = wave_data.get_wave_duration(current_wave)
	if _modifier:
		wave_time_left *= _modifier.wave_duration_mult
	_current_spawn_interval = wave_data.initial_spawn_interval
	if _modifier:
		_current_spawn_interval *= _modifier.spawn_rate_mult
	_spawn_cooldown = 0.3  # small initial delay
	enemies_alive = 0
	_is_boss_wave = wave_data.spawn_boss_on_last_wave and (current_wave == wave_data.to_wave)
	_boss_alive = false
	is_wave_active = true
	SoundManager.resume_from_shop()
	EventBus.wave_started.emit(current_wave)

	# Spawn boss on final wave
	if _is_boss_wave:
		_spawn_boss()


func get_wave_duration() -> float:
	return wave_data.get_wave_duration(current_wave)


func _spawn_enemy() -> void:
	if _arena == null:
		return
	var pos: Vector2 = _arena.get_camera_edge_spawn_position()
	var type: Enemy.EnemyType = _pick_enemy_type(current_wave)
	var spawn_wave: int = current_wave  # capture, w razie zmiany podczas await

	# Spawn telegraph — daje graczowi 0.4s na reakcję
	var telegraph := SpawnTelegraph.new()
	telegraph.global_position = pos
	get_tree().current_scene.add_child(telegraph)
	await telegraph.finished

	# Wave mogła się zakończyć podczas telegraph — nie spawnuj wroga w tej fazie
	if not is_wave_active or not is_inside_tree():
		return

	var scene: PackedScene = _ENEMY_SCENES.get(type, _ENEMY_SCENES[Enemy.EnemyType.GRUNT])
	var enemy: Enemy = scene.instantiate()
	enemy.global_position = pos
	# Add to tree first → _ready inicjalizuje komponenty + wykrywa pre-attached behavior
	get_tree().current_scene.add_child(enemy)
	enemy.configure(type, spawn_wave)
	# Apply arena modifiers to enemy stats
	if _modifier:
		enemy.max_hp = int(enemy.max_hp * _modifier.enemy_hp_mult)
		enemy.hp = enemy.max_hp
		enemy.move_speed *= _modifier.enemy_speed_mult
	enemies_alive += 1
	EventBus.enemy_spawned.emit(enemy)


## Cienka warstwa nad wave_data.pick_enemy_type — zachowana dla łatwego testu/przesterowania
func _pick_enemy_type(wave: int) -> Enemy.EnemyType:
	var picked: int = wave_data.pick_enemy_type(wave, _rng)
	return picked as Enemy.EnemyType


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
	# Discard uncollected loot (not crates)
	for loot in get_tree().get_nodes_in_group("loot"):
		if loot is LootDrop and is_instance_valid(loot):
			loot.queue_free()
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
	SoundManager.duck_for_shop()
	SoundManager.play_stinger("victory")
	# Save mid-run state for Continue
	SaveManager.save_run()
	# Slow-mo breather before shop opens
	_do_wave_end_slowmo()


func _do_wave_end_slowmo() -> void:
	Engine.time_scale = 0.3
	# Use a real-time tween (process_mode ALWAYS) so it runs during slow-mo
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	# Hold slow-mo for ~0.5 real seconds (= 1.5s game time at 0.3×)
	tween.tween_interval(1.5)
	tween.tween_callback(_after_wave_end_slowmo)


func _after_wave_end_slowmo() -> void:
	Engine.time_scale = 1.0
	if current_wave >= wave_data.to_wave:
		# Final wave — boss case, _on_enemy_killed handles it
		_start_next_wave()
		return
	# Show upgrade panel, await pick, then open shop
	EventBus.upgrade_panel_requested.emit()
	await EventBus.upgrade_panel_completed
	EventBus.shop_opened.emit()


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
	boss_node.global_position = _arena.get_camera_edge_spawn_position()
	# Add to tree first → _ready inicjalizuje komponenty, potem configure
	get_tree().current_scene.add_child(boss_node)
	boss_node.configure(boss_type, current_wave)
	_boss_alive = true
	enemies_alive += 1


func _on_enemy_killed(enemy: Node2D, _position: Vector2) -> void:
	enemies_alive = maxi(enemies_alive - 1, 0)
	if enemy is Boss:
		_boss_alive = false
		# Boss killed during boss wave = wave complete
		if _is_boss_wave:
			_complete_wave()
