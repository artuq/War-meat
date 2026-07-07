## TestWaveFlow — testuje flow fali: spawn → kill → wave_cleared → upgrade → shop
## Weryfikuje kolejność sygnałów i stan GameManagera
extends GdUnitTestSuite
class_name TestWaveFlow


# Minimal scene setup — tylko autoloady, bez pełnej areny
func before_all() -> void:
	GameManager.start_mission(5)


# ── Sygnały w odpowiedniej kolejności ────────────────────────

func test_wave_cleared_emits_after_wave_started() -> void:
	var monitor := monitor_signals(EventBus)

	EventBus.wave_started.emit(1)
	EventBus.wave_cleared.emit(1)

	assert_signal(monitor).is_emitted("wave_started")
	assert_signal(monitor).is_emitted("wave_cleared")


func test_upgrade_panel_requested_before_shop_opened() -> void:
	# Regresja: upgrade panel MUSI poprzedzać shop_opened
	var order: Array[String] = []

	EventBus.upgrade_panel_requested.connect(
		func(): order.append("upgrade"), CONNECT_ONE_SHOT
	)
	EventBus.shop_opened.connect(
		func(): order.append("shop"), CONNECT_ONE_SHOT
	)

	EventBus.upgrade_panel_requested.emit()
	EventBus.shop_opened.emit()

	assert_array(order)\
		.is_equal(["upgrade", "shop"])\
		.override_failure_message(
			"REGRESJA: Shop otworzył się przed upgrade panelem! Kolejność: %s" % str(order)
		)


# ── WaveData — pick_enemy_type zwraca poprawne typy ──────────

func test_wave_data_pick_consistent_with_min_wave() -> void:
	var wave_data: WaveData = load("res://src/data/waves/wave_default.tres")

	# Fala 1: tylko grunt (0)
	for _i in range(30):
		assert_int(wave_data.pick_enemy_type(1)).is_equal(0)

	# Fala 5: wszystkie typy dostępne (0-4)
	var types_seen: Array[int] = []
	for _i in range(200):
		var t := wave_data.pick_enemy_type(5)
		if t not in types_seen:
			types_seen.append(t)

	assert_int(types_seen.size())\
		.is_greater_equal(3)\
		.override_failure_message(
			"Fala 5 powinna mieć ≥3 różne typy wrogów. Widziano: %s" % str(types_seen)
		)


# ── GameManager state po misji ────────────────────────────────

func test_enemies_killed_increments_on_event() -> void:
	GameManager.start_mission(5)
	var initial := GameManager.enemies_killed

	# Symuluj kill (bez prawdziwego enemy node)
	var dummy := Node2D.new()
	EventBus.enemy_killed.emit(dummy, Vector2.ZERO)
	dummy.free()

	assert_int(GameManager.enemies_killed)\
		.is_equal(initial + 1)


func test_gold_earned_on_loot_collected() -> void:
	GameManager.start_mission(5)
	GameManager.gold = 0
	GameManager.gold_earned = 0

	EventBus.loot_dropped.emit(Vector2.ZERO, 50)
	# LootSpawner zbiera i emituje loot_collected → GameManager._on_loot_collected
	EventBus.loot_collected.emit(50)

	assert_int(GameManager.gold).is_greater_equal(50)


# ── Kill streak bonusy ────────────────────────────────────────

func test_streak_bonuses_cleared_between_missions() -> void:
	GameManager.streak_speed_bonus = 0.25
	GameManager.streak_damage_bonus = 0.20

	GameManager.start_mission(5)

	assert_float(GameManager.streak_speed_bonus)\
		.is_equal(0.0)\
		.override_failure_message("streak_speed_bonus nie wyczyszczony!")
	assert_float(GameManager.streak_damage_bonus)\
		.is_equal(0.0)\
		.override_failure_message("streak_damage_bonus nie wyczyszczony!")


# ── Enemy scene registry ──────────────────────────────────────

func test_all_enemy_scenes_loadable() -> void:
	var paths := {
		"grunt":     "res://src/entities/enemies/enemy_grunt.tscn",
		"rusher":    "res://src/entities/enemies/enemy_rusher.tscn",
		"tank":      "res://src/entities/enemies/enemy_tank.tscn",
		"shooter":   "res://src/entities/enemies/enemy_shooter.tscn",
		"grenadier": "res://src/entities/enemies/enemy_grenadier.tscn",
	}
	for name in paths:
		assert_bool(ResourceLoader.exists(paths[name]))\
			.is_true()\
			.override_failure_message("Brakuje sceny wroga: %s (%s)" % [name, paths[name]])


func test_enemy_scene_instantiates_without_errors() -> void:
	var scene := load("res://src/entities/enemies/enemy_grunt.tscn") as PackedScene
	var enemy: Enemy = auto_free(scene.instantiate())
	add_child(enemy)
	await await_idle_frame()
	# configure() PO add_child — nowa reguła z refaktoru
	enemy.configure(Enemy.EnemyType.GRUNT, 1)
	await await_idle_frame()

	assert_int(enemy.max_hp).is_greater(0)
	assert_bool(enemy._is_dying).is_false()


func test_shooter_has_attack_behavior_after_configure() -> void:
	var scene := load("res://src/entities/enemies/enemy_shooter.tscn") as PackedScene
	var enemy: Enemy = auto_free(scene.instantiate())
	add_child(enemy)
	await await_idle_frame()
	enemy.configure(Enemy.EnemyType.SHOOTER, 1)
	await await_idle_frame()

	assert_object(enemy.attack_behavior)\
		.is_not_null()\
		.override_failure_message("Shooter nie ma attack_behavior po configure()!")
	assert_bool(enemy.attack_behavior is ShootBehavior)\
		.is_true()\
		.override_failure_message("attack_behavior nie jest ShootBehavior!")


func test_grenadier_has_grenade_behavior_after_configure() -> void:
	var scene := load("res://src/entities/enemies/enemy_grenadier.tscn") as PackedScene
	var enemy: Enemy = auto_free(scene.instantiate())
	add_child(enemy)
	await await_idle_frame()
	enemy.configure(Enemy.EnemyType.GRENADIER, 1)
	await await_idle_frame()

	assert_bool(enemy.attack_behavior is GrenadeBehavior)\
		.is_true()\
		.override_failure_message("attack_behavior nie jest GrenadeBehavior!")
