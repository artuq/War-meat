## TestWaveData — gdUnit4 v6
## UWAGA: nowa instancja na każdy test — class vars nie persystują.
## Używamy helpera _wd() który wczytuje WaveData lokalnie.
extends GdUnitTestSuite
class_name TestWaveData


func _wd():
	return load("res://src/data/waves/wave_default.tres")


func _get_unit(enemy_type: int) -> WaveUnitData:
	for u in _wd().units:
		if u.enemy_type == enemy_type:
			return u
	fail("Nie znaleziono unit dla enemy_type=%d" % enemy_type)
	return null


# ── Struktura danych ──────────────────────────────────────────

func test_wave_data_loaded_successfully() -> void:
	assert_object(_wd()).is_not_null()


func test_has_five_enemy_types() -> void:
	assert_int(_wd().units.size()).is_equal(5)


func test_covers_waves_1_to_5() -> void:
	assert_int(_wd().from_wave).is_equal(1)
	assert_int(_wd().to_wave).is_equal(5)


# ── REGRESJA: Grenadier weight=0 ─────────────────────────────

func test_grenadier_has_nonzero_weight() -> void:
	var grenadier_units: Array = _wd().units.filter(
		func(u: WaveUnitData) -> bool: return u.enemy_type == 4
	)
	assert_array(grenadier_units)\
		.is_not_empty()\
		.override_failure_message("Brak Grenadiera w wave_data!")
	assert_float(grenadier_units[0].weight)\
		.is_greater(0.0)\
		.override_failure_message("REGRESJA: Grenadier weight=0!")


# ── Reguły min_wave ───────────────────────────────────────────

func test_grunt_appears_from_wave_1() -> void:
	var grunt := _get_unit(0)
	assert_int(grunt.min_wave).is_equal(1)


func test_rusher_appears_from_wave_2() -> void:
	var rusher := _get_unit(1)
	assert_int(rusher.min_wave).is_equal(2)


func test_tank_appears_from_wave_3() -> void:
	var tank := _get_unit(2)
	assert_int(tank.min_wave).is_equal(3)


func test_shooter_appears_from_wave_3() -> void:
	var shooter := _get_unit(3)
	assert_int(shooter.min_wave).is_equal(3)


func test_grenadier_appears_from_wave_4() -> void:
	var grenadier := _get_unit(4)
	assert_int(grenadier.min_wave).is_equal(4)


# ── Wave 1 — tylko Grunty ─────────────────────────────────────

func test_wave1_pick_only_returns_grunt() -> void:
	var wd = _wd()
	for i in range(100):
		var picked: int = wd.pick_enemy_type(1)
		assert_int(picked)\
			.is_equal(0)\
			.override_failure_message("Fala 1 zwróciła non-Grunt: %d" % picked)


# ── pick_enemy_type zwraca validne typy ───────────────────────

func test_pick_returns_valid_type_wave_3() -> void:
	var wd = _wd()
	var valid_types := [0, 1, 2, 3]
	for i in range(50):
		var picked: int = wd.pick_enemy_type(3)
		assert_array(valid_types)\
			.contains(picked)\
			.override_failure_message("Fala 3 zwróciła invalid typ: %d" % picked)


func test_pick_never_returns_grenadier_on_wave_3() -> void:
	var wd = _wd()
	for i in range(100):
		var picked: int = wd.pick_enemy_type(3)
		assert_int(picked)\
			.is_not_equal(4)\
			.override_failure_message("Grenadier pojawił się na fali 3 (min_wave=4)!")


# ── Timing ────────────────────────────────────────────────────

func test_wave_duration_increases_per_wave() -> void:
	var wd = _wd()
	var dur_wave1: float = wd.get_wave_duration(1)
	var dur_wave3: float = wd.get_wave_duration(3)
	assert_float(dur_wave3).is_greater(dur_wave1)


func test_spawn_interval_has_valid_range() -> void:
	var wd = _wd()
	assert_float(wd.min_spawn_interval).is_less(wd.initial_spawn_interval)
