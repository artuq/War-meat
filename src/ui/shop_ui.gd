## ShopUI — sklep między falami z bronią, pasywkami i rekrutacją
extends CanvasLayer

signal closed

@onready var panel: PanelContainer = $Panel
@onready var item_list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/ItemList
@onready var gold_label: Label = $Panel/VBoxContainer/GoldLabel
@onready var continue_button: Button = $Panel/VBoxContainer/ContinueButton

var consumable_items: Array[Dictionary] = [
	{"id": "medkit", "name": "Apteczka", "cost": 80, "description": "Leczy +30 HP", "type": "consumable"},
]

var weapon_items: Array[Dictionary] = [
	{"id": "weapon_shotgun", "name": "Strzelba", "cost": 100, "description": "5 pocisków, krótki zasięg", "type": "weapon"},
	{"id": "weapon_pistol", "name": "Pistolet", "cost": 70, "description": "Wysoka celność, duży zasięg", "type": "weapon"},
	{"id": "weapon_rifle", "name": "Karabin", "cost": 50, "description": "Szybki ogień, średni dmg", "type": "weapon"},
]

var recruit_classes: Array[Dictionary] = []

## Passive items offered this shop visit (random 3-4 from pool)
var _current_passive_offers: Array[PassiveItem] = []


func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue)
	EventBus.shop_opened.connect(_open)


func _build_recruit_classes() -> void:
	recruit_classes.clear()
	recruit_classes.append({"name": "Szturmowiec", "factory": "create_assault", "description": "HP 100, DMG ×1.0, Karabin"})
	recruit_classes.append({"name": "Snajper", "factory": "create_sniper", "description": "HP 60, DMG ×1.8, Pistolet"})
	recruit_classes.append({"name": "Medyk", "factory": "create_medic", "description": "HP 80, Leczy oddział, Pistolet"})
	if GameManager.is_class_unlocked("engineer"):
		recruit_classes.append({"name": "Inżynier", "factory": "create_engineer", "description": "HP 90, DMG ×0.8, Strzelba"})
	if GameManager.is_class_unlocked("scout"):
		recruit_classes.append({"name": "Zwiadowca", "factory": "create_scout", "description": "HP 55, SPD 110, Luck 25"})
	if GameManager.is_class_unlocked("heavy"):
		recruit_classes.append({"name": "Ciężki", "factory": "create_heavy", "description": "HP 160, DMG ×1.4, wolny"})


func _open() -> void:
	visible = true
	_build_recruit_classes()
	_roll_passive_offers()
	_refresh_ui()
	get_tree().paused = true


func _roll_passive_offers() -> void:
	_current_passive_offers.clear()
	var all_items := PassiveItem.get_all_items()
	all_items.shuffle()
	var offer_count: int = mini(4, all_items.size())
	for i in offer_count:
		_current_passive_offers.append(all_items[i])


func _get_recruit_cost() -> int:
	var squad := _get_squad()
	if squad == null:
		return 150
	return 150 + (squad.get_soldier_count() - 1) * 75


func _get_squad() -> Squad:
	var arena := get_tree().current_scene
	return arena.get_node_or_null("Squad") as Squad


func _refresh_ui() -> void:
	for child in item_list.get_children():
		child.queue_free()

	var slots_text: String = "Pasywki: %d/%d" % [GameManager.get_passive_count(), GameManager.get_max_passive_slots()]
	gold_label.text = "Złoto: $%d  |  LV.%d  |  %s" % [GameManager.gold, GameManager.level, slots_text]

	# --- Rekrutacja ---
	var squad := _get_squad()
	var can_recruit := squad != null and squad.get_soldier_count() < Squad.MAX_SOLDIERS
	if can_recruit:
		var header := Label.new()
		header.text = "── REKRUTACJA ──"
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_list.add_child(header)

		var cost := _get_recruit_cost()
		for rc in recruit_classes:
			var btn := Button.new()
			btn.text = "%s  $%d  —  %s" % [rc.name, cost, rc.description]
			btn.disabled = GameManager.gold < cost
			btn.pressed.connect(_recruit.bind(rc.factory, cost))
			item_list.add_child(btn)

	# --- Bronie ---
	var wep_header := Label.new()
	wep_header.text = "── BROŃ ──"
	wep_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_list.add_child(wep_header)

	for item in weapon_items:
		var btn := Button.new()
		var owned: bool = _all_have_weapon(item.id)
		if owned:
			btn.text = "%s  —  [POSIADANY]" % item.name
			btn.disabled = true
		else:
			btn.text = "%s  $%d  —  %s" % [item.name, item.cost, item.description]
			btn.disabled = GameManager.gold < item.cost
		btn.pressed.connect(_buy_weapon.bind(item))
		item_list.add_child(btn)

	# --- Pasywne przedmioty ---
	var passive_header := Label.new()
	passive_header.text = "── PASYWKI (%d/%d) ──" % [GameManager.get_passive_count(), GameManager.get_max_passive_slots()]
	passive_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_list.add_child(passive_header)

	var slots_full: bool = GameManager.get_passive_count() >= GameManager.get_max_passive_slots()
	for p_item in _current_passive_offers:
		var btn := Button.new()
		var count: int = GameManager.count_passive(p_item.id)
		var count_str: String = "  [×%d]" % count if count > 0 else ""
		var synergy_str: String = ""
		if p_item.synergy_tag != PassiveItem.SynergyTag.NONE:
			var tag_name: String = _get_synergy_name(p_item.synergy_tag)
			var slvl: int = GameManager.get_synergy_level(p_item.synergy_tag)
			synergy_str = "  [%s %d/3]" % [tag_name, slvl]
		btn.text = "%s  $%d  —  %s%s%s" % [p_item.item_name, p_item.cost, p_item.description, count_str, synergy_str]
		btn.disabled = GameManager.gold < p_item.cost or slots_full
		btn.pressed.connect(_buy_passive.bind(p_item))
		item_list.add_child(btn)

	# --- Konsumable ---
	var cons_header := Label.new()
	cons_header.text = "── KONSUMABLE ──"
	cons_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_list.add_child(cons_header)

	for item in consumable_items:
		var btn := Button.new()
		btn.text = "%s  $%d  —  %s" % [item.name, item.cost, item.description]
		btn.disabled = GameManager.gold < item.cost
		btn.pressed.connect(_buy_consumable.bind(item))
		item_list.add_child(btn)

	# --- Active synergies ---
	var has_any_synergy := false
	for tag in [PassiveItem.SynergyTag.SPEED, PassiveItem.SynergyTag.DEFENSE, PassiveItem.SynergyTag.OFFENSE]:
		var lvl: int = GameManager.get_synergy_level(tag)
		if lvl > 0:
			if not has_any_synergy:
				var syn_header := Label.new()
				syn_header.text = "── SYNERGIE ──"
				syn_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				item_list.add_child(syn_header)
				has_any_synergy = true
			var lbl := Label.new()
			var bonus_str: String = " ✓ AKTYWNA!" if lvl >= 3 else ""
			lbl.text = "  %s: %d/3%s" % [_get_synergy_name(tag), lvl, bonus_str]
			lbl.add_theme_font_size_override("font_size", 11)
			if lvl >= 3:
				lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
			item_list.add_child(lbl)


func _get_synergy_name(tag: PassiveItem.SynergyTag) -> String:
	match tag:
		PassiveItem.SynergyTag.SPEED: return "Szybkość"
		PassiveItem.SynergyTag.DEFENSE: return "Obrona"
		PassiveItem.SynergyTag.OFFENSE: return "Ofensywa"
	return "?"


func _recruit(factory_name: String, cost: int) -> void:
	if GameManager.gold < cost:
		return
	var squad := _get_squad()
	if squad == null:
		return
	var sc: SoldierClass
	match factory_name:
		"create_assault":
			sc = SoldierClass.create_assault()
		"create_sniper":
			sc = SoldierClass.create_sniper()
		"create_medic":
			sc = SoldierClass.create_medic()
		"create_engineer":
			sc = SoldierClass.create_engineer()
		"create_scout":
			sc = SoldierClass.create_scout()
		"create_heavy":
			sc = SoldierClass.create_heavy()
		_:
			return
	if squad.add_soldier(sc):
		GameManager.gold -= cost
		GameManager.apply_passives_to_squad()
		_refresh_ui()


func _buy_passive(item: PassiveItem) -> void:
	if GameManager.gold < item.cost:
		return
	if not GameManager.add_passive(item):
		return  # slots full
	GameManager.gold -= item.cost
	EventBus.item_purchased.emit(item.id, item.cost)
	_refresh_ui()


func _buy_weapon(item: Dictionary) -> void:
	if GameManager.gold < item.cost:
		return
	GameManager.gold -= item.cost
	EventBus.item_purchased.emit(item.id, item.cost)
	_apply_weapon(item.id)
	_refresh_ui()


func _buy_consumable(item: Dictionary) -> void:
	if GameManager.gold < item.cost:
		return
	GameManager.gold -= item.cost
	EventBus.item_purchased.emit(item.id, item.cost)
	_apply_consumable(item.id)
	_refresh_ui()


func _apply_weapon(weapon_id: String) -> void:
	var soldiers := get_tree().get_nodes_in_group("squad")
	for s in soldiers:
		if s is Soldier:
			match weapon_id:
				"weapon_rifle":
					s.set_weapon(WeaponData.create_rifle())
				"weapon_shotgun":
					s.set_weapon(WeaponData.create_shotgun())
				"weapon_pistol":
					s.set_weapon(WeaponData.create_pistol())
			# Re-apply passive weapon mults
			GameManager._apply_passives_to_soldier(s)


func _apply_consumable(item_id: String) -> void:
	var soldiers := get_tree().get_nodes_in_group("squad")
	match item_id:
		"medkit":
			for s in soldiers:
				if s is Soldier:
					s.hp = mini(s.hp + 30, s.max_hp)


func _all_have_weapon(weapon_type_id: String) -> bool:
	var target_type: WeaponData.Type
	match weapon_type_id:
		"weapon_rifle": target_type = WeaponData.Type.RIFLE
		"weapon_shotgun": target_type = WeaponData.Type.SHOTGUN
		"weapon_pistol": target_type = WeaponData.Type.PISTOL
		_: return false
	var soldiers := get_tree().get_nodes_in_group("squad")
	for s in soldiers:
		if s is Soldier and (s.weapon == null or s.weapon.type != target_type):
			return false
	return true


func _on_continue() -> void:
	visible = false
	get_tree().paused = false
	EventBus.shop_closed.emit()
