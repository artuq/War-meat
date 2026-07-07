## Boss — bazowy boss z fazami HP
class_name Boss
extends CharacterBody2D

enum BossType { JUNGLE, DESERT, BUNKER }

@export var boss_type: BossType = BossType.JUNGLE
@export var move_speed: float = 35.0
@export var contact_damage: int = 15
@export var gold_value: int = 200
@export var xp_value: int = 100

# HP delegowane do HealthComponent
var max_hp: int:
	get:
		return health_component.max_health if health_component else 500
	set(value):
		if health_component:
			health_component.set_max(value)

var hp: int:
	get:
		return health_component.current_health if health_component else 500
	set(value):
		if health_component:
			var old: int = health_component.current_health
			health_component.current_health = clampi(value, 0, health_component.max_health)
			if value < old:
				health_component.on_unit_hit.emit()
			health_component.on_health_changed.emit(health_component.current_health, health_component.max_health)
			if health_component.current_health == 0 and old > 0:
				health_component.on_unit_died.emit()
var target: Node2D = null
var phase: int = 1  # 1 = >50% HP, 2 = 25-50%, 3 = <25%
var _contact_timer: float = 0.0
var _ability_timer: float = 0.0
var _ability_cooldown: float = 3.0
var _dash_speed: float = 200.0
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _shield_active: bool = false

var enemy_scene: PackedScene = preload("res://src/entities/enemies/enemy_rusher.tscn")
var _enemy_proj_scene: PackedScene = preload("res://src/entities/enemies/enemy_projectile.tscn")

# Sprite textures per boss type
var _boss_textures: Dictionary = {
	BossType.JUNGLE: preload("res://assets/sprites/enemies/boss_jungle.png"),
	BossType.DESERT: preload("res://assets/sprites/enemies/boss_desert.png"),
	BossType.BUNKER: preload("res://assets/sprites/enemies/boss_bunker.png"),
}
var _shield_texture: Texture2D = preload("res://assets/sprites/enemies/shield_overlay.png")
var _has_sprite: bool = false
var _bob_time: float = 0.0
const BOSS_SCALE := 0.5

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var body_sprite: Sprite2D = $BodySprite
@onready var shield_sprite: Sprite2D = $ShieldSprite
@onready var shadow_sprite: Sprite2D = $Shadow
@onready var health_component: HealthComponent = $HealthComponent


func _ready() -> void:
	# Hook up HealthComponent before configure (configure() called post add_child)
	health_component.on_unit_died.connect(_die)
	health_component.setup(max_hp, true)
	add_to_group("enemies")
	add_to_group("boss")
	collision_layer = 2
	collision_mask = 17
	_apply_visual()
	queue_redraw()


func _apply_visual() -> void:
	if _boss_textures.has(boss_type):
		body_sprite.texture = _boss_textures[boss_type]
		body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		body_sprite.scale = Vector2(BOSS_SCALE, BOSS_SCALE)
		body_sprite.visible = true
		_has_sprite = true
		shadow_sprite.visible = true
	else:
		body_sprite.visible = false
	shield_sprite.texture = _shield_texture


func _update_shield_sprite() -> void:
	shield_sprite.visible = _shield_active


func _get_boss_separation() -> Vector2:
	var force := Vector2.ZERO
	const RADIUS := 80.0
	const STRENGTH := 200.0
	for other in get_tree().get_nodes_in_group("boss"):
		if other == self or not is_instance_valid(other):
			continue
		var diff: Vector2 = global_position - other.global_position
		var dist: float = diff.length()
		if dist < RADIUS and dist > 0.01:
			force += diff.normalized() * (RADIUS - dist) / RADIUS * STRENGTH
	return force


func configure(type: BossType, wave: int) -> void:
	boss_type = type
	var scale_mult := 1.0 + (wave - 1) * 0.1
	match type:
		BossType.JUNGLE:
			max_hp = int(400 * scale_mult)
			move_speed = 50.0
			contact_damage = 12
			gold_value = 150
			_ability_cooldown = 2.5
		BossType.DESERT:
			max_hp = int(350 * scale_mult)
			move_speed = 30.0
			contact_damage = 8
			gold_value = 180
			_ability_cooldown = 2.0
		BossType.BUNKER:
			max_hp = int(600 * scale_mult)
			move_speed = 20.0
			contact_damage = 20
			gold_value = 220
			_ability_cooldown = 3.5
	hp = max_hp
	# Re-apply visual — configure jest wywołwane PO add_child/_ready,
	# więc boss_type był domyślny (JUNGLE) podczas pierwszego _apply_visual.
	_apply_visual()
	queue_redraw()


func _draw() -> void:
	# --- Phase-tinted modulate (sprite) ---
	if _has_sprite:
		var phase_tint := Color.WHITE
		if phase == 2:
			phase_tint = Color(1.0, 0.85, 0.4)  # warm orange
		elif phase == 3:
			phase_tint = Color(1.0, 0.4, 0.3)   # angry red
		body_sprite.modulate = phase_tint
		# Shield overlay via Sprite2D (no draw_arc needed)
		shield_sprite.visible = _shield_active
	else:
		# Fallback _draw() primitives when sprite is missing
		var radius := 14.0
		var color := Color.WHITE
		match boss_type:
			BossType.JUNGLE:
				color = Color(0.1, 0.8, 0.3)
			BossType.DESERT:
				color = Color(0.9, 0.7, 0.2)
			BossType.BUNKER:
				color = Color(0.5, 0.5, 0.6)
		if _shield_active:
			draw_arc(Vector2.ZERO, 18.0, 0, TAU, 32, Color(0.3, 0.6, 1.0, 0.6), 2.0)
		draw_circle(Vector2.ZERO, radius, color)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color.darkened(0.4), 2.0)
		var inner_color := Color(1, 1, 1, 0.3)
		if phase == 2:
			inner_color = Color(1, 0.8, 0.2, 0.5)
		elif phase == 3:
			inner_color = Color(1, 0.2, 0.1, 0.6)
		draw_circle(Vector2.ZERO, 6.0, inner_color)

	# HP bar above boss (always drawn, regardless of sprite)
	var bar_width := 30.0
	var bar_y := -20.0
	var hp_ratio: float = float(hp) / max(max_hp, 1)
	draw_rect(Rect2(-bar_width / 2, bar_y, bar_width, 4), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_width / 2, bar_y, bar_width * hp_ratio, 4), Color(1, 0.2, 0.2))


func _physics_process(delta: float) -> void:
	_bob_time += delta
	if _has_sprite:
		# Pulse scale based on phase — angrier = faster breathing
		var pulse_speed := 1.5 + (phase - 1) * 0.8
		var pulse_amp := 0.03 + (phase - 1) * 0.015
		var pulse := BOSS_SCALE + sin(_bob_time * pulse_speed * TAU) * pulse_amp
		body_sprite.scale = Vector2(pulse, pulse)
		# Wobble when moving
		if velocity.length() > 5.0:
			body_sprite.rotation = sin(_bob_time * 8.0) * 0.06
		else:
			body_sprite.rotation = lerpf(body_sprite.rotation, 0.0, 8.0 * delta)
		# Flip toward target
		if is_instance_valid(target):
			body_sprite.flip_h = target.global_position.x < global_position.x
	_find_target()
	_update_phase()
	_ability_timer -= delta
	velocity += _get_boss_separation()

	if not is_instance_valid(target):
		return

	var direction := (target.global_position - global_position).normalized()

	# Dash movement
	if _is_dashing:
		_dash_timer -= delta
		velocity = direction * _dash_speed
		move_and_slide()
		if _dash_timer <= 0.0:
			_is_dashing = false
		_check_contact(delta)
		return

	# Normal movement
	var current_speed := move_speed
	if phase >= 3:
		current_speed *= 1.3  # berserk speed
	velocity = direction * current_speed
	move_and_slide()
	_check_contact(delta)

	# Ability usage
	if _ability_timer <= 0.0:
		_use_ability()
		var cd: float = _ability_cooldown
		if phase >= 2:
			cd *= 0.7  # faster abilities in later phases
		_ability_timer = cd


func _update_phase() -> void:
	var hp_ratio: float = float(hp) / max(max_hp, 1)
	var new_phase: int = 1
	if hp_ratio <= 0.25:
		new_phase = 3
	elif hp_ratio <= 0.50:
		new_phase = 2
	if new_phase != phase:
		phase = new_phase
		queue_redraw()


func _use_ability() -> void:
	match boss_type:
		BossType.JUNGLE:
			_jungle_ability()
		BossType.DESERT:
			_desert_ability()
		BossType.BUNKER:
			_bunker_ability()


func _jungle_ability() -> void:
	if phase >= 2 and randf() < 0.5:
		# Summon 2-3 Rushers
		var count: int = 2 if phase == 2 else 3
		for i in count:
			var e: Enemy = enemy_scene.instantiate()
			var offset := Vector2(randf_range(-30, 30), randf_range(-30, 30))
			e.global_position = global_position + offset
			get_tree().current_scene.add_child(e)
			e.configure(Enemy.EnemyType.RUSHER, GameManager.current_wave)
	else:
		# Dash attack
		_is_dashing = true
		_dash_timer = 0.4


func _desert_ability() -> void:
	if not is_instance_valid(target):
		return
	# Shoot burst of projectiles
	var dir := (target.global_position - global_position).normalized()
	var bullet_count: int = 3 if phase < 3 else 5
	var spread := 0.3 if phase < 3 else 0.5
	for i in bullet_count:
		var angle_offset: float = (float(i) - float(bullet_count - 1) / 2.0) * spread
		var proj: EnemyProjectile = _enemy_proj_scene.instantiate()
		proj.damage = contact_damage
		proj.speed = 200.0
		proj.direction = dir.rotated(angle_offset)
		proj.global_position = global_position + dir * 16.0
		get_tree().current_scene.add_child(proj)


func _bunker_ability() -> void:
	if phase == 1:
		# Shield — reduce incoming damage for a bit
		_shield_active = true
		queue_redraw()
		var timer := get_tree().create_timer(2.0)
		timer.timeout.connect(_drop_shield)
	else:
		# Berserk charge
		_is_dashing = true
		_dash_timer = 0.6
		_dash_speed = 250.0


func _drop_shield() -> void:
	_shield_active = false
	queue_redraw()


func take_damage(amount: int) -> void:
	if not health_component.is_alive():
		return
	if _shield_active:
		amount = int(amount * 0.3)
	# HP delegowane do komponentu — on_unit_died sygnał wywoła _die() automatycznie
	health_component.take_damage(amount)
	queue_redraw()
	_spawn_damage_number(amount)


func _spawn_damage_number(amount: int) -> void:
	if not SettingsManager.damage_numbers_enabled:
		return
	var dn := preload("res://src/systems/damage_number.gd").new()
	dn.value = amount
	dn.global_position = global_position + Vector2(0, -12)
	get_tree().current_scene.add_child(dn)


func _die() -> void:
	var death_fx := ParticleFactory.create_death_puff(global_position, Color(0.8, 0.2, 0.1))
	get_tree().current_scene.add_child(death_fx)
	EventBus.enemy_killed.emit(self, global_position)
	EventBus.enemy_killed_at.emit(global_position)
	EventBus.loot_dropped.emit(global_position, gold_value)
	GameManager.add_xp(xp_value)
	queue_free()


func _find_target() -> void:
	if is_instance_valid(target):
		return
	var squad_members := get_tree().get_nodes_in_group("squad")
	var closest_dist := INF
	for member in squad_members:
		var dist := global_position.distance_to(member.global_position)
		if dist < closest_dist:
			closest_dist = dist
			target = member


func _check_contact(delta: float) -> void:
	_contact_timer -= delta
	if _contact_timer > 0.0:
		return
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is Soldier:
			collider.take_damage(contact_damage)
			_contact_timer = 0.5
			break
