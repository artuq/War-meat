## PassiveItem — pasywny przedmiot do siatki ekwipunku (max 8 slotów)
class_name PassiveItem
extends Resource

enum StatType { LUCK, SPEED, ARMOR, RANGE, FIRE_RATE, DAMAGE }
enum SynergyTag { NONE, SPEED, DEFENSE, OFFENSE }

@export var id: String = ""
@export var item_name: String = ""
@export var description: String = ""
@export var cost: int = 100
@export var stat_type: StatType = StatType.LUCK
@export var stat_value: float = 0.0
@export var synergy_tag: SynergyTag = SynergyTag.NONE
@export var icon_color: Color = Color.WHITE


static func create_lucky_charm() -> PassiveItem:
	var p := PassiveItem.new()
	p.id = "lucky_charm"
	p.item_name = "Talizman Szczęścia"
	p.description = "+15 Luck (kryty, złoto)"
	p.cost = 100
	p.stat_type = StatType.LUCK
	p.stat_value = 15.0
	p.synergy_tag = SynergyTag.OFFENSE
	p.icon_color = Color(1.0, 0.85, 0.2)
	return p


static func create_speed_amulet() -> PassiveItem:
	var p := PassiveItem.new()
	p.id = "speed_amulet"
	p.item_name = "Amulet Szybkości"
	p.description = "+12% SPD"
	p.cost = 90
	p.stat_type = StatType.SPEED
	p.stat_value = 0.12
	p.synergy_tag = SynergyTag.SPEED
	p.icon_color = Color(0.3, 0.8, 1.0)
	return p


static func create_steel_armor() -> PassiveItem:
	var p := PassiveItem.new()
	p.id = "steel_armor"
	p.item_name = "Stalowy Pancerz"
	p.description = "+25 HP max"
	p.cost = 110
	p.stat_type = StatType.ARMOR
	p.stat_value = 25.0
	p.synergy_tag = SynergyTag.DEFENSE
	p.icon_color = Color(0.6, 0.6, 0.7)
	return p


static func create_scope() -> PassiveItem:
	var p := PassiveItem.new()
	p.id = "scope"
	p.item_name = "Lunetka"
	p.description = "+15% zasięg"
	p.cost = 85
	p.stat_type = StatType.RANGE
	p.stat_value = 0.15
	p.synergy_tag = SynergyTag.OFFENSE
	p.icon_color = Color(0.9, 0.3, 0.3)
	return p


static func create_adrenaline() -> PassiveItem:
	var p := PassiveItem.new()
	p.id = "adrenaline"
	p.item_name = "Adrenalina"
	p.description = "+10% szybkość ognia"
	p.cost = 95
	p.stat_type = StatType.FIRE_RATE
	p.stat_value = 0.10
	p.synergy_tag = SynergyTag.SPEED
	p.icon_color = Color(1.0, 0.4, 0.1)
	return p


static func create_combat_knife() -> PassiveItem:
	var p := PassiveItem.new()
	p.id = "combat_knife"
	p.item_name = "Nóż Bojowy"
	p.description = "+12% DMG"
	p.cost = 105
	p.stat_type = StatType.DAMAGE
	p.stat_value = 0.12
	p.synergy_tag = SynergyTag.OFFENSE
	p.icon_color = Color(0.8, 0.2, 0.2)
	return p


static func create_kevlar_vest() -> PassiveItem:
	var p := PassiveItem.new()
	p.id = "kevlar_vest"
	p.item_name = "Kamizelka Kevlarowa"
	p.description = "+15 HP max"
	p.cost = 75
	p.stat_type = StatType.ARMOR
	p.stat_value = 15.0
	p.synergy_tag = SynergyTag.DEFENSE
	p.icon_color = Color(0.4, 0.5, 0.3)
	return p


static func create_energy_drink() -> PassiveItem:
	var p := PassiveItem.new()
	p.id = "energy_drink"
	p.item_name = "Napój Energetyczny"
	p.description = "+8% SPD, +5% fire rate"
	p.cost = 80
	p.stat_type = StatType.SPEED
	p.stat_value = 0.08
	p.synergy_tag = SynergyTag.SPEED
	p.icon_color = Color(0.2, 1.0, 0.5)
	return p


## All available passive items for shop rotation
static func get_all_items() -> Array[PassiveItem]:
	return [
		create_lucky_charm(),
		create_speed_amulet(),
		create_steel_armor(),
		create_scope(),
		create_adrenaline(),
		create_combat_knife(),
		create_kevlar_vest(),
		create_energy_drink(),
	]
