## UpgradePanel — panel wyboru upgrade'u między falami (Brotato-style)
## Reaguje na EventBus.upgrade_panel_requested. Po wyborze emituje upgrade_panel_completed.
extends CanvasLayer

const PICKS_PER_OFFER := 3

@onready var panel_root: PanelContainer = $PanelRoot
@onready var card_row: HBoxContainer = $PanelRoot/Margin/VBox/CardRow
@onready var title_label: Label = $PanelRoot/Margin/VBox/TitleLabel
@onready var skip_button: Button = $PanelRoot/Margin/VBox/SkipButton

# Viewport 640×360 landscape. 3 karty w rzędzie, forma pozioma/kwadratowa.
# Szerokość: (640 - 32 marginesy - 16 gaps) / 3 ≈ 197 → 180
# Wysokość: 360 - 24(tytuł+sep) - 26(skip+sep) - 24(marginesy) = 286 → MAX 140
const CARD_WIDTH  := 180
const CARD_HEIGHT := 130

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	visible = false
	layer = 10
	EventBus.upgrade_panel_requested.connect(_show_panel)
	if skip_button:
		skip_button.pressed.connect(_on_skip)


func _show_panel() -> void:
	var picks := _roll_upgrades(PICKS_PER_OFFER)
	if picks.is_empty():
		EventBus.upgrade_panel_completed.emit()
		return
	get_tree().paused = true
	# 1. BEZPIECZNE sprzątanie starych kart
	for child in card_row.get_children():
		child.queue_free()
	await get_tree().process_frame
	# 2. Dodaj nowe karty
	for u in picks:
		card_row.add_child(_make_card(u))
	# 3. Pokaż panel (nadal niewidoczny, jeszcze niesentrowany)
	visible = true
	# 4. Czekaj 1 klatkę aż PanelContainer obliczy swój minimum size na podstawie kart
	await get_tree().process_frame
	# 5. WYMUSZAM rozmiar i centrowanie ręcznie — zero magii Godot layoutu
	_center_panel()


func _center_panel() -> void:
	# Wymuś rozmiar = minimum content size (nie pozwól PanelContainerowi rosnąć)
	var min_size := panel_root.get_combined_minimum_size()
	panel_root.size = min_size
	# Wycentruj na ekranie
	var vp := get_viewport().get_visible_rect().size
	panel_root.position = ((vp - min_size) * 0.5).round()


func _close() -> void:
	visible = false
	get_tree().paused = false
	EventBus.upgrade_panel_completed.emit()


func _on_skip() -> void:
	_close()


func _on_card_pressed(upgrade: UpgradeData) -> void:
	GameManager.add_run_upgrade(upgrade)
	_close()


func _roll_upgrades(count: int) -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = UpgradeData.get_all_upgrades()
	if pool.is_empty():
		return []
	var weights: Array[float] = []
	for u in pool:
		weights.append(UpgradeData.get_rarity_weight(u.rarity))
	var picks: Array[UpgradeData] = []
	var used: Array[int] = []
	var attempts := 0
	while picks.size() < count and attempts < 100:
		attempts += 1
		var idx: int = _rng.rand_weighted(weights)
		if idx in used:
			continue
		used.append(idx)
		picks.append(pool[idx])
	return picks


func _build_cards(upgrades: Array[UpgradeData]) -> void:
	# UWAGA: ta funkcja jest pozostawiona dla kompatybilności, ale _show_panel
	# wykonuje free + build inline z properly timed `await process_frame`.
	for child in card_row.get_children():
		child.queue_free()
	for u in upgrades:
		card_row.add_child(_make_card(u))


func _make_card(upgrade: UpgradeData) -> Control:
	var rarity_color: Color = UpgradeData.get_rarity_color(upgrade.rarity)

	var card := PanelContainer.new()
	# Stały rozmiar — nie zależy od ekranu, nie zmienia się między falami
	card.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.size_flags_stretch_ratio = 1.0
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.13, 0.95)
	sb.border_color = rarity_color
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel", sb)

	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.18, 0.18, 0.22, 0.95)
	sb_hover.border_color = rarity_color.lightened(0.25)
	sb_hover.set_border_width_all(4)

	card.mouse_entered.connect(func(): card.add_theme_stylebox_override("panel", sb_hover))
	card.mouse_exited.connect(func(): card.add_theme_stylebox_override("panel", sb))
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton \
				and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT:
			_on_card_pressed(upgrade))

	var label := Label.new()
	label.text = "%s\n\n%s" % [upgrade.upgrade_name, upgrade.description]
	label.add_theme_color_override("font_color", rarity_color)
	label.add_theme_font_size_override("font_size", 11)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(label)

	return card
