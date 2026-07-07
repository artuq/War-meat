## TestCombat — i-frames, knockback, armor, damage flow (gdUnit4 v6)
extends GdUnitTestSuite
class_name TestCombat

# ── I-Frames ─────────────────────────────────────────────────

func test_iframes_block_second_hit() -> void:
	var scene := load("res://src/entities/squad/soldier.tscn") as PackedScene
	var soldier: Soldier = auto_free(scene.instantiate())
	add_child(soldier)
	await await_idle_frame()

	var hp_before := soldier.hp
	soldier.take_damage(10)
	soldier.take_damage(10)  # zablokowane przez i-frame

	assert_int(soldier.hp)\
		.is_equal(hp_before - 10)\
		.override_failure_message("I-frame nie zadziałał: spodziewano %d, dostano %d" % [hp_before - 10, soldier.hp])

func test_iframes_flag_set_after_damage() -> void:
	var scene := load("res://src/entities/squad/soldier.tscn") as PackedScene
	var soldier: Soldier = auto_free(scene.instantiate())
	add_child(soldier)
	await await_idle_frame()

	soldier.take_damage(5)
	assert_bool(soldier.is_invulnerable).is_true()

func test_iframes_expire_after_duration() -> void:
	var scene := load("res://src/entities/squad/soldier.tscn") as PackedScene
	var soldier: Soldier = auto_free(scene.instantiate())
	add_child(soldier)
	await await_idle_frame()

	soldier.take_damage(5)
	await await_millis(600)  # IFRAME_DURATION = 0.5s
	assert_bool(soldier.is_invulnerable).is_false()

# ── Armor ─────────────────────────────────────────────────────

func test_armor_reduces_damage() -> void:
	var scene := load("res://src/entities/squad/soldier.tscn") as PackedScene
	var soldier: Soldier = auto_free(scene.instantiate())
	add_child(soldier)
	await await_idle_frame()

	soldier.armor = 5
	var hp_before := soldier.hp
	soldier.take_damage(10)  # 10 - 5 armor = 5 dmg
	assert_int(soldier.hp).is_equal(hp_before - 5)

func test_armor_minimum_damage_is_1() -> void:
	var scene := load("res://src/entities/squad/soldier.tscn") as PackedScene
	var soldier: Soldier = auto_free(scene.instantiate())
	add_child(soldier)
	await await_idle_frame()

	soldier.armor = 999
	var hp_before := soldier.hp
	soldier.take_damage(1)
	assert_int(soldier.hp).is_equal(hp_before - 1)

# ── Knockback ─────────────────────────────────────────────────

func test_apply_knockback_sets_state() -> void:
	var scene := load("res://src/entities/enemies/enemy_grunt.tscn") as PackedScene
	var enemy: Enemy = auto_free(scene.instantiate())
	add_child(enemy)
	await await_idle_frame()
	enemy.configure(Enemy.EnemyType.GRUNT, 1)

	enemy._apply_knockback(Vector2.RIGHT, 90.0)

	assert_float(enemy._knockback_power).is_equal(90.0)\
		.override_failure_message("Knockback force powinno być 90.0")

func test_knockback_timer_set_after_knockback() -> void:
	var scene := load("res://src/entities/enemies/enemy_grunt.tscn") as PackedScene
	var enemy: Enemy = auto_free(scene.instantiate())
	add_child(enemy)
	await await_idle_frame()
	enemy.configure(Enemy.EnemyType.GRUNT, 1)

	enemy._apply_knockback(Vector2.RIGHT, 90.0)
	assert_float(enemy._knockback_timer).is_greater(0.0)

# ── EventBus signals ──────────────────────────────────────────

func test_soldier_damage_emits_screen_shake() -> void:
	var scene := load("res://src/entities/squad/soldier.tscn") as PackedScene
	var soldier: Soldier = auto_free(scene.instantiate())
	add_child(soldier)
	await await_idle_frame()

	var sig := assert_signal(EventBus)
	soldier.take_damage(10)
	await sig.is_emitted("screen_shake_requested")

func test_soldier_death_emits_soldier_died() -> void:
	var scene := load("res://src/entities/squad/soldier.tscn") as PackedScene
	var soldier: Soldier = auto_free(scene.instantiate())
	add_child(soldier)
	await await_idle_frame()

	var sig := assert_signal(EventBus)
	soldier.take_damage(99999)
	await sig.is_emitted("soldier_died")
