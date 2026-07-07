## KillStreak — combo counter z wizualnym feedbackiem i mechanicznymi bonusami
extends CanvasLayer

var _kill_count: int = 0
var _combo_timer: float = 0.0
const COMBO_WINDOW: float = 2.0
const MIN_STREAK: int = 3
var _active: bool = false

var _label: Label
var _bonus_label: Label
var _tween: Tween = null

# Tiery — każdy tier od min_kills wzwyż daje podane bonusy
# Ważne: sprawdzane od najwyższego do najniższego
const STREAK_TIERS: Array = [
	{"min": 10, "speed": 0.25, "damage": 0.20, "color": Color(1.0, 0.25, 0.1),  "label": "ON FIRE!"},
	{"min": 5,  "speed": 0.15, "damage": 0.10, "color": Color(1.0, 0.55, 0.0),  "label": "HOT!"},
	{"min": 3,  "speed": 0.10, "damage": 0.0,  "color": Color(1.0, 0.85, 0.1),  "label": "KILL STREAK"},
]


func _ready() -> void:
	layer = 5
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.anchor_left = 0.5
	_label.anchor_right = 0.5
	# Poniżej HUD (HP bar ~50px) — nie koliduje z interfejsem
	_label.anchor_top = 0.0
	_label.anchor_bottom = 0.0
	_label.offset_left = -180
	_label.offset_right = 180
	_label.offset_top = 58
	_label.offset_bottom = 100
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.grow_vertical = Control.GROW_DIRECTION_END
	_label.pivot_offset = Vector2(180, 21)
	_label.add_theme_font_size_override("font_size", 20)
	# Outline (biały, gruby) — czytelny na każdym tle
	_label.add_theme_constant_override("outline_size", 5)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	_label.visible = false
	add_child(_label)

	# Bonus info pod głównym licznikiem
	_bonus_label = Label.new()
	_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bonus_label.anchor_left = 0.5
	_bonus_label.anchor_right = 0.5
	_bonus_label.anchor_top = 0.0
	_bonus_label.anchor_bottom = 0.0
	_bonus_label.offset_left = -180
	_bonus_label.offset_right = 180
	_bonus_label.offset_top = 100
	_bonus_label.offset_bottom = 122
	_bonus_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bonus_label.grow_vertical = Control.GROW_DIRECTION_END
	_bonus_label.add_theme_font_size_override("font_size", 13)
	_bonus_label.add_theme_constant_override("outline_size", 4)
	_bonus_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	_bonus_label.visible = false
	add_child(_bonus_label)

	EventBus.enemy_killed_at.connect(_on_enemy_killed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_cleared.connect(_on_wave_ended)
	EventBus.shop_opened.connect(_force_hide)


func _on_wave_started(_wave: int) -> void:
	_active = true
	_kill_count = 0
	_combo_timer = 0.0
	_force_hide()


func _on_wave_ended(_wave: int) -> void:
	_active = false
	_force_hide()


func _force_hide() -> void:
	_kill_count = 0
	_combo_timer = 0.0
	_clear_bonuses()
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
	_label.visible = false
	_bonus_label.visible = false
	_label.modulate = Color.WHITE
	_bonus_label.modulate = Color.WHITE


func _on_enemy_killed(_pos: Vector2) -> void:
	if not _active:
		return
	_kill_count += 1
	_combo_timer = COMBO_WINDOW
	if _kill_count > GameManager.max_streak:
		GameManager.max_streak = _kill_count
	if _kill_count >= MIN_STREAK:
		_show_streak()
		_apply_streak_bonuses()


func _get_tier() -> Dictionary:
	for tier in STREAK_TIERS:
		if _kill_count >= tier["min"]:
			return tier
	return {}


func _apply_streak_bonuses() -> void:
	var tier := _get_tier()
	if tier.is_empty():
		_clear_bonuses()
		return
	GameManager.streak_speed_bonus = tier["speed"]
	GameManager.streak_damage_bonus = tier["damage"]


func _clear_bonuses() -> void:
	GameManager.streak_speed_bonus = 0.0
	GameManager.streak_damage_bonus = 0.0


func _show_streak() -> void:
	var tier := _get_tier()
	if tier.is_empty():
		return
	var tier_color: Color = tier["color"]
	var tier_label: String = tier["label"]

	_label.text = "× %d  %s" % [_kill_count, tier_label]
	_label.add_theme_color_override("font_color", tier_color)
	_label.visible = true
	_label.modulate = Color.WHITE

	# Bonus info
	var parts: Array[String] = []
	if tier["speed"] > 0.0:
		parts.append("+%d%% SPD" % int(tier["speed"] * 100))
	if tier["damage"] > 0.0:
		parts.append("+%d%% DMG" % int(tier["damage"] * 100))
	if parts.size() > 0:
		_bonus_label.text = "  ".join(parts)
		_bonus_label.add_theme_color_override("font_color", tier_color.lightened(0.3))
		_bonus_label.visible = true
	else:
		_bonus_label.visible = false

	# Pulse effect
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_label.scale = Vector2(1.3, 1.3)
	_tween.tween_property(_label, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_end_streak()


func _end_streak() -> void:
	_clear_bonuses()
	if _kill_count >= MIN_STREAK and _label.visible:
		if _tween and _tween.is_valid():
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(_label, "modulate:a", 0.0, 0.4)
		_tween.parallel().tween_property(_bonus_label, "modulate:a", 0.0, 0.4)
		_tween.tween_callback(func():
			_label.visible = false
			_bonus_label.visible = false
		)
	_kill_count = 0
