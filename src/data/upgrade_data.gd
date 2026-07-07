## UpgradeData — pojedynczy upgrade z UpgradePanel (level-up reward)
## Brotato-clone ref: scenes/ui/upgrade_panel — losowane między falami, wybierane darmowo.
class_name UpgradeData
extends Resource

enum StatType { DAMAGE, SPEED, MAX_HP, LUCK, RANGE, FIRE_RATE, ARMOR, HP_REGEN }
enum Rarity { COMMON, RARE, EPIC }

@export var id: String = ""
@export var upgrade_name: String = ""
@export var description: String = ""
@export var stat_type: StatType = StatType.DAMAGE
@export var stat_value: float = 0.05
@export var rarity: Rarity = Rarity.COMMON


const _RARITY_COLORS: Dictionary = {
	Rarity.COMMON: Color(0.85, 0.85, 0.85),
	Rarity.RARE: Color(0.3, 0.55, 1.0),
	Rarity.EPIC: Color(0.75, 0.3, 0.95),
}

const _RARITY_WEIGHTS: Dictionary = {
	Rarity.COMMON: 6.0,
	Rarity.RARE: 3.0,
	Rarity.EPIC: 1.0,
}


static func get_rarity_color(r: Rarity) -> Color:
	return _RARITY_COLORS.get(r, Color.WHITE)


static func get_rarity_weight(r: Rarity) -> float:
	return _RARITY_WEIGHTS.get(r, 1.0)


static func _make(id_: String, name_: String, desc: String, type: StatType, value: float, rarity_: Rarity) -> UpgradeData:
	var u := UpgradeData.new()
	u.id = id_
	u.upgrade_name = name_
	u.description = desc
	u.stat_type = type
	u.stat_value = value
	u.rarity = rarity_
	return u


## Wszystkie dostępne upgrade'y. Pool, z którego losuje UpgradePanel.
static func get_all_upgrades() -> Array[UpgradeData]:
	return [
		# DAMAGE
		_make("dmg_c", "Mocniejsze pociski", "+5% obrażeń", StatType.DAMAGE, 0.05, Rarity.COMMON),
		_make("dmg_r", "Wojenne treningi", "+10% obrażeń", StatType.DAMAGE, 0.10, Rarity.RARE),
		_make("dmg_e", "Beresker", "+15% obrażeń", StatType.DAMAGE, 0.15, Rarity.EPIC),
		# SPEED
		_make("spd_c", "Lekkie buty", "+5% prędkości", StatType.SPEED, 0.05, Rarity.COMMON),
		_make("spd_r", "Sprinter", "+10% prędkości", StatType.SPEED, 0.10, Rarity.RARE),
		# MAX_HP
		_make("hp_c", "Konserwy", "+10 max HP", StatType.MAX_HP, 10.0, Rarity.COMMON),
		_make("hp_r", "Pancerz", "+25 max HP", StatType.MAX_HP, 25.0, Rarity.RARE),
		_make("hp_e", "Reinforced", "+50 max HP", StatType.MAX_HP, 50.0, Rarity.EPIC),
		# LUCK
		_make("luck_c", "Talizman", "+5 szczęścia", StatType.LUCK, 5.0, Rarity.COMMON),
		_make("luck_r", "Czterolistna koniczyna", "+15 szczęścia", StatType.LUCK, 15.0, Rarity.RARE),
		# RANGE
		_make("rng_c", "Lornetka", "+5% zasięgu", StatType.RANGE, 0.05, Rarity.COMMON),
		_make("rng_r", "Snajperskie celowniki", "+12% zasięgu", StatType.RANGE, 0.12, Rarity.RARE),
		# FIRE_RATE
		_make("fr_c", "Wydajny mechanizm", "+5% szybkości ognia", StatType.FIRE_RATE, 0.05, Rarity.COMMON),
		_make("fr_r", "Pełen automat", "+12% szybkości ognia", StatType.FIRE_RATE, 0.12, Rarity.RARE),
		# ARMOR
		_make("arm_c", "Kamizelka", "+1 pancerza", StatType.ARMOR, 1.0, Rarity.COMMON),
		_make("arm_r", "Płytowa kamizelka", "+3 pancerza", StatType.ARMOR, 3.0, Rarity.RARE),
		# HP_REGEN
		_make("regen_c", "Apteczka polowa", "+1 HP/10s regen", StatType.HP_REGEN, 1.0, Rarity.COMMON),
		_make("regen_r", "Auto-medkit", "+3 HP/10s regen", StatType.HP_REGEN, 3.0, Rarity.RARE),
	]
