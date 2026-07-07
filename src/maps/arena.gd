## ArenaMap — orchiestracja areny: setup wizualny + delegacja narracji/save/audio
## Wcześniej: 309 linii i 7 odpowiedzialności. Teraz: ~140 linii, czysta orkiestracja.
class_name ArenaMap
extends Node2D

@export var arena_size: Vector2 = Vector2(2500, 1500)

var modifier: ArenaModifier = null

@onready var squad: Squad = $Squad
@onready var wave_manager: Node = $WaveManager
@onready var camera: Camera2D = $Squad/Camera2D

var _narrative: ArenaNarrative = null


func _ready() -> void:
	if modifier == null:
		modifier = GameManager.current_arena
	if modifier:
		arena_size = modifier.arena_size
	_build_visuals()
	if modifier and modifier.has_exploding_barrels:
		_spawn_barrels()
	GameManager.start_mission(wave_manager.total_waves)
	wave_manager.setup(self)
	if modifier:
		wave_manager.set_modifier(modifier)
	_apply_player_modifier()
	# Setup narrative pipeline
	_narrative = ArenaNarrative.new()
	_narrative.arena_id = modifier.arena_id if modifier else "jungle"
	add_child(_narrative)
	# Restore mid-run state if continuing
	if GameManager.restoring_run:
		_restore_run()
		_setup_music()
	else:
		# Music starts after briefing cutscene ends (no blip before duck)
		_narrative.briefing_done.connect(wave_manager.start)
		_narrative.briefing_done.connect(_setup_music, CONNECT_ONE_SHOT)
		_narrative.show_briefing()
	# Connect end-game flows
	EventBus.all_waves_cleared.connect(_on_all_waves_cleared)
	EventBus.squad_wiped.connect(_on_squad_wiped)


# --- Visual setup ---

func _build_visuals() -> void:
	# Floor — single ColorRect spanning whole arena
	var floor_color: Color = modifier.floor_color if modifier else Color(0.55, 0.55, 0.50)
	var floor_rect := ColorRect.new()
	floor_rect.color = floor_color
	floor_rect.position = -arena_size / 2.0
	floor_rect.size = arena_size
	floor_rect.z_index = -10
	add_child(floor_rect)

	# Debris — single Node2D w/ batched _draw zamiast 300 ColorRectów
	var debris := DebrisLayer.new()
	add_child(debris)
	var debris_count: int = modifier.debris_count if modifier else 300
	var debris_colors: Array = modifier.debris_colors if (modifier and not modifier.debris_colors.is_empty()) else []
	debris.generate(arena_size, debris_count, debris_colors)

	# Boundary walls
	_build_walls()


func _build_walls() -> void:
	var half := arena_size / 2.0
	var wall_color: Color = modifier.wall_color if modifier else Color(0.3, 0.3, 0.3)
	var walls_data := [
		{"pos": Vector2(0, -half.y), "size": Vector2(arena_size.x + 64, 32)},  # top
		{"pos": Vector2(0, half.y),  "size": Vector2(arena_size.x + 64, 32)},  # bottom
		{"pos": Vector2(-half.x, 0), "size": Vector2(32, arena_size.y + 64)},  # left
		{"pos": Vector2(half.x, 0),  "size": Vector2(32, arena_size.y + 64)},  # right
	]
	for data in walls_data:
		var body := StaticBody2D.new()
		body.position = data["pos"]
		body.collision_layer = 16
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = data["size"]
		shape.shape = rect
		body.add_child(shape)
		var vis := ColorRect.new()
		vis.color = wall_color
		vis.size = data["size"]
		vis.position = -data["size"] / 2.0
		body.add_child(vis)
		add_child(body)


func _spawn_barrels() -> void:
	var half := arena_size / 2.0
	var count: int = modifier.barrel_count if modifier else 0
	for i in count:
		var barrel := ExplodingBarrel.new()
		barrel.position = Vector2(
			randf_range(-half.x + 80, half.x - 80),
			randf_range(-half.y + 80, half.y - 80)
		)
		add_child(barrel)


func _apply_player_modifier() -> void:
	if modifier and modifier.player_speed_mult != 1.0:
		for s in get_tree().get_nodes_in_group("squad"):
			if s is Soldier:
				s.move_speed *= modifier.player_speed_mult


func _setup_music() -> void:
	var arena_id: String = modifier.arena_id if modifier else "jungle"
	SoundManager.play_music_layered(arena_id + "_base", arena_id + "_intense", 2.0)


# --- Spawn helpers (used by wave_manager) ---

func get_camera_edge_spawn_position() -> Vector2:
	if not is_instance_valid(camera):
		return _get_random_edge_position()
	var cam_pos: Vector2 = camera.global_position
	var view_half := Vector2(640.0, 360.0) / (2.0 * camera.zoom)
	var spawn_margin := 60.0
	var half := arena_size / 2.0
	var side := randi() % 4
	var pos := Vector2.ZERO
	match side:
		0:
			pos = Vector2(cam_pos.x + randf_range(-view_half.x, view_half.x), cam_pos.y - view_half.y - spawn_margin)
		1:
			pos = Vector2(cam_pos.x + randf_range(-view_half.x, view_half.x), cam_pos.y + view_half.y + spawn_margin)
		2:
			pos = Vector2(cam_pos.x - view_half.x - spawn_margin, cam_pos.y + randf_range(-view_half.y, view_half.y))
		3:
			pos = Vector2(cam_pos.x + view_half.x + spawn_margin, cam_pos.y + randf_range(-view_half.y, view_half.y))
	pos.x = clampf(pos.x, -half.x + 20, half.x - 20)
	pos.y = clampf(pos.y, -half.y + 20, half.y - 20)
	return pos


func _get_random_edge_position() -> Vector2:
	var half := arena_size / 2.0
	var margin := 40.0
	var side := randi() % 4
	match side:
		0: return Vector2(randf_range(-half.x + margin, half.x - margin), -half.y + margin)
		1: return Vector2(randf_range(-half.x + margin, half.x - margin), half.y - margin)
		2: return Vector2(-half.x + margin, randf_range(-half.y + margin, half.y - margin))
		3: return Vector2(half.x - margin, randf_range(-half.y + margin, half.y - margin))
	return Vector2.ZERO


func get_random_spawn_position() -> Vector2:
	var half := arena_size / 2.0
	var margin := 80.0
	return Vector2(
		randf_range(-half.x + margin, half.x - margin),
		randf_range(-half.y + margin, half.y - margin)
	)


# --- End-game flows ---

func _on_all_waves_cleared() -> void:
	_narrative.boss_dialog_done.connect(func(): _narrative.show_results(true), CONNECT_ONE_SHOT)
	_narrative.show_boss_dialog()


func _on_squad_wiped() -> void:
	# Dramatic hit stop then show results
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.12, true, false, true).timeout
	Engine.time_scale = 1.0
	get_tree().create_timer(0.9).timeout.connect(func(): _narrative.show_results(false))


func _restore_run() -> void:
	var data: Dictionary = GameManager.run_data
	GameManager.restoring_run = false
	GameManager.run_data = {}
	GameManager.gold = int(data.get("gold", 0))
	GameManager.xp = int(data.get("xp", 0))
	GameManager.level = int(data.get("level", 1))
	GameManager.enemies_killed = int(data.get("enemies_killed", 0))
	GameManager.gold_earned = int(data.get("gold_earned", 0))
	GameManager.max_streak = int(data.get("max_streak", 0))
	for pid in data.get("passive_ids", []):
		var item := PassiveItem.get_by_id(str(pid))
		if item:
			GameManager.add_passive(item)
	wave_manager.start_from_wave(int(data.get("current_wave", 1)))
