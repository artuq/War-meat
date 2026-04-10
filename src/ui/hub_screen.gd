## HubScreen — ekran główny: wybór areny, ulepszenia, klasy
extends CanvasLayer

@onready var tab_container: TabContainer = $Panel/TabContainer
@onready var arena_list: VBoxContainer = $Panel/TabContainer/Areny/ArenaList
@onready var upgrade_list: VBoxContainer = $Panel/TabContainer/Ulepszenia/ScrollContainer/UpgradeList
@onready var class_list: VBoxContainer = $Panel/TabContainer/Klasy/ScrollContainer/ClassList
@onready var resources_label: Label = $Panel/ResourcesLabel

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
	_refresh_all()


func _refresh_all() -> void:
	resources_label.text = "Surowce: %d" % GameManager.resources
	_build_arena_list()
	_build_upgrade_list()
	_build_class_list()


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
