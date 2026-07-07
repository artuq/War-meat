## WeaponData — dane broni (Resource)
class_name WeaponData
extends Resource

enum Type { RIFLE, SHOTGUN, PISTOL, SMG, SNIPER_RIFLE, MELEE, GRENADE }
enum Tier { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

const TIER_NAMES: Dictionary = {
	Tier.COMMON: "I",
	Tier.UNCOMMON: "II",
	Tier.RARE: "III",
	Tier.EPIC: "IV",
	Tier.LEGENDARY: "V",
}

const TIER_COLORS: Dictionary = {
	Tier.COMMON: Color(0.85, 0.85, 0.85),      # biały
	Tier.UNCOMMON: Color(0.3, 0.85, 0.3),       # zielony
	Tier.RARE: Color(0.3, 0.5, 1.0),            # niebieski
	Tier.EPIC: Color(0.7, 0.3, 0.9),            # fioletowy
	Tier.LEGENDARY: Color(1.0, 0.8, 0.2),       # złoty
}

const TIER_MULTIPLIERS: Dictionary = {
	Tier.COMMON: 1.0,
	Tier.UNCOMMON: 1.25,
	Tier.RARE: 1.5,
	Tier.EPIC: 1.85,
	Tier.LEGENDARY: 2.25,
}

@export var type: Type = Type.RIFLE
@export var tier: Tier = Tier.COMMON
@export var weapon_name: String = "Karabin"
@export var damage: int = 10
@export var fire_rate: float = 2.0        # strzały/s
@export var projectile_count: int = 1     # ilość pocisków na strzał
@export var spread_angle: float = 0.0     # rozrzut w radianach
@export var projectile_speed: float = 250.0
@export var attack_range: float = 120.0
@export var cost: int = 0                 # cena w sklepie
@export var texture_path: String = ""     # ścieżka do sprite'a broni


static func create_rifle() -> WeaponData:
	var w := WeaponData.new()
	w.type = Type.RIFLE
	w.weapon_name = "Karabin"
	w.damage = 8
	w.fire_rate = 3.0
	w.projectile_count = 1
	w.spread_angle = 0.05
	w.projectile_speed = 280.0
	w.attack_range = 140.0
	w.cost = 0
	w.texture_path = "res://assets/sprites/weapons/rifle.png"
	return w


static func create_shotgun() -> WeaponData:
	var w := WeaponData.new()
	w.type = Type.SHOTGUN
	w.weapon_name = "Strzelba"
	w.damage = 6
	w.fire_rate = 1.2
	w.projectile_count = 5
	w.spread_angle = 0.45
	w.projectile_speed = 200.0
	w.attack_range = 80.0
	w.cost = 120
	w.texture_path = "res://assets/sprites/weapons/shotgun.png"
	return w


static func create_pistol() -> WeaponData:
	var w := WeaponData.new()
	w.type = Type.PISTOL
	w.weapon_name = "Pistolet"
	w.damage = 15
	w.fire_rate = 1.5
	w.projectile_count = 1
	w.spread_angle = 0.02
	w.projectile_speed = 320.0
	w.attack_range = 160.0
	w.cost = 80
	w.texture_path = "res://assets/sprites/weapons/pistol.png"
	return w


static func create_smg() -> WeaponData:
	var w := WeaponData.new()
	w.type = Type.SMG
	w.weapon_name = "SMG"
	w.damage = 5
	w.fire_rate = 6.0
	w.projectile_count = 1
	w.spread_angle = 0.12
	w.projectile_speed = 260.0
	w.attack_range = 100.0
	w.cost = 90
	w.texture_path = "res://assets/sprites/weapons/smg.png"
	return w


static func create_sniper_rifle() -> WeaponData:
	var w := WeaponData.new()
	w.type = Type.SNIPER_RIFLE
	w.weapon_name = "Snajperka"
	w.damage = 35
	w.fire_rate = 0.8
	w.projectile_count = 1
	w.spread_angle = 0.0
	w.projectile_speed = 450.0
	w.attack_range = 250.0
	w.cost = 150
	w.texture_path = "res://assets/sprites/weapons/sniper_rifle.png"
	return w


static func create_melee() -> WeaponData:
	var w := WeaponData.new()
	w.type = Type.MELEE
	w.weapon_name = "Broń biała"
	w.damage = 40
	w.fire_rate = 2.5
	w.projectile_count = 1
	w.spread_angle = 0.0
	w.projectile_speed = 600.0
	w.attack_range = 45.0
	w.cost = 60
	w.texture_path = "res://assets/sprites/weapons/knife.png"
	return w


static func create_grenade() -> WeaponData:
	var w := WeaponData.new()
	w.type = Type.GRENADE
	w.weapon_name = "Granatnik"
	w.damage = 25
	w.fire_rate = 0.6
	w.projectile_count = 4
	w.spread_angle = 0.6
	w.projectile_speed = 180.0
	w.attack_range = 130.0
	w.cost = 130
	w.texture_path = "res://assets/sprites/weapons/grenade_launcher.png"
	return w


static func _create_base(weapon_type: Type) -> WeaponData:
	match weapon_type:
		Type.RIFLE: return create_rifle()
		Type.SHOTGUN: return create_shotgun()
		Type.PISTOL: return create_pistol()
		Type.SMG: return create_smg()
		Type.SNIPER_RIFLE: return create_sniper_rifle()
		Type.MELEE: return create_melee()
		Type.GRENADE: return create_grenade()
	return create_rifle()


static func create_tiered(weapon_type: Type, t: Tier) -> WeaponData:
	var w := _create_base(weapon_type)
	w.tier = t
	var mult: float = TIER_MULTIPLIERS.get(t, 1.0)
	w.damage = int(w.damage * mult)
	w.fire_rate = w.fire_rate * (1.0 + (mult - 1.0) * 0.3)
	w.attack_range = w.attack_range * (1.0 + (mult - 1.0) * 0.2)
	if t != Tier.COMMON:
		w.weapon_name = "%s T%s" % [w.weapon_name, TIER_NAMES[t]]
		w.cost = int(w.cost * mult)
	return w


# Tier probability config — data-driven, easy to tweak (ref: brotato-clone-4 global.gd)
# Format: { min_wave: int, legendary: float, epic: float, rare: float, uncommon: float }
# Common fills the remainder. Chances are cumulative thresholds.
const TIER_PROBABILITY_CONFIG: Array = [
	{ "min_wave": 5, "legendary": 0.05, "epic": 0.15, "rare": 0.35, "uncommon": 0.60 },
	{ "min_wave": 3, "legendary": 0.00, "epic": 0.02, "rare": 0.12, "uncommon": 0.35 },
	{ "min_wave": 0, "legendary": 0.00, "epic": 0.00, "rare": 0.05, "uncommon": 0.20 },
]

static func get_random_tier_for_wave(wave: int, luck: float = 0.0) -> Tier:
	# Find the right config bracket for this wave
	var cfg: Dictionary = TIER_PROBABILITY_CONFIG[-1]
	for entry in TIER_PROBABILITY_CONFIG:
		if wave >= entry["min_wave"]:
			cfg = entry
			break
	# Luck adds a small bonus to non-common chances (ref: brotato-clone-4)
	var luck_mult := 1.0 + clampf(luck / 200.0, 0.0, 0.5)
	var roll: float = randf()
	if roll < cfg["legendary"] * luck_mult: return Tier.LEGENDARY
	if roll < cfg["epic"]      * luck_mult: return Tier.EPIC
	if roll < cfg["rare"]      * luck_mult: return Tier.RARE
	if roll < cfg["uncommon"]  * luck_mult: return Tier.UNCOMMON
	return Tier.COMMON
