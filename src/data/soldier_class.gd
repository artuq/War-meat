## SoldierClass — definicja klasy żołnierza
class_name SoldierClass
extends Resource

enum ClassType { ASSAULT, SNIPER, MEDIC, ENGINEER, SCOUT, HEAVY }

@export var class_type: ClassType = ClassType.ASSAULT
@export var class_name_str: String = "Szturmowiec"
@export var base_hp: int = 100
@export var base_speed: float = 80.0
@export var damage_mult: float = 1.0
@export var default_weapon_type: WeaponData.Type = WeaponData.Type.RIFLE
@export var draw_color: Color = Color(0.3, 0.5, 0.9)
@export var draw_radius: float = 6.0
@export var base_luck: float = 10.0


static func create_assault() -> SoldierClass:
	var c := SoldierClass.new()
	c.class_type = ClassType.ASSAULT
	c.class_name_str = "Szturmowiec"
	c.base_hp = 100
	c.base_speed = 80.0
	c.damage_mult = 1.0
	c.default_weapon_type = WeaponData.Type.RIFLE
	c.draw_color = Color(0.3, 0.5, 0.9)
	c.draw_radius = 6.0
	c.base_luck = 10.0
	return c


static func create_sniper() -> SoldierClass:
	var c := SoldierClass.new()
	c.class_type = ClassType.SNIPER
	c.class_name_str = "Snajper"
	c.base_hp = 60
	c.base_speed = 65.0
	c.damage_mult = 1.8
	c.default_weapon_type = WeaponData.Type.PISTOL
	c.draw_color = Color(0.9, 0.8, 0.2)
	c.draw_radius = 5.0
	c.base_luck = 15.0
	return c


static func create_medic() -> SoldierClass:
	var c := SoldierClass.new()
	c.class_type = ClassType.MEDIC
	c.class_name_str = "Medyk"
	c.base_hp = 80
	c.base_speed = 75.0
	c.damage_mult = 0.6
	c.default_weapon_type = WeaponData.Type.PISTOL
	c.draw_color = Color(0.2, 0.85, 0.4)
	c.draw_radius = 6.0
	c.base_luck = 20.0
	return c


static func get_default_weapon(sc: SoldierClass) -> WeaponData:
	match sc.default_weapon_type:
		WeaponData.Type.RIFLE:
			return WeaponData.create_rifle()
		WeaponData.Type.SHOTGUN:
			return WeaponData.create_shotgun()
		WeaponData.Type.PISTOL:
			return WeaponData.create_pistol()
	return WeaponData.create_rifle()


static func create_engineer() -> SoldierClass:
	var c := SoldierClass.new()
	c.class_type = ClassType.ENGINEER
	c.class_name_str = "Inżynier"
	c.base_hp = 90
	c.base_speed = 70.0
	c.damage_mult = 0.8
	c.default_weapon_type = WeaponData.Type.SHOTGUN
	c.draw_color = Color(0.9, 0.5, 0.1)
	c.draw_radius = 6.0
	c.base_luck = 12.0
	return c


static func create_scout() -> SoldierClass:
	var c := SoldierClass.new()
	c.class_type = ClassType.SCOUT
	c.class_name_str = "Zwiadowca"
	c.base_hp = 55
	c.base_speed = 110.0
	c.damage_mult = 1.2
	c.default_weapon_type = WeaponData.Type.PISTOL
	c.draw_color = Color(0.4, 0.9, 0.9)
	c.draw_radius = 5.0
	c.base_luck = 25.0
	return c


static func create_heavy() -> SoldierClass:
	var c := SoldierClass.new()
	c.class_type = ClassType.HEAVY
	c.class_name_str = "Ciężki"
	c.base_hp = 160
	c.base_speed = 50.0
	c.damage_mult = 1.4
	c.default_weapon_type = WeaponData.Type.SHOTGUN
	c.draw_color = Color(0.6, 0.3, 0.3)
	c.draw_radius = 8.0
	c.base_luck = 5.0
	return c
