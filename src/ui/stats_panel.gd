## StatsPanel — podgląd statystyk oddziału
extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var stats_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/StatsList
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton


func _ready() -> void:
	panel.visible = false
	close_button.pressed.connect(_close)


func toggle() -> void:
	if panel.visible:
		_close()
	else:
		_open()


func _open() -> void:
	panel.visible = true
	_refresh()
	get_tree().paused = true


func _close() -> void:
	panel.visible = false
	get_tree().paused = false


func _refresh() -> void:
	for child in stats_list.get_children():
		child.queue_free()

	# Header
	var header := Label.new()
	header.text = "── ODDZIAŁ (LV.%d) ──" % GameManager.level
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 14)
	stats_list.add_child(header)

	var soldiers := get_tree().get_nodes_in_group("squad")
	var idx := 1
	for s in soldiers:
		if s is Soldier:
			var sc: SoldierClass = s.soldier_class
			var class_name_str: String = sc.class_name_str if sc else "?"
			var weapon_name: String = s.weapon.weapon_name if s.weapon else "?"
			var line := Label.new()
			line.text = "#%d %s | HP:%d/%d | %s | SPD:%.0f | DMG:×%.1f | LCK:%.0f" % [
				idx, class_name_str, s.hp, s.max_hp, weapon_name, s.move_speed, s.damage_mult, s.luck
			]
			line.add_theme_font_size_override("font_size", 11)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			stats_list.add_child(line)
			idx += 1

	if idx == 1:
		var empty := Label.new()
		empty.text = "Brak żołnierzy"
		stats_list.add_child(empty)

	# Passive equipment section
	var passive_header := Label.new()
	passive_header.text = "── PASYWKI (%d/%d) ──" % [GameManager.get_passive_count(), GameManager.get_max_passive_slots()]
	passive_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	passive_header.add_theme_font_size_override("font_size", 13)
	stats_list.add_child(passive_header)

	if GameManager.passive_items.is_empty():
		var empty_inv := Label.new()
		empty_inv.text = "  (brak)"
		empty_inv.add_theme_font_size_override("font_size", 11)
		stats_list.add_child(empty_inv)
	else:
		# Count items by id for display
		var item_counts: Dictionary = {}
		for p in GameManager.passive_items:
			item_counts[p.id] = item_counts.get(p.id, {"name": p.item_name, "desc": p.description, "count": 0, "color": p.icon_color})
			item_counts[p.id].count += 1
		for item_id in item_counts:
			var info: Dictionary = item_counts[item_id]
			var inv_line := Label.new()
			var count_str: String = "  ×%d" % info.count if info.count > 1 else ""
			inv_line.text = "  %s%s — %s" % [info.name, count_str, info.desc]
			inv_line.add_theme_font_size_override("font_size", 11)
			inv_line.add_theme_color_override("font_color", info.color)
			inv_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			stats_list.add_child(inv_line)

	# Synergies section
	var has_synergy := false
	for tag in [PassiveItem.SynergyTag.SPEED, PassiveItem.SynergyTag.DEFENSE, PassiveItem.SynergyTag.OFFENSE]:
		var lvl: int = GameManager.get_synergy_level(tag)
		if lvl > 0:
			if not has_synergy:
				var syn_header := Label.new()
				syn_header.text = "── SYNERGIE ──"
				syn_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				syn_header.add_theme_font_size_override("font_size", 13)
				stats_list.add_child(syn_header)
				has_synergy = true
			var syn_line := Label.new()
			var tag_name: String = _get_synergy_name(tag)
			var bonus_desc: String = _get_synergy_bonus_desc(tag)
			var active_str: String = " ✓" if lvl >= 3 else ""
			syn_line.text = "  %s %d/3%s — %s" % [tag_name, lvl, active_str, bonus_desc]
			syn_line.add_theme_font_size_override("font_size", 11)
			if lvl >= 3:
				syn_line.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
			stats_list.add_child(syn_line)

	# Economy info
	var eco_label := Label.new()
	eco_label.text = "── EKONOMIA ──\nŚr. szczęście: %.0f | Bonus złota: +%d%%" % [
		GameManager.get_squad_avg_luck(),
		int((GameManager.get_gold_bonus_mult() - 1.0) * 100)
	]
	eco_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eco_label.add_theme_font_size_override("font_size", 12)
	stats_list.add_child(eco_label)


func _get_synergy_name(tag: PassiveItem.SynergyTag) -> String:
	match tag:
		PassiveItem.SynergyTag.SPEED: return "Szybkość"
		PassiveItem.SynergyTag.DEFENSE: return "Obrona"
		PassiveItem.SynergyTag.OFFENSE: return "Ofensywa"
	return "?"


func _get_synergy_bonus_desc(tag: PassiveItem.SynergyTag) -> String:
	match tag:
		PassiveItem.SynergyTag.SPEED: return "10% szansa na unik"
		PassiveItem.SynergyTag.DEFENSE: return "-3 obrażenia od ataku"
		PassiveItem.SynergyTag.OFFENSE: return "+15% obrażeń"
	return ""
