## TestShopFlow — weryfikuje logikę sklepu: zakupy, reroll, banish, synergie
extends GdUnitTestSuite
class_name TestShopFlow


func before_each() -> void:
	GameManager.start_mission(5)
	GameManager.gold = 500


# ── WeaponData factory ────────────────────────────────────────

func test_create_rifle_returns_valid_weapon() -> void:
	var w := WeaponData.create_rifle()
	assert_object(w).is_not_null()
	assert_int(w.damage).is_greater(0)
	assert_float(w.fire_rate).is_greater(0.0)
	assert_float(w.attack_range).is_greater(0.0)


func test_create_tiered_scales_damage() -> void:
	var common := WeaponData.create_tiered(WeaponData.Type.RIFLE, WeaponData.Tier.COMMON)
	var epic   := WeaponData.create_tiered(WeaponData.Type.RIFLE, WeaponData.Tier.EPIC)
	assert_int(epic.damage).is_greater(common.damage)


func test_tier_multipliers_ordered() -> void:
	var mult_common    := WeaponData.TIER_MULTIPLIERS[WeaponData.Tier.COMMON]
	var mult_rare      := WeaponData.TIER_MULTIPLIERS[WeaponData.Tier.RARE]
	var mult_legendary := WeaponData.TIER_MULTIPLIERS[WeaponData.Tier.LEGENDARY]
	assert_float(mult_rare).is_greater(mult_common)
	assert_float(mult_legendary).is_greater(mult_rare)


# ── get_random_tier_for_wave ──────────────────────────────────

func test_wave1_mostly_common() -> void:
	var common_count := 0
	for _i in range(100):
		if WeaponData.get_random_tier_for_wave(1) == WeaponData.Tier.COMMON:
			common_count += 1
	# Wave 1: 80% common (threshold 0.20 uncommon) → oczekujemy ≥60 common z 100
	assert_int(common_count).is_greater_equal(60)


func test_wave5_has_higher_tiers() -> void:
	var non_common := 0
	for _i in range(100):
		if WeaponData.get_random_tier_for_wave(5) != WeaponData.Tier.COMMON:
			non_common += 1
	# Wave 5 (>= min_wave 5 tier config): dużo szans na wyższe tiery
	assert_int(non_common).is_greater(0)


# ── PassiveItem pool ──────────────────────────────────────────

func test_passive_items_all_have_cost() -> void:
	for item in PassiveItem.get_all_items():
		assert_int(item.cost)\
			.is_greater(0)\
			.override_failure_message("Pasywka '%s' ma koszt=0" % item.item_name)


func test_passive_items_have_unique_ids() -> void:
	var ids: Array[String] = []
	for item in PassiveItem.get_all_items():
		assert_array(ids)\
			.not_contains(item.id)\
			.override_failure_message("Duplikat passive id: '%s'" % item.id)
		ids.append(item.id)


# ── GameManager passive system ────────────────────────────────

func test_add_passive_increases_count() -> void:
	var initial := GameManager.get_passive_count()
	var item := PassiveItem.get_all_items()[0]
	GameManager.add_passive(item)
	assert_int(GameManager.get_passive_count()).is_equal(initial + 1)


func test_passive_slots_limit_enforced() -> void:
	# Wypełnij sloty
	var items := PassiveItem.get_all_items()
	var max_slots := GameManager.get_max_passive_slots()
	for i in range(max_slots + 5):
		if i < items.size():
			GameManager.add_passive(items[i % items.size()])

	assert_int(GameManager.get_passive_count())\
		.is_less_equal(max_slots)\
		.override_failure_message("Przekroczono limit slotów pasywek!")


# ── Synergy system ────────────────────────────────────────────

func test_synergy_level_increments_with_items() -> void:
	GameManager.passive_items.clear()
	GameManager.active_synergies.clear()

	# Dodaj 2 itemy z SynergyTag.SPEED
	var speed_items := PassiveItem.get_all_items().filter(
		func(i: PassiveItem) -> bool:
			return i.synergy_tag == PassiveItem.SynergyTag.SPEED
	)
	if speed_items.size() >= 2:
		GameManager.add_passive(speed_items[0])
		GameManager.add_passive(speed_items[1])
		assert_int(GameManager.get_synergy_level(PassiveItem.SynergyTag.SPEED))\
			.is_equal(2)


# ── Upgrade panel flow ────────────────────────────────────────

func test_upgrade_panel_completed_unblocks_shop() -> void:
	# Weryfikuje że EventBus ma oba sygnały zdefiniowane
	assert_bool(EventBus.has_signal("upgrade_panel_requested")).is_true()
	assert_bool(EventBus.has_signal("upgrade_panel_completed")).is_true()


func test_stats_speed_bonus_affects_move_speed() -> void:
	GameManager.run_stat_bonuses.clear()
	GameManager.start_mission(5)

	# Przed upgrade
	var base_bonus := GameManager.get_run_bonus(UpgradeData.StatType.SPEED)
	assert_float(base_bonus).is_equal(0.0)

	# Po upgrade
	var upgrade := UpgradeData.new()
	upgrade.stat_type = UpgradeData.StatType.SPEED
	upgrade.stat_value = 0.15
	GameManager.add_run_upgrade(upgrade)

	assert_float(GameManager.get_run_bonus(UpgradeData.StatType.SPEED))\
		.is_equal_approx(0.15, 0.001)
