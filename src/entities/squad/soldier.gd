## Soldier — pojedynczy żołnierz w oddziale
class_name Soldier
extends CharacterBody2D

@export var move_speed: float = 80.0

const VISUAL_SCALE := 0.4

# HP zarządzane przez HealthComponent (komponent jako single source of truth).
# Properties hp/max_hp delegują — wszystkie istniejące call sites działają bez zmian.
var max_hp: int:
	get:
		return health_component.max_health if health_component else 100
	set(value):
		if health_component:
			health_component.set_max(value)

var hp: int:
	get:
		return health_component.current_health if health_component else 100
	set(value):
		if health_component:
			var old: int = health_component.current_health
			health_component.current_health = clampi(value, 0, health_component.max_health)
			# Jeśli setowanie zmniejsza HP — odpal sygnał on_unit_hit dla efektów
			if value < old:
				health_component.on_unit_hit.emit()
			health_component.on_health_changed.emit(health_component.current_health, health_component.max_health)
			if health_component.current_health == 0 and old > 0:
				health_component.on_unit_died.emit()
var target: Node2D = null
var weapon: WeaponData = null
var soldier_class: SoldierClass = null
var damage_mult: float = 1.0
var luck: float = 10.0
var dodge_chance: float = 0.0
var armor: int = 0
var range_mult: float = 1.0
var fire_rate_mult: float = 1.0

const IFRAME_DURATION := 0.5
var is_invulnerable: bool = false
var _muzzle_offset: float = 38.0
var _anim_offset: float = 0.0

@onready var _dust: CPUParticles2D = $Dust
var _move_timer: float = 0.0
var _prev_pos: Vector2 = Vector2.ZERO

@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var muzzle: Marker2D = $WeaponPivot/Muzzle
@onready var body_sprite: Sprite2D = $BodySprite
@onready var shadow_sprite: Sprite2D = $BodySprite/Shadow
@onready var hand_back: Sprite2D = $WeaponPivot/HandBack
@onready var hand_front: Sprite2D = $WeaponPivot/HandFront
@onready var weapon_sprite_node: Sprite2D = $WeaponPivot/WeaponSprite
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var health_component: HealthComponent = $HealthComponent

# Sprite textures per class / weapon type (null = _draw() fallback)
var _body_textures: Dictionary = {
	SoldierClass.ClassType.ASSAULT: preload("res://assets/sprites/soldiers/Assault.png"),
	SoldierClass.ClassType.ENGINEER: preload("res://assets/sprites/soldiers/Engineer.png"),
	SoldierClass.ClassType.HEAVY: preload("res://assets/sprites/soldiers/Heavy.png"),
	SoldierClass.ClassType.MEDIC: preload("res://assets/sprites/soldiers/Medic.png"),
	SoldierClass.ClassType.SCOUT: preload("res://assets/sprites/soldiers/Scout.png"),
	SoldierClass.ClassType.SNIPER: preload("res://assets/sprites/soldiers/Sniper.png"),
}
## Preload all weapon textures up front so missing files fail at compile time,
## not silently at runtime (regression guard — gracz-z-pustymi-rękami bug).
var _weapon_textures: Dictionary = {
	WeaponData.Type.RIFLE: preload("res://assets/sprites/weapons/rifle.png"),
	WeaponData.Type.SHOTGUN: preload("res://assets/sprites/weapons/shotgun.png"),
	WeaponData.Type.SMG: preload("res://assets/sprites/weapons/smg.png"),
	WeaponData.Type.SNIPER_RIFLE: preload("res://assets/sprites/weapons/sniper_rifle.png"),
	WeaponData.Type.MELEE: preload("res://assets/sprites/weapons/knife.png"),
	WeaponData.Type.GRENADE: preload("res://assets/sprites/weapons/grenade_launcher.png"),
	WeaponData.Type.PISTOL: preload("res://assets/sprites/weapons/pistol.png"),
}
var _has_sprite: bool = false
var _flash_mat: ShaderMaterial = null
var _shadow_mat: ShaderMaterial = null
const _FLASH_SHADER := preload("res://src/effects/flash.gdshader")
const _SHADOW_SHADER := preload("res://src/effects/shadow.gdshader")


func _ready() -> void:
	if soldier_class == null:
		soldier_class = SoldierClass.create_assault()
	# Hook up HealthComponent before _apply_class (apply_class sets max_hp via property)
	health_component.on_unit_died.connect(_die)
	_apply_class()
	# Pełne HP po spawnie
	health_component.setup(max_hp, true)
	add_to_group("squad")
	if weapon == null:
		weapon = SoldierClass.get_default_weapon(soldier_class)
	_apply_weapon()
	_apply_visual()
	_prev_pos = global_position


	_anim_offset = randf()
	# Uruchom animację Idle od razu po spawnie z losowym offsetem
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle")
		anim_player.seek(_anim_offset * anim_player.current_animation_length, true)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	detection_area.body_entered.connect(_on_body_entered_detection)
	detection_area.body_exited.connect(_on_body_exited_detection)




func configure_class(sc: SoldierClass) -> void:
	soldier_class = sc
	_apply_class()
	weapon = SoldierClass.get_default_weapon(sc)
	_apply_weapon()
	_apply_visual()
	queue_redraw()


func _apply_class() -> void:
	max_hp = soldier_class.base_hp
	move_speed = soldier_class.base_speed
	damage_mult = soldier_class.damage_mult
	luck = soldier_class.base_luck


func _apply_visual() -> void:
	if soldier_class and _body_textures.has(soldier_class.class_type):
		var tex: Texture2D = _body_textures[soldier_class.class_type]
		body_sprite.texture = tex
		body_sprite.scale = Vector2(VISUAL_SCALE, VISUAL_SCALE)
		body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		body_sprite.visible = true
		_has_sprite = true
		# Flash shader na body_sprite — nie koliduje z modulate weaponów ani innych efektów
		if _flash_mat == null:
			_flash_mat = ShaderMaterial.new()
			_flash_mat.shader = _FLASH_SHADER
		body_sprite.material = _flash_mat
		# Shadow jest dzieckiem BodySprite — dziedziczy animacje (bob, rotation)
		shadow_sprite.texture = tex
		shadow_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		shadow_sprite.scale = Vector2.ONE
		shadow_sprite.modulate = Color.WHITE
		if _shadow_mat == null:
			_shadow_mat = ShaderMaterial.new()
			_shadow_mat.shader = _SHADOW_SHADER
			_shadow_mat.set_shader_parameter("look_right", true)
			_shadow_mat.set_shader_parameter("shadow_alpha", 0.5)
			_shadow_mat.set_shader_parameter("skew_strength", 0.4)
		shadow_sprite.material = _shadow_mat
		shadow_sprite.visible = true
		# Hands baked into weapon sprites (Brotato-style) — hide separate hand nodes
		hand_back.visible = false
		hand_front.visible = false
	else:
		body_sprite.visible = false
		shadow_sprite.visible = false
		hand_back.visible = false
		hand_front.visible = false
		_has_sprite = false
	_apply_weapon_visual()
	queue_redraw()


func _apply_weapon_visual() -> void:
	if weapon == null:
		weapon_sprite_node.visible = false
		push_warning("[Soldier] _apply_weapon_visual: weapon == null, hiding sprite")
		return
	var tex: Texture2D = null
	if _weapon_textures.has(weapon.type):
		tex = _weapon_textures[weapon.type]
	elif weapon.texture_path != "" and ResourceLoader.exists(weapon.texture_path):
		tex = load(weapon.texture_path)
	if tex == null:
		weapon_sprite_node.visible = false
		push_warning("[Soldier] No sprite found for weapon type=%s (texture_path=%s)" % [weapon.type, weapon.texture_path])
		return
	weapon_sprite_node.texture = tex
	weapon_sprite_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Sprites designed at correct relative sizes — apply uniform scale so
	# rifle (128px) stays wider than pistol (80px), sniper (160px) widest.
	weapon_sprite_node.scale = Vector2(VISUAL_SCALE, VISUAL_SCALE)
	_muzzle_offset = weapon_sprite_node.position.x + float(tex.get_width()) * 0.5 * VISUAL_SCALE
	weapon_sprite_node.visible = true


func _draw() -> void:
	if _has_sprite:
		return
	var color := soldier_class.draw_color if soldier_class else Color(0.2, 0.8, 0.2)
	var radius := soldier_class.draw_radius if soldier_class else 6.0
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color.darkened(0.3), 1.0)
	# Orbiting weapon barrel
	if weapon_pivot:
		var gun_dir := Vector2.RIGHT.rotated(weapon_pivot.rotation)
		var gun_start := gun_dir * (radius - 1.0)
		var gun_end := gun_dir * (radius + 7.0)
		draw_line(gun_start, gun_end, Color(0.75, 0.75, 0.75), 2.0)
		# Muzzle dot
		draw_circle(gun_end, 1.5, Color(1.0, 0.95, 0.5))


func set_weapon(new_weapon: WeaponData) -> void:
	weapon = new_weapon
	_apply_weapon()
	_apply_weapon_visual()


func _apply_weapon() -> void:
	attack_timer.wait_time = 1.0 / (weapon.fire_rate * fire_rate_mult)
	var det_shape: CircleShape2D = detection_area.get_child(0).shape
	det_shape.radius = weapon.attack_range * range_mult


func _get_squad_separation() -> Vector2:
	var force := Vector2.ZERO
	const RADIUS := 58.0
	const STRENGTH := 180.0
	for ally in get_tree().get_nodes_in_group("squad"):
		if ally == self or not is_instance_valid(ally):
			continue
		var diff: Vector2 = global_position - ally.global_position
		var dist: float = diff.length()
		if dist < RADIUS and dist > 0.01:
			force += diff.normalized() * (RADIUS - dist) / RADIUS * STRENGTH
	return force


func _physics_process(delta: float) -> void:
	var sep := _get_squad_separation()
	if velocity != Vector2.ZERO or sep.length() > 1.0:
		velocity += sep
		move_and_slide()
	_update_target()
	# Weapon orbit — keep pivot in right half-plane [-90°, +90°] at all times.
	# flip_h mirrors the sprite left↔right so the barrel points toward the target
	# even when the target is on the left side.
	if is_instance_valid(target):
		var dir := (target.global_position - weapon_pivot.global_position).normalized()
		var aim_left := dir.x < 0
		weapon_sprite_node.flip_h = aim_left
		var target_rot: float
		if aim_left:
			target_rot = atan2(-dir.y, -dir.x)
			muzzle.position.x = -_muzzle_offset
		else:
			target_rot = atan2(dir.y, dir.x)
			muzzle.position.x = _muzzle_offset
		# Płynny obrót broni — lerp_angle obsługuje przejście przez ±π bez "skoku"
		weapon_pivot.rotation = lerp_angle(weapon_pivot.rotation, target_rot, 14.0 * delta)
	# Moving state — mierzymy faktyczną zmianę pozycji (niezawodne przy
	# kolizjach i oscylacji velocity). >0.5j/klatkę = ruch.
	var dist_moved := global_position.distance_to(_prev_pos)
	_prev_pos = global_position
	if dist_moved > 0.5:
		_move_timer = 0.2
	elif _move_timer > 0.0:
		_move_timer -= delta
	var moving: bool = _move_timer > 0.0
	if _dust:
		_dust.emitting = moving
	# Sprite direction + movement wobble
	if _has_sprite:
		var facing_left: bool = false
		if is_instance_valid(target):
			facing_left = target.global_position.x < global_position.x
		body_sprite.flip_h = facing_left
		if shadow_sprite.material is ShaderMaterial:
			(shadow_sprite.material as ShaderMaterial).set_shader_parameter("look_right", not facing_left)
		# Animations — przełącz między Idle i Move
		if anim_player:
			var anim := "Move" if moving else "Idle"
			if anim_player.has_animation(anim) and anim_player.current_animation != anim:
				anim_player.play(anim)
				anim_player.seek(randf() * anim_player.current_animation_length, true)
			elif not anim_player.has_animation(anim):
				# Fallback proceduralny gdy brak animacji w scenie
				if moving:
					body_sprite.rotation = sin(Time.get_ticks_msec() * 0.01) * 0.08
				else:
					body_sprite.rotation = lerpf(body_sprite.rotation, 0.0, 10.0 * delta)
	queue_redraw()
	if soldier_class and soldier_class.class_type == SoldierClass.ClassType.MEDIC:
		_medic_heal(delta)
	_passive_regen(delta)


var _heal_timer: float = 0.0
var hp_regen_per_10s: float = 0.0
var _regen_timer: float = 0.0


func _passive_regen(delta: float) -> void:
	if hp_regen_per_10s <= 0.0 or hp >= max_hp:
		return
	_regen_timer -= delta
	if _regen_timer > 0.0:
		return
	_regen_timer = 10.0
	health_component.heal(int(hp_regen_per_10s))
	EventBus.soldier_damaged.emit(self)


func _medic_heal(delta: float) -> void:
	_heal_timer -= delta
	if _heal_timer > 0.0:
		return
	_heal_timer = 2.0
	var allies := get_tree().get_nodes_in_group("squad")
	for ally in allies:
		if ally is Soldier and ally != self and ally.hp < ally.max_hp:
			ally.health_component.heal(5)
			EventBus.soldier_damaged.emit(ally)


func take_damage(amount: int) -> void:
	if is_invulnerable:
		return
	if dodge_chance > 0.0 and randf() < dodge_chance:
		return
	is_invulnerable = true
	var final_amount: int = maxi(amount - armor, 1)
	# HP delegowane do komponentu — on_unit_died sygnał wywoła _die() automatycznie
	health_component.take_damage(final_amount)
	EventBus.soldier_damaged.emit(self)
	EventBus.screen_shake_requested.emit(2.5, 0.12)
	_flash_damage()
	if health_component.is_alive():
		get_tree().create_timer(IFRAME_DURATION, true, false, true).timeout.connect(
			func(): if is_instance_valid(self): is_invulnerable = false
		)


func _flash_damage() -> void:
	if _flash_mat:
		# Czerwony flash przez shader — nie rusza modulate, nie koliduje z i-framami
		_flash_mat.set_shader_parameter("flash_color", Vector4(1.0, 0.15, 0.15, 1.0))
		_flash_mat.set_shader_parameter("flash_amount", 1.0)
		var tween := create_tween()
		tween.tween_method(
			func(v: float): _flash_mat.set_shader_parameter("flash_amount", v),
			1.0, 0.0, 0.18
		)
	else:
		modulate = Color(1.0, 0.3, 0.3)
		var tween := create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.15)


func _die() -> void:
	EventBus.soldier_died.emit(self)
	queue_free()


func _update_target() -> void:
	if is_instance_valid(target):
		return
	# Szukaj najbliższego wroga w zasięgu
	var enemies := detection_area.get_overlapping_bodies()
	var closest_dist := INF
	target = null
	for enemy in enemies:
		if enemy.is_in_group("enemies"):
			var dist := global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				target = enemy


func _on_attack_timer_timeout() -> void:
	if is_instance_valid(target):
		_shoot_at(target)


func _shoot_at(enemy: Node2D) -> void:
	var projectile_scene := preload("res://src/entities/projectiles/projectile.tscn")
	# Weapon recoil — snap back then spring forward
	var orig_x := weapon_sprite_node.position.x
	var recoil := create_tween()
	recoil.tween_property(weapon_sprite_node, "position:x", orig_x - 4.0, 0.04)
	recoil.tween_property(weapon_sprite_node, "position:x", orig_x, 0.10).set_ease(Tween.EASE_OUT)
	# Muzzle flash particle
	var flash_dir: Vector2 = (enemy.global_position - global_position).normalized()
	var flash := ParticleFactory.create_muzzle_flash(muzzle.global_position, flash_dir)
	get_tree().current_scene.add_child(flash)
	# Weapon SFX
	SoundManager.play_weapon_sfx("rifle", muzzle.global_position)
	# Predictive aiming — celuj tam, gdzie wróg będzie za chwilę
	var to_enemy: Vector2 = enemy.global_position - global_position
	var dist: float = to_enemy.length()
	var time_to_hit: float = dist / weapon.projectile_speed
	var enemy_vel: Vector2 = enemy.velocity if enemy is CharacterBody2D else Vector2.ZERO
	var predicted_pos: Vector2 = enemy.global_position + enemy_vel * time_to_hit
	var base_dir: Vector2 = (predicted_pos - global_position).normalized()
	var crit_chance: float = clampf(luck / 200.0, 0.0, 0.5)
	for i in weapon.projectile_count:
		var proj: Projectile = projectile_scene.instantiate()
		var is_crit: bool = randf() < crit_chance
		var base_damage: int = int(weapon.damage * damage_mult * (1.0 + GameManager.streak_damage_bonus))
		proj.damage = base_damage * 2 if is_crit else base_damage
		proj.is_crit = is_crit
		proj.speed = weapon.projectile_speed
		if weapon.projectile_count > 1:
			var offset: float = -weapon.spread_angle / 2.0 + weapon.spread_angle * (float(i) / maxf(float(weapon.projectile_count - 1), 1.0))
			proj.direction = base_dir.rotated(offset)
		else:
			var spread: float = randf_range(-weapon.spread_angle, weapon.spread_angle)
			proj.direction = base_dir.rotated(spread)
		proj.global_position = muzzle.global_position
		get_tree().current_scene.add_child(proj)


func _on_body_entered_detection(body: Node2D) -> void:
	if body.is_in_group("enemies") and not is_instance_valid(target):
		target = body


func _on_body_exited_detection(body: Node2D) -> void:
	if body == target:
		target = null
