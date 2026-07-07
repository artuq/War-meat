## HubScreen — ekran główny: wybór areny, ulepszenia, klasy
extends CanvasLayer

const TAB_NAMES: Array[String] = ["ARENY", "ULEPSZENIA", "KLASY"]

# --- UI PALETTE (metallic military) ---
const COL_OUTLINE := Color("#1a1a2e")
const COL_NAVBAR_BG := Color("#1e1e2e")
const COL_TAB_INACTIVE := Color("#1e1e2e")
const COL_TAB_ACTIVE := Color("#252530")
const COL_TAB_HOVER := Color("#3a3a4e")
const COL_BORDER_DARK := Color("#3a3a4e")
const COL_BORDER_LIGHT := Color("#555570")
const COL_RIVET := Color("#6b6b6b")
const COL_RIVET_HIGHLIGHT := Color("#8c8c8c")
const COL_TEXT := Color("#ffffff")
const COL_TEXT_DIM := Color("#e0e0e0")

@onready var nav_bar: PanelContainer = $Panel/VBox/NavBar
@onready var tab_buttons: HBoxContainer = $Panel/VBox/NavBar/TabButtons
@onready var arena_list: VBoxContainer = $Panel/VBox/Content/ArenaContent
@onready var upgrade_list: VBoxContainer = $Panel/VBox/Content/UpgradeContent/UpgradeList
@onready var class_list: VBoxContainer = $Panel/VBox/Content/ClassContent/ClassList
@onready var resources_label: Label = $Panel/VBox/ResourcesLabel

var _content_pages: Array[Control] = []
var _tab_btns: Array[Button] = []
var _current_tab: int = 0
var _arenas: Array[ArenaModifier] = []

const CLASS_UNLOCK_MAP: Dictionary = {
	"engineer": {"arena": "jungle", "cost": 40, "factory": "create_engineer", "name": "Inżynier", "desc": "HP 90, Strzelba, naprawy"},
	"scout": {"arena": "desert", "cost": 60, "factory": "create_scout", "name": "Zwiadowca", "desc": "HP 55, SPD 110, Luck 25"},
	"heavy": {"arena": "bunker", "cost": 80, "factory": "create_heavy", "name": "Ciężki", "desc": "HP 160, DMG ×1.4, wolny"},
}

const UPGRADE_NAMES: Dictionary = {
	"hp_bonus": {"name": "Wzmocnienie HP", "desc": "+10 HP startowe na poziom"},
	"dmg_bonus": {"name": "Trening Bojowy", "desc": "+5% obrażeń na poziom"},
	"extra_slot": {"name": "Dodatkowy Slot", "desc": "+1 slot pasywek na poziom"},
}


func _ready() -> void:
	_arenas = [
		ArenaModifier.create_jungle(),
		ArenaModifier.create_desert(),
		ArenaModifier.create_bunker(),
	]
	_content_pages = [
		$Panel/VBox/Content/ArenaContent,
		$Panel/VBox/Content/UpgradeContent,
		$Panel/VBox/Content/ClassContent,
	]
	_style_navbar()
	_build_tab_buttons()
	_switch_tab(0)
	_refresh_all()
	# Hub music
	SoundManager.play_music("hub")


func _refresh_all() -> void:
	resources_label.text = "Surowce: %d" % GameManager.resources
	_build_arena_list()
	_build_upgrade_list()
	_build_class_list()


# --- METALLIC NAVBAR STYLE ---

func _style_navbar() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_NAVBAR_BG
	# 1px dark outline
	sb.border_color = COL_OUTLINE
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	# Beveled top edge (lighter line)
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 1
	sb.corner_radius_bottom_right = 1
	# Inner shadow at bottom for depth
	sb.shadow_color = COL_BORDER_DARK
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(0, 1)
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 3.0
	sb.content_margin_bottom = 3.0
	nav_bar.add_theme_stylebox_override("panel", sb)
	# Draw rivets on both ends
	nav_bar.draw.connect(_draw_rivets)


func _draw_rivets() -> void:
	var sz := nav_bar.size
	var rivet_y := sz.y * 0.5
	# Left side rivets
	_draw_rivet(nav_bar, Vector2(8, rivet_y))
	_draw_rivet(nav_bar, Vector2(18, rivet_y))
	# Right side rivets
	_draw_rivet(nav_bar, Vector2(sz.x - 8, rivet_y))
	_draw_rivet(nav_bar, Vector2(sz.x - 18, rivet_y))


func _draw_rivet(ctrl: Control, pos: Vector2) -> void:
	ctrl.draw_circle(pos, 2.5, COL_RIVET)
	ctrl.draw_circle(pos + Vector2(-0.5, -0.5), 1.0, COL_RIVET_HIGHLIGHT)


func _make_tab_style(active: bool, hover: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if active:
		sb.bg_color = COL_TAB_ACTIVE
		# Top accent border (military green tint)
		sb.border_color = COL_BORDER_LIGHT
		sb.border_width_top = 2
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 0
	elif hover:
		sb.bg_color = COL_TAB_HOVER
		sb.border_color = COL_BORDER_DARK
		sb.border_width_top = 1
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 0
	else:
		sb.bg_color = COL_TAB_INACTIVE
		sb.border_color = COL_BORDER_DARK
		sb.border_width_top = 0
		sb.border_width_left = 0
		sb.border_width_right = 0
		sb.border_width_bottom = 0
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.content_margin_left = 4.0
	sb.content_margin_right = 4.0
	sb.content_margin_top = 2.0
	sb.content_margin_bottom = 2.0
	return sb


# --- CUSTOM TABS ---

func _build_tab_buttons() -> void:
	for child in tab_buttons.get_children():
		child.queue_free()
	_tab_btns.clear()

	for i in TAB_NAMES.size():
		var btn := Button.new()
		btn.text = TAB_NAMES[i]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 32)
		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color", COL_TEXT_DIM)
		btn.add_theme_color_override("font_hover_color", COL_TEXT)
		btn.add_theme_color_override("font_pressed_color", COL_TEXT)
		btn.add_theme_stylebox_override("normal", _make_tab_style(false))
		btn.add_theme_stylebox_override("hover", _make_tab_style(false, true))
		btn.add_theme_stylebox_override("pressed", _make_tab_style(true))
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.mouse_entered.connect(_on_tab_hover.bind(i, true))
		btn.mouse_exited.connect(_on_tab_hover.bind(i, false))
		btn.pressed.connect(_switch_tab.bind(i))
		tab_buttons.add_child(btn)
		_tab_btns.append(btn)


func _apply_tab_styles() -> void:
	for i in _tab_btns.size():
		var btn := _tab_btns[i]
		var active := (i == _current_tab)
		btn.add_theme_stylebox_override("normal", _make_tab_style(active))
		btn.add_theme_stylebox_override("hover", _make_tab_style(active, not active))
		btn.add_theme_stylebox_override("pressed", _make_tab_style(true))
		btn.add_theme_color_override("font_color", COL_TEXT if active else COL_TEXT_DIM)


func _switch_tab(idx: int) -> void:
	_current_tab = idx
	for i in _content_pages.size():
		_content_pages[i].visible = (i == idx)
	_apply_tab_styles()
	nav_bar.queue_redraw()


func _on_tab_hover(idx: int, entered: bool) -> void:
	if idx == _current_tab:
		return
	nav_bar.queue_redraw()


# --- ARENY ---

func _build_arena_list() -> void:
	for child in arena_list.get_children():
		child.queue_free()

	for arena in _arenas:
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label := Label.new()
		var stars := "⭐".repeat(arena.difficulty)
		name_label.text = "%s  %s" % [arena.arena_name, stars]
		name_label.add_theme_font_size_override("font_size", 14)
		info.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = arena.description
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info.add_child(desc_label)

		hbox.add_child(info)

		var btn := Button.new()
		var is_unlocked: bool = arena.arena_id in GameManager.unlocked_arenas
		if is_unlocked:
			btn.text = "WALCZ"
			btn.pressed.connect(_on_arena_selected.bind(arena))
		else:
			btn.text = "🔒"
			btn.disabled = true
		btn.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(btn)

		arena_list.add_child(hbox)
		arena_list.add_child(HSeparator.new())


# --- ULEPSZENIA ---

func _build_upgrade_list() -> void:
	for child in upgrade_list.get_children():
		child.queue_free()

	for upgrade_id in UPGRADE_NAMES:
		var info: Dictionary = UPGRADE_NAMES[upgrade_id]
		var lvl: int = GameManager.get_upgrade_level(upgrade_id)
		var max_lvl: int = GameManager.get_upgrade_max(upgrade_id)
		var cost: int = GameManager.get_upgrade_cost(upgrade_id)

		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label := Label.new()
		if lvl >= max_lvl:
			label.text = "%s  LV.%d/%d  MAX  —  %s" % [info.name, lvl, max_lvl, info.desc]
		else:
			label.text = "%s  LV.%d/%d  —  %s" % [info.name, lvl, max_lvl, info.desc]
		label.add_theme_font_size_override("font_size", 11)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hbox.add_child(label)

		var btn := Button.new()
		if lvl >= max_lvl:
			btn.text = "MAX"
			btn.disabled = true
		else:
			btn.text = "$%d" % cost
			btn.disabled = GameManager.resources < cost
			btn.pressed.connect(_buy_upgrade.bind(upgrade_id))
		btn.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(btn)

		upgrade_list.add_child(hbox)
		upgrade_list.add_child(HSeparator.new())


# --- KLASY ---

func _build_class_list() -> void:
	for child in class_list.get_children():
		child.queue_free()

	# Show base classes
	var base_classes: Array[String] = ["assault", "sniper", "medic"]
	for cid in base_classes:
		var lbl := Label.new()
		lbl.text = "✅  %s  (domyślna)" % _get_class_display_name(cid)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		class_list.add_child(lbl)

	class_list.add_child(HSeparator.new())

	# Unlockable classes
	for class_id in CLASS_UNLOCK_MAP:
		var info: Dictionary = CLASS_UNLOCK_MAP[class_id]
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 11)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(80, 0)

		if GameManager.is_class_unlocked(class_id):
			label.text = "✅  %s  —  %s" % [info.name, info.desc]
			label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
			btn.text = "ODBLOK."
			btn.disabled = true
		elif info.arena not in GameManager.unlocked_arenas:
			label.text = "🔒  %s  —  Ukończ arenę: %s" % [info.name, info.arena]
			label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			btn.text = "🔒"
			btn.disabled = true
		else:
			label.text = "%s  —  %s" % [info.name, info.desc]
			btn.text = "$%d" % info.cost
			btn.disabled = GameManager.resources < info.cost
			btn.pressed.connect(_unlock_class.bind(class_id, info.cost))

		hbox.add_child(label)
		hbox.add_child(btn)
		class_list.add_child(hbox)


func _get_class_display_name(class_id: String) -> String:
	match class_id:
		"assault": return "Szturmowiec"
		"sniper": return "Snajper"
		"medic": return "Medyk"
		"engineer": return "Inżynier"
		"scout": return "Zwiadowca"
		"heavy": return "Ciężki"
	return class_id


# --- ACTIONS ---

func _on_arena_selected(arena: ArenaModifier) -> void:
	GameManager.current_arena = arena
	get_tree().change_scene_to_file("res://src/maps/arena.tscn")


func _buy_upgrade(upgrade_id: String) -> void:
	if GameManager.buy_upgrade(upgrade_id):
		_refresh_all()


func _unlock_class(class_id: String, cost: int) -> void:
	if GameManager.resources < cost:
		return
	GameManager.resources -= cost
	GameManager.unlock_class(class_id)
	_refresh_all()
