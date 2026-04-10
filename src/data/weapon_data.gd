## WeaponData — dane broni (Resource)
class_name WeaponData
extends Resource

enum Type { RIFLE, SHOTGUN, PISTOL, SMG, SNIPER_RIFLE, MELEE, GRENADE }

@export var type: Type = Type.RIFLE
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
	w.texture_path = "res://assets/Gun collection/PNG/Riffle-01.png"
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
	w.texture_path = "res://assets/Gun collection/PNG/Shut gun -01.png"
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
	w.texture_path = ""
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
	w.texture_path = "res://assets/Gun collection/PNG/SMG.png"
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
	w.texture_path = "res://assets/Gun collection/PNG/Snipers -01.png"
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
	w.texture_path = "res://assets/Gun collection/PNG/Melee -01.png"
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
	w.texture_path = "res://assets/Gun collection/PNG/Grenade -01.png"
	return w
