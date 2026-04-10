## WeaponData — dane broni (Resource)
class_name WeaponData
extends Resource

enum Type { RIFLE, SHOTGUN, PISTOL }

@export var type: Type = Type.RIFLE
@export var weapon_name: String = "Karabin"
@export var damage: int = 10
@export var fire_rate: float = 2.0        # strzały/s
@export var projectile_count: int = 1     # ilość pocisków na strzał
@export var spread_angle: float = 0.0     # rozrzut w radianach
@export var projectile_speed: float = 250.0
@export var attack_range: float = 120.0
@export var cost: int = 0                 # cena w sklepie


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
	return w
