## HUD — Brotato-style layout
extends CanvasLayer

@onready var hp_bar: ProgressBar = $TopLeft/HPBar
@onready var lv_label: Label = $TopLeft/LVLabel
@onready var gold_label: Label = $GoldRow/GoldLabel
@onready var wave_label: Label = $TopRight/WaveLabel
@onready var timer_label: Label = $TopRight/TimerLabel
@onready var joystick: VirtualJoystick = $VirtualJoystick
@onready var pause_button: Button = $PauseButton

var _total_max_hp: int = 0
var _total_hp: int = 0
var _hp_bar_ready := false
var _wave_manager: Node = null


func _ready() -> void:
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_cleared.connect(_on_wave_cleared)
	EventBus.loot_collected.connect(_on_loot_collected)
	EventBus.item_purchased.connect(_on_item_purchased)
	EventBus.shop_closed.connect(_on_shop_closed)
	EventBus.soldier_died.connect(_on_soldier_died)
	EventBus.soldier_damaged.connect(_on_soldier_damaged)
	EventBus.xp_gained.connect(_on_xp_gained)
	EventBus.level_up.connect(_on_level_up)
	_update_gold(0)
	_update_wave(0, 5)
	timer_label.text = ""
	call_deferred("_update_hp_bar")
	call_deferred("_find_wave_manager")
	pause_button.pressed.connect(_on_pause_pressed)


func _process(_delta: float) -> void:
	if _wave_manager and _wave_manager.is_wave_active:
		var secs: int = ceili(_wave_manager.wave_time_left)
		timer_label.text = "%d:%02d" % [secs / 60, secs % 60]
		if secs <= 10:
			timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		else:
			timer_label.add_theme_color_override("font_color", Color(1, 1, 1))
	else:
		timer_label.text = ""


func _find_wave_manager() -> void:
	_wave_manager = get_tree().current_scene.get_node_or_null("WaveManager")


func get_joystick() -> VirtualJoystick:
	return joystick


func _on_wave_started(wave_number: int) -> void:
	_update_wave(wave_number, GameManager.total_waves)


func _on_wave_cleared(wave_number: int) -> void:
	# Show upcoming wave number during shop phase
	var next_wave: int = wave_number + 1
	if next_wave <= GameManager.total_waves:
		wave_label.text = "NASTĘPNA: WAVE %d" % next_wave
	else:
		wave_label.text = "OSTATNIA FALA!"


func _on_loot_collected(_value: int) -> void:
	_update_gold(GameManager.gold)


func _on_item_purchased(_item_id: String, _cost: int) -> void:
	_update_gold(GameManager.gold)


func _on_shop_closed() -> void:
	_update_gold(GameManager.gold)
	_update_hp_bar()


func _on_soldier_died(_soldier: Node2D) -> void:
	_update_hp_bar()


func _on_soldier_damaged(_soldier: Node2D) -> void:
	_update_hp_bar()


func _update_wave(current: int, _total: int) -> void:
	wave_label.text = "WAVE %d" % current


func _update_gold(amount: int) -> void:
	gold_label.text = str(amount)


func _update_hp_bar() -> void:
	var soldiers := get_tree().get_nodes_in_group("squad")
	var new_max: int = 0
	var new_hp: int = 0
	for soldier in soldiers:
		if soldier is Soldier:
			new_max += soldier.max_hp
			new_hp += soldier.hp
	var max_val: float = max(new_max, 1)
	if not _hp_bar_ready or new_max != _total_max_hp:
		hp_bar.init_bar(max_val)
		_hp_bar_ready = true
	_total_max_hp = new_max
	_total_hp = new_hp
	hp_bar.update_bar(_total_hp)
	lv_label.text = "LV.%d" % GameManager.level


func _on_xp_gained(_amount: int) -> void:
	_update_xp_bar()


func _on_level_up(new_level: int) -> void:
	lv_label.text = "LV.%d" % new_level
	_update_xp_bar()
	_update_hp_bar()


func _update_xp_bar() -> void:
	var xp_bar := get_node_or_null("TopLeft/XPBar") as ProgressBar
	if xp_bar:
		xp_bar.max_value = max(GameManager.xp_to_next_level, 1)
		xp_bar.value = GameManager.xp


func _on_pause_pressed() -> void:
	var pause_menu_scene := preload("res://src/ui/pause_menu.tscn")
	var menu := pause_menu_scene.instantiate()
	get_tree().current_scene.add_child(menu)
	get_tree().paused = true
