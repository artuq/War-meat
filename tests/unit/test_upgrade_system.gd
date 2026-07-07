## TestUpgradeSystem — testy upgrade panelu i run_stat_bonuses
extends GdUnitTestSuite
class_name TestUpgradeSystem


func before_each() -> void:
	# Reset pełny — wyczyść wszystkie możliwe bonusy
	GameManager.run_stat_bonuses.clear()
	GameManager.passive_items.clear()
	GameManager.active_synergies.clear()


# ── UpgradeData pool ──────────────────────────────────────────

func test_upgrade_pool_not_empty() -> void:
	var pool := UpgradeData.get_all_upgrades()
	assert_array(pool).is_not_empty()


func test_all_upgrades_have_nonzero_value() -> void:
	for upgrade in UpgradeData.get_all_upgrades():
		assert_float(upgrade.stat_value)\
			.is_greater(0.0)\
			.override_failure_message("Upgrade '%s' ma stat_value=0" % upgrade.upgrade_name)


func test_all_upgrades_have_valid_id() -> void:
	var seen_ids: Array[String] = []
	for upgrade in UpgradeData.get_all_upgrades():
		assert_str(upgrade.id).is_not_empty()
		assert_array(seen_ids)\
			.not_contains(upgrade.id)\
			.override_failure_message("Duplikat upgrade id: '%s'" % upgrade.id)
		seen_ids.append(upgrade.id)


func test_all_rarities_represented() -> void:
	var has_common := false
	var has_rare := false
	var has_epic := false
	for u in UpgradeData.get_all_upgrades():
		if u.rarity == UpgradeData.Rarity.COMMON:  has_common = true
		if u.rarity == UpgradeData.Rarity.RARE:    has_rare = true
		if u.rarity == UpgradeData.Rarity.EPIC:    has_epic = true
	assert_bool(has_common).is_true()
	assert_bool(has_rare).is_true()
	assert_bool(has_epic).is_true()


# ── add_run_upgrade accumulates ───────────────────────────────

func test_add_run_upgrade_stores_bonus() -> void:
	GameManager.run_stat_bonuses.clear()  # explicit — before_each może nie zawsze działać
	var upgrade := UpgradeData.new()
	upgrade.stat_type = UpgradeData.StatType.DAMAGE
	upgrade.stat_value = 0.10

	GameManager.add_run_upgrade(upgrade)

	assert_float(GameManager.get_run_bonus(UpgradeData.StatType.DAMAGE))\
		.is_equal_approx(0.10, 0.001)


func test_add_multiple_same_type_accumulates() -> void:
	GameManager.run_stat_bonuses.clear()
	var u1 := UpgradeData.new()
	u1.stat_type = UpgradeData.StatType.SPEED
	u1.stat_value = 0.05
	var u2 := UpgradeData.new()
	u2.stat_type = UpgradeData.StatType.SPEED
	u2.stat_value = 0.10

	GameManager.add_run_upgrade(u1)
	GameManager.add_run_upgrade(u2)

	assert_float(GameManager.get_run_bonus(UpgradeData.StatType.SPEED))\
		.is_equal_approx(0.15, 0.001)


func test_different_types_dont_interfere() -> void:
	GameManager.run_stat_bonuses.clear()
	var dmg := UpgradeData.new()
	dmg.stat_type = UpgradeData.StatType.DAMAGE
	dmg.stat_value = 0.10
	var spd := UpgradeData.new()
	spd.stat_type = UpgradeData.StatType.SPEED
	spd.stat_value = 0.05

	GameManager.add_run_upgrade(dmg)
	# SPEED nie zmienione po dodaniu DAMAGE upgrade
	assert_float(GameManager.get_run_bonus(UpgradeData.StatType.SPEED))\
		.is_equal_approx(0.0, 0.001)\
		.override_failure_message("DAMAGE upgrade zmodyfikował SPEED — błąd izolacji!")

	GameManager.add_run_upgrade(spd)
	# DAMAGE nie zmienione po dodaniu SPEED upgrade
	assert_float(GameManager.get_run_bonus(UpgradeData.StatType.DAMAGE))\
		.is_equal_approx(0.10, 0.001)\
		.override_failure_message("SPEED upgrade zmodyfikował DAMAGE — błąd izolacji!")


func test_run_bonuses_cleared_on_mission_start() -> void:
	var upgrade := UpgradeData.new()
	upgrade.stat_type = UpgradeData.StatType.DAMAGE
	upgrade.stat_value = 0.20
	GameManager.add_run_upgrade(upgrade)

	GameManager.start_mission(5)

	assert_float(GameManager.get_run_bonus(UpgradeData.StatType.DAMAGE))\
		.is_equal(0.0)\
		.override_failure_message("run_stat_bonuses nie zostały wyczyszczone przy start_mission!")


# ── Rarity colors defined ─────────────────────────────────────

func test_rarity_color_common_is_gray() -> void:
	var color := UpgradeData.get_rarity_color(UpgradeData.Rarity.COMMON)
	assert_float(color.r).is_greater(0.7)
	assert_float(color.g).is_greater(0.7)
	assert_float(color.b).is_greater(0.7)


func test_rarity_weight_common_highest() -> void:
	var w_common := UpgradeData.get_rarity_weight(UpgradeData.Rarity.COMMON)
	var w_epic   := UpgradeData.get_rarity_weight(UpgradeData.Rarity.EPIC)
	assert_float(w_common).is_greater(w_epic)
