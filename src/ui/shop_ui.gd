## ShopUI — unified 5-card shop (Brotato-style)
extends CanvasLayer

signal closed

const CARD_COUNT := 5
const REROLL_BASE_COST := 10
const MAX_BANISHES := 3

@onready var panel: PanelContainer = $Panel
@onready var item_list: VBoxContainer = $Panel/HBoxRoot/VBoxContainer/ScrollContainer/ItemList
@onready var gold_label: Label = $Panel/HBoxRoot/VBoxContainer/GoldLabel
@onready var continue_button: Button = $Panel/HBoxRoot/VBoxContainer/ContinueButton
@onready var _stats_column: StatsColumn = $Panel/StatsColumn
@onready var _stats_toggle: Button = $Panel/HBoxRoot/VBoxContainer/TopRow/StatsToggle

var _stats_open: bool = false
var _stats_tween: Tween = null
var _unhover_timer: SceneTreeTimer = null
const _STATS_WIDTH: float = 185.0

var consumable_items: Array[Dictionary] = [
	{"id": "medkit", "name": "Apteczka", "cost": 80, "description": "Leczy +30 HP", "type": "consumable"},
]

var weapon_items: Array[Dictionary] = [
	{"id": "weapon_shotgun", "name": "Strzelba", "cost": 100, "description": "5 pocisków, krótki zasięg", "type": "weapon"},
	{"id": "weapon_pistol", "name": "Pistolet", "cost": 70, "description": "Wysoka celność, duży zasięg", "type": "weapon"},
	{"id": "weapon_rifle", "name": "Karabin", "cost": 50, "description": "Szybki ogień, średni dmg", "type": "weapon"},
	{"id": "weapon_smg", "name": "SMG", "cost": 90, "description": "Bardzo szybki ogień, krótki zasięg", "type": "weapon"},
	{"id": "weapon_sniper", "name": "Snajperka", "cost": 150, "description": "Wysoki dmg, duży zasięg, wolny ogień", "type": "weapon"},
	{"id": "weapon_melee", "name": "Broń biała", "cost": 60, "description": "Bardzo wysokie dmg w zwarciu", "type": "weapon"},
	{"id": "weapon_grenade", "name": "Granatnik", "cost": 130, "description": "Rozsiew 4 pocisków, wolny ogień", "type": "weapon"},
]

var recruit_classes: Array[Dictionary] = []

# Unified offer system
var _current_offers: Array[Dictionary] = []  # {card_type, data, tier}
var _locked_cards: Array[Dictionary] = []
var _banished_ids: Array[String] = []
var _reroll_count: int = 0
var _banish_count: int = 0


func _ready() -> void:
	visible = false
	_stats_column.visible = false
	_stats_toggle.pressed.connect(func(): _set_stats_open(!_stats_open))
	continue_button.pressed.connect(_on_continue)
	EventBus.shop_opened.connect(_open)
	EventBus.mission_started.connect(_on_mission_started)


## Smart positioning — stats overlay po przeciwnej stronie karty (top_level, absolute pos)
func _position_stats_for_card(card: ShopCard) -> void:
	if card == null:
		return
	var panel := $Panel as Control
	# Czekaj aż panel ma rozmiar (może być 0 przy pierwszym frame)
	if panel.size.x < 10:
		await get_tree().process_frame
	var panel_rect := panel.get_global_rect()
	var card_center_x := card.global_position.x + card.size.x * 0.5
	var stats_w: float = _STATS_WIDTH
	var stats_h: float = panel_rect.size.y
	# Lewa lub prawa strona — zawsze POZA kartami, nie nakrywając ich
	var pos_x: float
	if card_center_x < panel_rect.position.x + panel_rect.size.x * 0.5:
		# Karta po lewej → stats po prawej krawędzi panelu
		pos_x = panel_rect.position.x + panel_rect.size.x - stats_w
	else:
		# Karta po prawej → stats po lewej krawędzi panelu
		pos_x = panel_rect.position.x
	_stats_column.global_position = Vector2(pos_x, panel_rect.position.y)
	_stats_column.size = Vector2(stats_w, stats_h)


## Płynne wysunięcie/schowanie panelu statystyk
func _set_stats_open(open: bool, preview_card: ShopCard = null) -> void:
	if _stats_tween and _stats_tween.is_valid():
		_stats_tween.kill()
	_stats_open = open
	_stats_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if open:
		if preview_card:
			_position_stats_for_card(preview_card)
			_stats_column.refresh_with_preview(preview_card)
		else:
			_stats_column.refresh()
		_stats_column.visible = true
		_stats_column.modulate.a = 0.0
		_stats_tween.tween_property(_stats_column, "modulate:a", 1.0, 0.15)
	else:
		_stats_tween.tween_property(_stats_column, "modulate:a", 0.0, 0.12)
		_stats_tween.tween_callback(func(): _stats_column.visible = false)


func _on_mission_started() -> void:
	_locked_cards.clear()
	_current_offers.clear()
	_banished_ids.clear()
	_reroll_count = 0
	_banish_count = 0


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
	_roll_offers()
	_refresh_ui()
	get_tree().paused = true


# --- UNIFIED POOL ---

func _get_card_id(entry: Dictionary) -> String:
	var ct: ShopCard.CardType = entry.card_type
	if ct == ShopCard.CardType.RECRUIT:
		return entry.data.factory
	return entry.data.id


func _roll_offers() -> void:
	var wave: int = GameManager.current_wave
	var pool: Array[Dictionary] = []

	# Weapons
	for item in weapon_items:
		if item.id in _banished_ids:
			continue
		var tier: WeaponData.Tier = WeaponData.get_random_tier_for_wave(wave)
		pool.append({"card_type": ShopCard.CardType.WEAPON, "data": item, "tier": tier})

	# Passives
	for p_item in PassiveItem.get_all_items():
		if p_item.id in _banished_ids:
			continue
		pool.append({"card_type": ShopCard.CardType.PASSIVE, "data": p_item, "tier": WeaponData.Tier.COMMON})

	# Consumables
	for item in consumable_items:
		pool.append({"card_type": ShopCard.CardType.CONSUMABLE, "data": item, "tier": WeaponData.Tier.COMMON})

	# Recruits
	var squad := _get_squad()
	var can_recruit := squad != null and squad.get_soldier_count() < Squad.MAX_SOLDIERS
	if can_recruit:
		for rc in recruit_classes:
			pool.append({"card_type": ShopCard.CardType.RECRUIT, "data": rc, "tier": WeaponData.Tier.COMMON})

	# Remove locked card items from pool
	var locked_ids: Array[String] = []
	for lc in _locked_cards:
		locked_ids.append(_get_card_id(lc))
	var filtered_pool: Array[Dictionary] = []
	for entry in pool:
		if _get_card_id(entry) not in locked_ids:
			filtered_pool.append(entry)

	# Shuffle and draw
	filtered_pool.shuffle()
	var draw_count := maxi(CARD_COUNT - _locked_cards.size(), 0)
	var drawn: Array[Dictionary] = []
	for i in mini(draw_count, filtered_pool.size()):
		drawn.append(filtered_pool[i])

	_current_offers = _locked_cards.duplicate(true) + drawn
	# Cap at 5
	if _current_offers.size() > CARD_COUNT:
		_current_offers.resize(CARD_COUNT)


func _get_reroll_cost() -> int:
	return REROLL_BASE_COST * int(pow(2, _reroll_count))


func _reroll() -> void:
	var cost := _get_reroll_cost()
	if GameManager.gold < cost:
		return
	GameManager.gold -= cost
	_reroll_count += 1
	_roll_offers()
	_refresh_ui()


# --- UI ---

func _refresh_ui() -> void:
	for child in item_list.get_children():
		child.queue_free()

	var gold := GameManager.gold
	var slots_full: bool = GameManager.get_passive_count() >= GameManager.get_max_passive_slots()
	var can_banish: bool = _banish_count < MAX_BANISHES
	gold_label.text = "Złoto: $%d   |   LV.%d" % [gold, GameManager.level]

	# Card row — poziomy scroll (swipe), stała szerokość karty, podglądowa 5. jako hint
	var card_scroll := ScrollContainer.new()
	card_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_scroll.custom_minimum_size = Vector2(0, 180)
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	card_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	item_list.add_child(card_scroll)

	var card_row := HBoxContainer.new()
	card_row.add_theme_constant_override("separation", 8)
	card_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_scroll.add_child(card_row)

	const CARD_SCENE := preload("res://src/ui/card_template.tscn")
	const CARD_SCENE_RECRUIT := preload("res://src/ui/card_template_recruit.tscn")
	for i in _current_offers.size():
		var entry: Dictionary = _current_offers[i]
		var card: ShopCard = (CARD_SCENE_RECRUIT if entry.card_type == ShopCard.CardType.RECRUIT else CARD_SCENE).instantiate()
		card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		card.add_to_group("shop_cards")
		card_row.add_child(card)

		var ct: ShopCard.CardType = entry.card_type
		match ct:
			ShopCard.CardType.WEAPON:
				var owned: bool = _all_have_weapon(entry.data.id)
				card.setup_weapon(entry.data, entry.tier, owned, gold, can_banish)
			ShopCard.CardType.PASSIVE:
				var p_item: PassiveItem = entry.data
				var count: int = GameManager.count_passive(p_item.id)
				var synergy_lvl: int = GameManager.get_synergy_level(p_item.synergy_tag)
				card.setup_passive(p_item, count, synergy_lvl, slots_full, gold, can_banish)
			ShopCard.CardType.CONSUMABLE:
				card.setup_consumable(entry.data, gold)
			ShopCard.CardType.RECRUIT:
				card.setup_recruit(entry.data, _get_recruit_cost(), gold)

		# Restore lock state
		var eid := _get_card_id(entry)
		for lc in _locked_cards:
			if _get_card_id(lc) == eid:
				card.set_locked(true)
				break

		card.purchased.connect(_on_card_purchased)
		card.locked_toggled.connect(_on_card_lock_toggled.bind(i))
		card.banished.connect(_on_card_banished)
		card.hovered.connect(_on_card_hovered)
		card.unhovered.connect(_on_card_unhovered)
		card.preview_requested.connect(_on_card_preview_requested)

	# Refresh stats column
	if _stats_column:
		_stats_column.refresh()

	# Reroll button
	var reroll_row := HBoxContainer.new()
	reroll_row.alignment = BoxContainer.ALIGNMENT_CENTER
	item_list.add_child(reroll_row)

	var reroll_btn := Button.new()
	var reroll_cost := _get_reroll_cost()
	reroll_btn.text = "🔄 REROLL  $%d" % reroll_cost
	reroll_btn.custom_minimum_size = Vector2(120, 28)
	reroll_btn.add_theme_font_size_override("font_size", 10)
	reroll_btn.disabled = gold < reroll_cost
	reroll_btn.pressed.connect(_reroll)
	reroll_row.add_child(reroll_btn)

	var banish_label := Label.new()
	banish_label.text = "  Banish: %d/%d" % [_banish_count, MAX_BANISHES]
	banish_label.add_theme_font_size_override("font_size", 9)
	banish_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	reroll_row.add_child(banish_label)

	# Synergies row — always show all 3 tags with fixed height (no layout shift)
	var syn_container := VBoxContainer.new()
	syn_container.custom_minimum_size = Vector2(0, 40)
	syn_container.add_theme_constant_override("separation", 1)
	item_list.add_child(syn_container)

	var syn_header := Label.new()
	syn_header.text = "── SYNERGIE ──"
	syn_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	syn_header.add_theme_font_size_override("font_size", 10)
	syn_container.add_child(syn_header)

	for tag in [PassiveItem.SynergyTag.SPEED, PassiveItem.SynergyTag.DEFENSE, PassiveItem.SynergyTag.OFFENSE]:
		var lvl: int = GameManager.get_synergy_level(tag)
		var lbl := Label.new()
		var bonus_str: String = " ✓ AKTYWNA!" if lvl >= 3 else ""
		lbl.text = "%s: %d/3%s" % [_get_synergy_name(tag), lvl, bonus_str]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 10)
		if lvl >= 3:
			lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		elif lvl == 0:
			lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		syn_container.add_child(lbl)


# --- SIGNAL HANDLERS ---

func _on_card_purchased(card: ShopCard) -> void:
	match card.card_type:
		ShopCard.CardType.WEAPON:
			_buy_weapon(card.card_data, card.weapon_tier)
		ShopCard.CardType.PASSIVE:
			_buy_passive(card.card_data)
		ShopCard.CardType.CONSUMABLE:
			_buy_consumable(card.card_data)
		ShopCard.CardType.RECRUIT:
			_recruit(card.card_data.factory, _get_recruit_cost())


func _on_card_lock_toggled(card: ShopCard, offer_idx: int) -> void:
	if offer_idx < 0 or offer_idx >= _current_offers.size():
		return
	var entry := _current_offers[offer_idx]
	var eid := _get_card_id(entry)

	if card.is_locked:
		# Add to locked if not already there
		var found := false
		for lc in _locked_cards:
			if _get_card_id(lc) == eid:
				found = true
				break
		if not found:
			_locked_cards.append(entry)
	else:
		# Remove from locked
		for i in range(_locked_cards.size() - 1, -1, -1):
			if _get_card_id(_locked_cards[i]) == eid:
				_locked_cards.remove_at(i)
				break


func _on_card_banished(card: ShopCard) -> void:
	if _banish_count >= MAX_BANISHES:
		return
	var ban_id: String = ""
	match card.card_type:
		ShopCard.CardType.WEAPON:
			ban_id = card.card_data.id
		ShopCard.CardType.PASSIVE:
			ban_id = card.card_data.id
		_:
			return  # consumables + recruits not banishable
	if ban_id.is_empty():
		return
	_banished_ids.append(ban_id)
	_banish_count += 1
	# Remove from locked
	for i in range(_locked_cards.size() - 1, -1, -1):
		if _get_card_id(_locked_cards[i]) == ban_id:
			_locked_cards.remove_at(i)
			break
	# Re-roll to replace banished card
	_roll_offers()
	_refresh_ui()


# --- PURCHASE LOGIC ---

func _buy_weapon(item: Dictionary, tier: WeaponData.Tier) -> void:
	var tier_cost_mult: float = WeaponData.TIER_MULTIPLIERS.get(tier, 1.0)
	var final_cost: int = int(item.cost * tier_cost_mult)
	if GameManager.gold < final_cost:
		return
	GameManager.gold -= final_cost
	EventBus.item_purchased.emit(item.id, final_cost)
	_apply_weapon(item.id, tier)
	_refresh_ui()


func _buy_passive(item: PassiveItem) -> void:
	if GameManager.gold < item.cost:
		return
	if not GameManager.add_passive(item):
		return
	GameManager.gold -= item.cost
	EventBus.item_purchased.emit(item.id, item.cost)
	_refresh_ui()


func _buy_consumable(item: Dictionary) -> void:
	if GameManager.gold < item.cost:
		return
	GameManager.gold -= item.cost
	EventBus.item_purchased.emit(item.id, item.cost)
	_apply_consumable(item.id)
	_refresh_ui()


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


# --- HELPERS ---

func _get_synergy_name(tag: PassiveItem.SynergyTag) -> String:
	match tag:
		PassiveItem.SynergyTag.SPEED: return "Szybkość"
		PassiveItem.SynergyTag.DEFENSE: return "Obrona"
		PassiveItem.SynergyTag.OFFENSE: return "Ofensywa"
	return "?"


func _get_recruit_cost() -> int:
	var squad := _get_squad()
	if squad == null:
		return 150
	return 150 + (squad.get_soldier_count() - 1) * 75


func _get_squad() -> Squad:
	var arena := get_tree().current_scene
	return arena.get_node_or_null("Squad") as Squad


func _apply_weapon(weapon_id: String, tier: WeaponData.Tier = WeaponData.Tier.COMMON) -> void:
	var weapon_type: WeaponData.Type
	match weapon_id:
		"weapon_rifle": weapon_type = WeaponData.Type.RIFLE
		"weapon_shotgun": weapon_type = WeaponData.Type.SHOTGUN
		"weapon_pistol": weapon_type = WeaponData.Type.PISTOL
		"weapon_smg": weapon_type = WeaponData.Type.SMG
		"weapon_sniper": weapon_type = WeaponData.Type.SNIPER_RIFLE
		"weapon_melee": weapon_type = WeaponData.Type.MELEE
		"weapon_grenade": weapon_type = WeaponData.Type.GRENADE
		_: return
	var new_weapon := WeaponData.create_tiered(weapon_type, tier)
	var soldiers := get_tree().get_nodes_in_group("squad")
	for s in soldiers:
		if s is Soldier:
			s.set_weapon(new_weapon)
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
		"weapon_smg": target_type = WeaponData.Type.SMG
		"weapon_sniper": target_type = WeaponData.Type.SNIPER_RIFLE
		"weapon_melee": target_type = WeaponData.Type.MELEE
		"weapon_grenade": target_type = WeaponData.Type.GRENADE
		_: return false
	var soldiers := get_tree().get_nodes_in_group("squad")
	for s in soldiers:
		if s is Soldier and (s.weapon == null or s.weapon.type != target_type):
			return false
	return true


# --- STATS PREVIEW ---

func _on_card_hovered(card: ShopCard) -> void:
	_unhover_timer = null
	_set_stats_open(true, card)


func _on_card_unhovered(_card: ShopCard) -> void:
	if not _stats_open:
		return
	# Daj silnikowi jedną klatkę na przetworzenie mouse_entered kolejnej karty
	_unhover_timer = get_tree().create_timer(0.05)
	_unhover_timer.timeout.connect(_check_close_stats)


func _check_close_stats() -> void:
	_unhover_timer = null
	var mouse := get_viewport().get_mouse_position()
	for card in get_tree().get_nodes_in_group("shop_cards"):
		if is_instance_valid(card) and card.get_global_rect().has_point(mouse):
			return
	_set_stats_open(false)


func _on_card_preview_requested(card: ShopCard) -> void:
	# Mobile: dotknięcie karty → toggle stats z preview
	# Jeśli ten sam card już pokazuje preview → schowaj. Inny → pokaż.
	if _stats_open and _stats_column and _stats_column.current_preview_card == card:
		_set_stats_open(false)
	else:
		_set_stats_open(true, card)


func _on_continue() -> void:
	_set_stats_open(false)
	await get_tree().create_timer(0.2).timeout
	visible = false
	get_tree().paused = false
	EventBus.shop_closed.emit()
