## TestHealthComponent — gdUnit4 v6
## Nota: HealthComponent tworzymy lokalnie w każdym teście (klasowe _hc nie persystuje w v6)
extends GdUnitTestSuite
class_name TestHealthComponent


func _make_hc(max_hp: int = 100) -> HealthComponent:
	var hc := HealthComponent.new()
	hc.max_health = max_hp
	hc._ready()
	return hc


# ── Damage ────────────────────────────────────────────────────

func test_take_damage_reduces_hp() -> void:
	var hc := _make_hc()
	hc.take_damage(30)
	assert_int(hc.current_health).is_equal(70)
	hc.free()


func test_take_damage_cannot_go_below_zero() -> void:
	var hc := _make_hc()
	hc.take_damage(9999)
	assert_int(hc.current_health).is_equal(0)
	hc.free()


func test_full_health_after_ready() -> void:
	var hc := _make_hc(100)
	assert_int(hc.current_health).is_equal(100)
	hc.free()


# ── Heal ──────────────────────────────────────────────────────

func test_heal_restores_hp() -> void:
	var hc := _make_hc()
	hc.take_damage(40)
	hc.heal(20)
	assert_int(hc.current_health).is_equal(80)
	hc.free()


func test_heal_cannot_exceed_max() -> void:
	var hc := _make_hc()
	hc.heal(9999)
	assert_int(hc.current_health).is_equal(100)
	hc.free()


func test_heal_does_nothing_when_dead() -> void:
	var hc := _make_hc()
	hc.take_damage(100)
	hc.heal(50)
	assert_int(hc.current_health).is_equal(0)
	hc.free()


# ── Set max ───────────────────────────────────────────────────

func test_set_max_clips_current_health() -> void:
	var hc := _make_hc()
	hc.take_damage(20)
	hc.set_max(60)
	assert_int(hc.current_health).is_equal(60)
	hc.free()


func test_set_max_does_not_refill() -> void:
	var hc := _make_hc()
	hc.take_damage(40)
	hc.set_max(120)
	assert_int(hc.current_health).is_equal(60)
	hc.free()


# ── Sygnały ───────────────────────────────────────────────────

func test_emits_on_unit_hit_on_damage() -> void:
	# Array jako reference container — GDScript lambdy capture by value, nie by ref
	var hc := _make_hc()
	var counter := [0]
	hc.on_unit_hit.connect(func(): counter[0] += 1)
	hc.take_damage(10)
	assert_int(counter[0]).is_equal(1)\
		.override_failure_message("on_unit_hit nie był emitowany przy take_damage(10)")
	hc.free()


func test_emits_on_unit_died_when_hp_zero() -> void:
	var hc := _make_hc()
	var counter := [0]
	hc.on_unit_died.connect(func(): counter[0] += 1)
	hc.take_damage(100)
	assert_int(counter[0]).is_equal(1)\
		.override_failure_message("on_unit_died nie był emitowany gdy HP=0")
	hc.free()


func test_does_not_emit_died_on_partial_damage() -> void:
	var hc := _make_hc()
	var counter := [0]
	hc.on_unit_died.connect(func(): counter[0] += 1)
	hc.take_damage(50)
	assert_int(counter[0]).is_equal(0)\
		.override_failure_message("on_unit_died emitowany przy częściowych obrażeniach!")
	hc.free()


func test_emits_health_changed_on_damage() -> void:
	var hc := _make_hc()
	var counter := [0]
	hc.on_health_changed.connect(func(_c, _m): counter[0] += 1)
	hc.take_damage(25)
	assert_int(counter[0]).is_equal(1)\
		.override_failure_message("on_health_changed nie był emitowany przy take_damage")
	hc.free()


# ── is_alive ──────────────────────────────────────────────────

func test_is_alive_true_when_hp_above_zero() -> void:
	var hc := _make_hc()
	assert_bool(hc.is_alive()).is_true()
	hc.free()


func test_is_alive_false_when_hp_zero() -> void:
	var hc := _make_hc()
	hc.take_damage(100)
	assert_bool(hc.is_alive()).is_false()
	hc.free()


# ── Ratio ─────────────────────────────────────────────────────

func test_health_ratio_full() -> void:
	var hc := _make_hc()
	assert_float(hc.get_health_ratio()).is_equal_approx(1.0, 0.001)
	hc.free()


func test_health_ratio_half() -> void:
	var hc := _make_hc()
	hc.take_damage(50)
	assert_float(hc.get_health_ratio()).is_equal_approx(0.5, 0.001)
	hc.free()
