## StatsColumn — lewy panel statystyk oddziału (Brotato-style)
class_name StatsColumn
extends PanelContainer

var _stats_list: VBoxContainer
var current_preview_card: ShopCard = null  ## Aktualnie podglądana karta (mobile toggle)


func _ready() -> void:
	custom_minimum_size = Vector2(185, 0)
	size_flags_horizontal = Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = false
	# Cały panel statystyk jest "duchem" dla myszy — nie blokuje hover na kartach
	_set_mouse_ignore_recursive(self)


func _set_mouse_ignore_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_ignore_recursive(child)

	var style: StyleBox
	var tex := load("res://assets/sprites/ui/Panel BG.svg") as Texture2D
	if tex:
		var style_tex := StyleBoxTexture.new()
		style_tex.texture = tex
		style_tex.texture_margin_left = 12
		style_tex.texture_margin_top = 12
		style_tex.texture_margin_right = 12
		style_tex.texture_margin_bottom = 12
		style_tex.content_margin_left = 8
		style_tex.content_margin_top = 8
		style_tex.content_margin_right = 8
		style_tex.content_margin_bottom = 8
		style = style_tex
	else:
		var style_flat := StyleBoxFlat.new()
		style_flat.bg_color = Color(0.08, 0.08, 0.10)
		style_flat.border_color = Color(0.25, 0.25, 0.28)
		style_flat.set_border_width_all(1)
		style_flat.set_corner_radius_all(2)
		style_flat.set_content_margin_all(8)
		style = style_flat
	add_theme_stylebox_override("panel", style)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	_stats_list = VBoxContainer.new()
	_stats_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_list.add_theme_constant_override("separation", 1)
	scroll.add_child(_stats_list)


func refresh() -> void:
	for child in _stats_list.get_children():
		child.queue_free()

	# Header
	var header := Label.new()
	header.text = "Statystyki"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_stats_list.add_child(header)

	var sep := HSeparator.new()
	_stats_list.add_child(sep)

	# Gather squad stats
	var soldiers := get_tree().get_nodes_in_group("squad")
	var count: int = 0
	var total_hp: int = 0
	var total_max_hp: int = 0
	var total_dmg: float = 0.0
	var total_speed: float = 0.0
	var total_luck: float = 0.0
	var total_armor: int = 0
	var total_range_mult: float = 0.0
	var total_fire_rate_mult: float = 0.0
	var total_dodge: float = 0.0

	for s in soldiers:
		if s is Soldier:
			count += 1
			total_hp += s.hp
			total_max_hp += s.max_hp
			total_dmg += s.damage_mult
			total_speed += s.move_speed
			total_luck += s.luck
			total_armor += s.armor
			total_range_mult += s.range_mult
			total_fire_rate_mult += s.fire_rate_mult
			total_dodge += s.dodge_chance

	if count == 0:
		count = 1  # avoid division by zero

	var avg_dmg: float = total_dmg / count
	var avg_speed: float = total_speed / count
	var avg_luck: float = total_luck / count
	var avg_range: float = total_range_mult / count
	var avg_fire_rate: float = total_fire_rate_mult / count
	var avg_dodge: float = total_dodge / count
	var crit_pct: float = clampf(avg_luck / 200.0, 0.0, 0.5) * 100.0

	# Stat rows
	_add_stat_row("❤️", "Max HP", str(total_max_hp), total_max_hp > 100 * count)
	_add_stat_row("💚", "HP", "%d/%d" % [total_hp, total_max_hp], false)
	_add_stat_row("⚔", "Obrażenia", "×%.2f" % avg_dmg, avg_dmg > 1.0)
	_add_stat_row("🛡", "Pancerz", str(total_armor), total_armor > 0)
	_add_stat_row("🏃", "Szybkość", "%.0f" % avg_speed, avg_speed > 80.0)
	_add_stat_row("🎯", "Zasięg", "%.0f%%" % (avg_range * 100.0), avg_range > 1.0)
	_add_stat_row("🔥", "Sz. ognia", "%.0f%%" % (avg_fire_rate * 100.0), avg_fire_rate > 1.0)
	_add_stat_row("🍀", "Szczęście", "%.0f" % avg_luck, avg_luck > 10.0)
	_add_stat_row("⚡", "Crit", "%.1f%%" % crit_pct, crit_pct > 5.0)
	_add_stat_row("🏹", "Unik", "%.0f%%" % (avg_dodge * 100.0), avg_dodge > 0.0)

	# Separator
	var sep2 := HSeparator.new()
	_stats_list.add_child(sep2)

	# Synergy section
	for tag in [PassiveItem.SynergyTag.SPEED, PassiveItem.SynergyTag.DEFENSE, PassiveItem.SynergyTag.OFFENSE]:
		var lvl: int = GameManager.get_synergy_level(tag)
		if lvl > 0:
			var tag_name: String
			match tag:
				PassiveItem.SynergyTag.SPEED: tag_name = "Szybkość"
				PassiveItem.SynergyTag.DEFENSE: tag_name = "Obrona"
				PassiveItem.SynergyTag.OFFENSE: tag_name = "Ofensywa"
				_: tag_name = "?"
			var row := HBoxContainer.new()
			var name_lbl := Label.new()
			name_lbl.text = "  %s" % tag_name
			name_lbl.add_theme_font_size_override("font_size", 11)
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(name_lbl)
			var val_lbl := Label.new()
			val_lbl.text = "%d/3" % lvl
			val_lbl.add_theme_font_size_override("font_size", 11)
			if lvl >= 3:
				val_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
				name_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
			row.add_child(val_lbl)
			_stats_list.add_child(row)

	# Economy
	var sep3 := HSeparator.new()
	_stats_list.add_child(sep3)
	var gold_bonus: int = int((GameManager.get_gold_bonus_mult() - 1.0) * 100.0)
	_add_stat_row("💰", "Złoto bonus", "+%d%%" % gold_bonus, gold_bonus > 0)

	# Squad size
	var squad_count: int = 0
	for s in soldiers:
		if s is Soldier:
			squad_count += 1
	_add_stat_row("👥", "Oddział", "%d/%d" % [squad_count, Squad.MAX_SOLDIERS], false)

	# Owned passives section
	var sep4 := HSeparator.new()
	_stats_list.add_child(sep4)
	var passive_header := Label.new()
	passive_header.text = "Pasywki %d/%d" % [GameManager.get_passive_count(), GameManager.get_max_passive_slots()]
	passive_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	passive_header.add_theme_font_size_override("font_size", 11)
	passive_header.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_stats_list.add_child(passive_header)
	if GameManager.passive_items.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "  (brak)"
		empty_lbl.add_theme_font_size_override("font_size", 11)
		empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		_stats_list.add_child(empty_lbl)
	else:
		var item_counts: Dictionary = {}
		for p in GameManager.passive_items:
			if not item_counts.has(p.id):
				item_counts[p.id] = {"name": p.item_name, "count": 0, "color": p.icon_color}
			item_counts[p.id].count += 1
		for item_id in item_counts:
			var info: Dictionary = item_counts[item_id]
			var lbl := Label.new()
			var cnt_str: String = " ×%d" % info.count if info.count > 1 else ""
			lbl.text = "  %s%s" % [info.name, cnt_str]
			lbl.add_theme_font_size_override("font_size", 11)
			lbl.add_theme_color_override("font_color", info.color)
			lbl.clip_text = true
			_stats_list.add_child(lbl)

	# Bottom breathing room
	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 8)
	_stats_list.add_child(bottom_spacer)


func _add_stat_row(icon: String, stat_name: String, value_str: String, is_buffed: bool, delta_str: String = "") -> void:
	var row := HBoxContainer.new()

	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", 10)
	icon_lbl.custom_minimum_size = Vector2(16, 0)
	row.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = stat_name
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	row.add_child(name_lbl)

	var val_lbl := Label.new()
	val_lbl.add_theme_font_size_override("font_size", 11)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.custom_minimum_size = Vector2(36, 0)
	val_lbl.text = value_str
	if is_buffed:
		val_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	else:
		val_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	row.add_child(val_lbl)

	# Delta column — always present with fixed width to prevent layout jitter
	var delta_lbl := Label.new()
	delta_lbl.add_theme_font_size_override("font_size", 11)
	delta_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	delta_lbl.custom_minimum_size = Vector2(30, 0)
	if delta_str != "":
		delta_lbl.text = delta_str
		delta_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	else:
		delta_lbl.text = ""
	row.add_child(delta_lbl)

	_stats_list.add_child(row)


func refresh_with_preview(card: ShopCard) -> void:
	current_preview_card = card
	if card == null or card.card_type != ShopCard.CardType.PASSIVE:
		refresh()
		return

	# Gather current stats (same as refresh)
	var soldiers := get_tree().get_nodes_in_group("squad")
	var count: int = 0
	var total_hp: int = 0
	var total_max_hp: int = 0
	var total_dmg: float = 0.0
	var total_speed: float = 0.0
	var total_luck: float = 0.0
	var total_armor: int = 0
	var total_range_mult: float = 0.0
	var total_fire_rate_mult: float = 0.0
	var total_dodge: float = 0.0
	for s in soldiers:
		if s is Soldier:
			count += 1
			total_hp += s.hp
			total_max_hp += s.max_hp
			total_dmg += s.damage_mult
			total_speed += s.move_speed
			total_luck += s.luck
			total_armor += s.armor
			total_range_mult += s.range_mult
			total_fire_rate_mult += s.fire_rate_mult
			total_dodge += s.dodge_chance
	if count == 0:
		count = 1

	var avg_dmg: float = total_dmg / count
	var avg_speed: float = total_speed / count
	var avg_luck: float = total_luck / count
	var avg_range: float = total_range_mult / count
	var avg_fire_rate: float = total_fire_rate_mult / count
	var avg_dodge: float = total_dodge / count
	var crit_pct: float = clampf(avg_luck / 200.0, 0.0, 0.5) * 100.0

	# Compute deltas from the hovered passive
	var item: PassiveItem = card.card_data
	var d_hp := 0.0
	var d_dmg := 0.0
	var d_spd := 0.0
	var d_luck := 0.0
	var d_range := 0.0
	var d_rof := 0.0
	match item.stat_type:
		PassiveItem.StatType.LUCK:
			d_luck = item.stat_value
		PassiveItem.StatType.ARMOR:
			d_hp = item.stat_value
		PassiveItem.StatType.SPEED:
			d_spd = avg_speed * item.stat_value
		PassiveItem.StatType.DAMAGE:
			d_dmg = avg_dmg * item.stat_value
		PassiveItem.StatType.RANGE:
			d_range = item.stat_value
		PassiveItem.StatType.FIRE_RATE:
			d_rof = item.stat_value

	# Rebuild UI with deltas
	for child in _stats_list.get_children():
		child.queue_free()

	var header := Label.new()
	header.text = "Statystyki"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_stats_list.add_child(header)
	_stats_list.add_child(HSeparator.new())

	_add_stat_row("❤️", "Max HP", str(total_max_hp), total_max_hp > 100 * count,
		str(total_max_hp + int(d_hp * count)) if abs(d_hp) > 0.01 else "")
	_add_stat_row("💚", "HP", "%d/%d" % [total_hp, total_max_hp], false)
	_add_stat_row("⚔", "Obrażenia", "×%.2f" % avg_dmg, avg_dmg > 1.0,
		"×%.2f" % (avg_dmg + d_dmg) if abs(d_dmg) > 0.01 else "")
	_add_stat_row("🛡", "Pancerz", str(total_armor), total_armor > 0)
	_add_stat_row("🏃", "Szybkość", "%.0f" % avg_speed, avg_speed > 80.0,
		"%.0f" % (avg_speed + d_spd) if abs(d_spd) > 0.01 else "")
	_add_stat_row("🎯", "Zasięg", "%.0f%%" % (avg_range * 100.0), avg_range > 1.0,
		"%.0f%%" % ((avg_range + d_range) * 100.0) if abs(d_range) > 0.01 else "")
	_add_stat_row("🔥", "Sz. ognia", "%.0f%%" % (avg_fire_rate * 100.0), avg_fire_rate > 1.0,
		"%.0f%%" % ((avg_fire_rate + d_rof) * 100.0) if abs(d_rof) > 0.01 else "")
	_add_stat_row("🍀", "Szczęście", "%.0f" % avg_luck, avg_luck > 10.0,
		"%.0f" % (avg_luck + d_luck) if abs(d_luck) > 0.01 else "")
	var new_luck := avg_luck + d_luck
	var new_crit := clampf(new_luck / 200.0, 0.0, 0.5) * 100.0
	_add_stat_row("⚡", "Crit", "%.1f%%" % crit_pct, crit_pct > 5.0,
		"%.1f%%" % new_crit if abs(d_luck) > 0.01 else "")
	_add_stat_row("🏹", "Unik", "%.0f%%" % (avg_dodge * 100.0), avg_dodge > 0.0)

	_stats_list.add_child(HSeparator.new())

	# Synergies (same as refresh)
	for tag in [PassiveItem.SynergyTag.SPEED, PassiveItem.SynergyTag.DEFENSE, PassiveItem.SynergyTag.OFFENSE]:
		var lvl: int = GameManager.get_synergy_level(tag)
		var preview_lvl := lvl
		if item.synergy_tag == tag:
			preview_lvl += 1
		if lvl > 0 or preview_lvl > 0:
			var tag_name: String
			match tag:
				PassiveItem.SynergyTag.SPEED: tag_name = "Szybkość"
				PassiveItem.SynergyTag.DEFENSE: tag_name = "Obrona"
				PassiveItem.SynergyTag.OFFENSE: tag_name = "Ofensywa"
				_: tag_name = "?"
			var row := HBoxContainer.new()
			var name_lbl := Label.new()
			name_lbl.text = "  %s" % tag_name
			name_lbl.add_theme_font_size_override("font_size", 11)
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(name_lbl)
			var val_lbl := Label.new()
			val_lbl.add_theme_font_size_override("font_size", 11)
			if preview_lvl > lvl:
				val_lbl.text = "%d/3 → %d/3" % [lvl, preview_lvl]
				val_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
				name_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
			else:
				val_lbl.text = "%d/3" % lvl
				if lvl >= 3:
					val_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
					name_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
			row.add_child(val_lbl)
			_stats_list.add_child(row)

	_stats_list.add_child(HSeparator.new())
	var gold_bonus: int = int((GameManager.get_gold_bonus_mult() - 1.0) * 100.0)
	_add_stat_row("💰", "Złoto bonus", "+%d%%" % gold_bonus, gold_bonus > 0)
	var squad_count: int = 0
	for s in soldiers:
		if s is Soldier:
			squad_count += 1
	_add_stat_row("👥", "Oddział", "%d/%d" % [squad_count, Squad.MAX_SOLDIERS], false)
