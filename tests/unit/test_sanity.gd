## TestSanity — minimalne testy sprawdzające że framework działa
## Zero zewnętrznych zależności — tylko GDScript math
extends GdUnitTestSuite
class_name TestSanity


func test_basic_math_passes() -> void:
	assert_int(2 + 2).is_equal(4)


func test_string_not_empty() -> void:
	assert_str("hello").is_not_empty()


func test_array_contains() -> void:
	var arr := [1, 2, 3]
	assert_array(arr).contains(2)


func test_float_approx() -> void:
	assert_float(0.1 + 0.2).is_equal_approx(0.3, 0.001)


func test_bool_true() -> void:
	assert_bool(true).is_true()


func test_wave_data_loads() -> void:
	var data = load("res://src/data/waves/wave_default.tres")
	assert_object(data).is_not_null()


func test_upgrade_data_pool_not_empty() -> void:
	var pool := UpgradeData.get_all_upgrades()
	assert_array(pool).is_not_empty()


func test_health_component_new() -> void:
	var hc := HealthComponent.new()
	assert_object(hc).is_not_null()
	assert_int(hc.max_health).is_equal(100)
	hc.free()
