## GameManager — globalny stan gry
extends Node

# --- Waluta ---
var gold: int = 0
var resources: int = 0

# --- XP / Poziom ---
var xp: int = 0
var level: int = 1
var xp_to_next_level: int = 50

# --- Stan misji ---
var current_wave: int = 0
var total_waves: int = 5
var is_mission_active: bool = false
var current_arena: ArenaModifier = null

# --- Progresja aren ---
var unlocked_arenas: Array[String] = ["jungle"]

# --- Odblokowane klasy ---
var unlocked_classes: Array[String] = ["assault", "sniper", "medic"]

# --- Permanentne ulepszenia ---
var upgrades: Dictionary = {
	"hp_bonus": 0,       # +10 HP per level
	"dmg_bonus": 0,      # +5% DMG per level
	"extra_slot": 0,     # +1 passive slot per level (max 2)
}

const UPGRADE_COSTS: Dictionary = {
	"hp_bonus": [30, 60, 100, 150, 200],
	"dmg_bonus": [25, 50, 80, 120, 180],
	"extra_slot": [80, 160],
}

const SAVE_PATH: String = "user://warmeat_save.json"

# --- Statystyki misji ---
var enemies_killed: int = 0
var gold_earned: int = 0
var max_streak: int = 0
var mission_time: float = 0.0
var _mission_start_ms: int = 0

# --- Kill streak bonusy (tymczasowe, resetowane przy końcu serii) ---
var streak_speed_bonus: float = 0.0    # +% do prędkości squadu
var streak_damage_bonus: float = 0.0   # +% do obrażeń żołnierzy

# --- Upgrade Panel rewards (per-run, między falami) ---
# Mapuje UpgradeData.StatType (int) → skumulowana wartość
var run_stat_bonuses: Dictionary = {}

# --- Mid-run restore ---
var restoring_run: bool = false
var run_data: Dictionary = {}

# --- Ekwipunek (pasywne sloty) ---
const BASE_PASSIVE_SLOTS: int = 8
var passive_items: Array[PassiveItem] = []

# --- Synergie ---
var active_synergies: Dictionary = {}  # {SynergyTag: count}


func _ready() -> void:
	EventBus.loot_collected.connect(_on_loot_collected)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.mission_won.connect(_on_mission_won)
	EventBus.mission_lost.connect(_on_mission_lost)
	EventBus.squad_wiped.connect(_on_squad_wiped)
	load_game()


func start_mission(waves: int = 5) -> void:
	gold = 0
	resources = 0
	current_wave = 0
	total_waves = waves
	enemies_killed = 0
	gold_earned = 0
	xp = 0
	level = 1
	xp_to_next_level = 50
	passive_items.clear()
	active_synergies.clear()
	max_streak = 0
	streak_speed_bonus = 0.0
	streak_damage_bonus = 0.0
	run_stat_bonuses.clear()
	mission_time = 0.0
	_mission_start_ms = Time.get_ticks_msec()
	is_mission_active = true
	EventBus.mission_started.emit()


func get_max_passive_slots() -> int:
	return BASE_PASSIVE_SLOTS + upgrades.get("extra_slot", 0)


func add_passive(item: PassiveItem) -> bool:
	if passive_items.size() >= get_max_passive_slots():
		return false
	passive_items.append(item)
	_update_synergies()
	apply_passives_to_squad()
	return true


func get_passive_count() -> int:
	return passive_items.size()


func has_passive(item_id: String) -> bool:
	for p in passive_items:
		if p.id == item_id:
			return true
	return false


func count_passive(item_id: String) -> int:
	var c: int = 0
	for p in passive_items:
		if p.id == item_id:
			c += 1
	return c


func get_passive_bonus(stat_type: PassiveItem.StatType) -> float:
	var total: float = 0.0
	for p in passive_items:
		if p.stat_type == stat_type:
			total += p.stat_value
	return total


## Dodaje upgrade z UpgradePanel — kumuluje per-run bonus dla danego stat type
func add_run_upgrade(upgrade: UpgradeData) -> void:
	if upgrade == null:
		return
	var key: int = int(upgrade.stat_type)
	run_stat_bonuses[key] = run_stat_bonuses.get(key, 0.0) + upgrade.stat_value
	apply_passives_to_squad()


func get_run_bonus(stat_type: int) -> float:
	return run_stat_bonuses.get(stat_type, 0.0)


func _update_synergies() -> void:
	active_synergies.clear()
	for p in passive_items:
		if p.synergy_tag != PassiveItem.SynergyTag.NONE:
			var tag: int = p.synergy_tag
			active_synergies[tag] = active_synergies.get(tag, 0) + 1


func get_synergy_level(tag: PassiveItem.SynergyTag) -> int:
	return active_synergies.get(int(tag), 0)


func has_synergy_bonus(tag: PassiveItem.SynergyTag) -> bool:
	return get_synergy_level(tag) >= 3


func apply_passives_to_squad() -> void:
	var soldiers := get_tree().get_nodes_in_group("squad")
	for s in soldiers:
		if s is Soldier:
			_apply_passives_to_soldier(s)


func _apply_passives_to_soldier(s: Soldier) -> void:
	# Reset to class base stats
	var sc: SoldierClass = s.soldier_class
	if sc == null:
		return
	s.max_hp = sc.base_hp
	s.move_speed = sc.base_speed
	s.damage_mult = sc.damage_mult
	s.luck = sc.base_luck

	# Apply level bonuses
	s.max_hp += (level - 1) * 10

	# Apply permanent upgrades
	s.max_hp += upgrades.get("hp_bonus", 0) * 10
	s.damage_mult *= 1.0 + upgrades.get("dmg_bonus", 0) * 0.05

	# Apply passive bonuses
	s.luck += get_passive_bonus(PassiveItem.StatType.LUCK)
	s.max_hp += int(get_passive_bonus(PassiveItem.StatType.ARMOR))
	s.move_speed *= 1.0 + get_passive_bonus(PassiveItem.StatType.SPEED)
	s.damage_mult *= 1.0 + get_passive_bonus(PassiveItem.StatType.DAMAGE)

	# Apply weapon stat passives (range, fire_rate) via multipliers
	s.range_mult = 1.0 + get_passive_bonus(PassiveItem.StatType.RANGE)
	s.fire_rate_mult = 1.0 + get_passive_bonus(PassiveItem.StatType.FIRE_RATE)
	s.hp_regen_per_10s = get_passive_bonus(PassiveItem.StatType.HP_REGEN)

	# Apply Upgrade Panel run bonuses (additive na top of passives)
	s.damage_mult *= 1.0 + get_run_bonus(UpgradeData.StatType.DAMAGE)
	s.move_speed *= 1.0 + get_run_bonus(UpgradeData.StatType.SPEED)
	s.max_hp += int(get_run_bonus(UpgradeData.StatType.MAX_HP))
	s.luck += get_run_bonus(UpgradeData.StatType.LUCK)
	s.range_mult *= 1.0 + get_run_bonus(UpgradeData.StatType.RANGE)
	s.fire_rate_mult *= 1.0 + get_run_bonus(UpgradeData.StatType.FIRE_RATE)
	s.armor += int(get_run_bonus(UpgradeData.StatType.ARMOR))
	s.hp_regen_per_10s += get_run_bonus(UpgradeData.StatType.HP_REGEN)
	if s.weapon:
		s._apply_weapon()

	# Synergy bonuses
	if has_synergy_bonus(PassiveItem.SynergyTag.SPEED):
		s.dodge_chance = 0.10  # 10% dodge
	if has_synergy_bonus(PassiveItem.SynergyTag.DEFENSE):
		s.armor = 3  # flat damage reduction
	if has_synergy_bonus(PassiveItem.SynergyTag.OFFENSE):
		s.damage_mult *= 1.15  # +15% DMG

	# Clamp HP
	s.hp = mini(s.hp, s.max_hp)


func get_squad_avg_luck() -> float:
	var soldiers := get_tree().get_nodes_in_group("squad")
	var total_luck: float = 0.0
	var count: int = 0
	for s in soldiers:
		if s is Soldier:
			total_luck += s.luck
			count += 1
	if count == 0:
		return 10.0
	return total_luck / count


func get_gold_bonus_mult() -> float:
	## Luck-based gold bonus: +1% per avg luck point
	var avg_luck: float = get_squad_avg_luck()
	return 1.0 + avg_luck * 0.01


func add_xp(amount: int) -> void:
	xp += amount
	EventBus.xp_gained.emit(amount)
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level = 50 * level
		EventBus.level_up.emit(level)
		_apply_level_bonus()


func _apply_level_bonus() -> void:
	var soldiers := get_tree().get_nodes_in_group("squad")
	for s in soldiers:
		if s is Soldier:
			s.max_hp += 10
			s.hp = mini(s.hp + 10, s.max_hp)


func _on_loot_collected(value: int) -> void:
	var bonus_value: int = int(value * get_gold_bonus_mult())
	gold += bonus_value
	gold_earned += bonus_value


func _on_enemy_killed(_enemy: Node2D, _position: Vector2) -> void:
	enemies_killed += 1


func _on_mission_won() -> void:
	is_mission_active = false
	mission_time = (Time.get_ticks_msec() - _mission_start_ms) / 1000.0
	save_game()


func _on_mission_lost() -> void:
	is_mission_active = false
	mission_time = (Time.get_ticks_msec() - _mission_start_ms) / 1000.0
	save_game()


func _on_squad_wiped() -> void:
	if is_mission_active:
		EventBus.mission_lost.emit()


# --- Ulepszenia permanentne ---

func get_upgrade_level(upgrade_id: String) -> int:
	return upgrades.get(upgrade_id, 0)


func get_upgrade_max(upgrade_id: String) -> int:
	if UPGRADE_COSTS.has(upgrade_id):
		return UPGRADE_COSTS[upgrade_id].size()
	return 0


func get_upgrade_cost(upgrade_id: String) -> int:
	var lvl: int = get_upgrade_level(upgrade_id)
	if not UPGRADE_COSTS.has(upgrade_id):
		return -1
	var costs: Array = UPGRADE_COSTS[upgrade_id]
	if lvl >= costs.size():
		return -1  # maxed
	return costs[lvl]


func buy_upgrade(upgrade_id: String) -> bool:
	var cost: int = get_upgrade_cost(upgrade_id)
	if cost < 0 or resources < cost:
		return false
	resources -= cost
	upgrades[upgrade_id] = get_upgrade_level(upgrade_id) + 1
	save_game()
	return true


# --- Odblokowywanie klas ---

func unlock_class(class_id: String) -> bool:
	if class_id in unlocked_classes:
		return false
	unlocked_classes.append(class_id)
	save_game()
	return true


func is_class_unlocked(class_id: String) -> bool:
	return class_id in unlocked_classes


# --- Save / Load ---

func save_game() -> void:
	var data: Dictionary = {
		"resources": resources,
		"unlocked_arenas": unlocked_arenas,
		"unlocked_classes": unlocked_classes,
		"upgrades": upgrades,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		return
	var data: Dictionary = parsed
	resources = int(data.get("resources", 0))
	var arenas_raw: Variant = data.get("unlocked_arenas", ["jungle"])
	unlocked_arenas.clear()
	if arenas_raw is Array:
		for a in arenas_raw:
			unlocked_arenas.append(str(a))
	var classes_raw: Variant = data.get("unlocked_classes", ["assault", "sniper", "medic"])
	unlocked_classes.clear()
	if classes_raw is Array:
		for c in classes_raw:
			unlocked_classes.append(str(c))
	var upgrades_raw: Variant = data.get("upgrades", {})
	if upgrades_raw is Dictionary:
		for key in upgrades_raw:
			upgrades[str(key)] = int(upgrades_raw[key])
