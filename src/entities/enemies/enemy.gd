## Enemy — bazowy wróg z wariantami (Brotato-style)
class_name Enemy
extends CharacterBody2D

enum EnemyType { GRUNT, RUSHER, TANK, SHOOTER, GRENADIER }

@export var move_speed: float = 40.0
@export var attack_damage: int = 5
@export var gold_value: int = 10
@export var contact_cooldown: float = 0.5
@export var enemy_type: EnemyType = EnemyType.GRUNT

# HP delegowane do HealthComponent (single source of truth).
var max_hp: int:
	get:
		return health_component.max_health if health_component else 30
	set(value):
		if health_component:
			health_component.set_max(value)

var hp: int:
	get:
		return health_component.current_health if health_component else 30
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
var _contact_timer: float = 0.0
var xp_value: int = 10
# Per-enemy phase offset so identical enemies don't sway in sync
var _anim_offset: float = 0.0

# Knockback — additive force (not velocity override, ref: brotato-clone-4)
var _knockback_dir: Vector2 = Vector2.ZERO
var _knockback_power: float = 0.0
var _knockback_timer: float = 0.0
const KNOCKBACK_FORCE: float = 120.0
const KNOCKBACK_DURATION: float = 0.25
# Death state — prevent double-die calls
var _is_dying: bool = false

# Attack wind-up state
var _attack_state: int = 0  # 0=chase, 1=windup, 2=cooldown
var _attack_timer: float = 0.0
const ATTACK_RANGE: float = 14.0
const WINDUP_TIME: float = 0.15
const ATTACK_PAUSE: float = 0.4

# Behavior — opcjonalny child node przejmujący sterowanie atakiem
# (ShootBehavior dla Shootera, GrenadeBehavior dla Grenadiera).
# Brak = default melee chase z _melee_behavior().
var attack_behavior: Node = null

# Sprite textures per type (null = use _draw() fallback)
var _sprite_textures: Dictionary = {
	EnemyType.GRUNT: preload("res://assets/sprites/enemies/Grunt.png"),
	EnemyType.RUSHER: preload("res://assets/sprites/enemies/Rusher.png"),
	EnemyType.TANK: preload("res://assets/sprites/enemies/Tank.png"),
	EnemyType.SHOOTER: preload("res://assets/sprites/enemies/Shooter.png"),
	EnemyType.GRENADIER: preload("res://assets/sprites/enemies/Grenadier.png"),
}
var _shadow_texture: Texture2D  # unused — shadow uses body texture now
var _has_sprite: bool = false
var _flash_mat: ShaderMaterial = null
const _FLASH_SHADER := preload("res://src/effects/flash.gdshader")
const _SHADOW_SHADER := preload("res://src/effects/shadow.gdshader")

const VISUAL_SCALE := 0.65

@onready var body_sprite: Sprite2D = $BodySprite
@onready var shadow_sprite: Sprite2D = $BodySprite/Shadow
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var vision_area: Area2D = $VisionArea
@onready var health_component: HealthComponent = $HealthComponent


func _ready() -> void:
	health_component.on_unit_died.connect(_die)
	health_component.setup(max_hp, true)
	add_to_group("enemies")
	_anim_offset = randf() * TAU  # random phase per instance
	_apply_visual()
	# Wykryj behavior pre-attached ze sceny (enemy_shooter.tscn, enemy_grenadier.tscn)
	attack_behavior = get_node_or_null("AttackBehavior")




func _draw() -> void:
	# Skip _draw() primitives if this type has a real sprite
	if _has_sprite:
		return
	var radius := 5.0
	var color := Color(0.9, 0.2, 0.2)  # red grunt
	match enemy_type:
		EnemyType.GRUNT:
			radius = 5.0
			color = Color(0.9, 0.2, 0.2)
		EnemyType.RUSHER:
			radius = 4.0
			color = Color(1.0, 0.6, 0.3)
		EnemyType.TANK:
			radius = 7.0
			color = Color(0.6, 0.3, 0.8)
		EnemyType.SHOOTER:
			radius = 5.0
			color = Color(0.2, 0.6, 0.9)
		EnemyType.GRENADIER:
			radius = 6.0
			color = Color(0.9, 0.8, 0.2)
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius + 1.5, 0, TAU, 32, Color.WHITE, 1.0)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color.darkened(0.3), 1.0)
	# Shooter crosshair indicator
	if enemy_type == EnemyType.SHOOTER:
		draw_line(Vector2(-3, 0), Vector2(3, 0), Color.WHITE, 1.0)
		draw_line(Vector2(0, -3), Vector2(0, 3), Color.WHITE, 1.0)
	# Grenadier warning ring
	if enemy_type == EnemyType.GRENADIER:
		draw_arc(Vector2.ZERO, 8.0, 0, TAU, 16, Color(1, 0.4, 0.1, 0.4), 1.0)


## Konfiguruj wariant wroga — wywoływane PO add_child (bo property setters
## dla max_hp/hp delegują do HealthComponent, a ten jest @onready).
func configure(type: EnemyType, wave: int) -> void:
	enemy_type = type
	var wave_mult := 1.0 + (wave - 1) * 0.15  # +15% stats per wave
	match type:
		EnemyType.GRUNT:
			max_hp = int(12 * wave_mult)
			move_speed = 40.0 + wave * 2.0
			attack_damage = int(5 * wave_mult)
			gold_value = 10 + wave * 2
			xp_value = 8
		EnemyType.RUSHER:
			max_hp = int(8 * wave_mult)
			move_speed = 75.0 + wave * 3.0
			attack_damage = int(3 * wave_mult)
			gold_value = 8 + wave * 2
			contact_cooldown = 0.3
			xp_value = 8
		EnemyType.TANK:
			max_hp = int(80 * wave_mult)
			move_speed = 20.0 + wave * 1.0
			attack_damage = int(10 * wave_mult)
			gold_value = 30 + wave * 5
			xp_value = 25
		EnemyType.SHOOTER:
			max_hp = int(20 * wave_mult)
			move_speed = 25.0 + wave * 1.0
			attack_damage = int(6 * wave_mult)
			gold_value = 18 + wave * 3
			xp_value = 15
			var sr: float = 120.0 + wave * 5.0
			if attack_behavior is ShootBehavior:
				# Pre-attached z enemy_shooter.tscn — tylko zaktualizuj parametry
				(attack_behavior as ShootBehavior).shoot_range = sr
			else:
				_attach_shoot_behavior(sr, 1.2)
		EnemyType.GRENADIER:
			max_hp = int(35 * wave_mult)
			move_speed = 22.0 + wave * 1.0
			attack_damage = int(12 * wave_mult)
			gold_value = 25 + wave * 4
			xp_value = 20
			var tr: float = 100.0 + wave * 5.0
			if attack_behavior is GrenadeBehavior:
				(attack_behavior as GrenadeBehavior).throw_range = tr
			else:
				_attach_grenade_behavior(tr, 2.5)
	# _ready() woła _apply_visual() z domyślnym enemy_type=GRUNT.
	# Tutaj mamy już właściwy typ — re-apply żeby sprite był poprawny.
	_apply_visual()
	# Sync HP z nowym max_hp ustawionym w match powyżej
	health_component.setup(max_hp, true)
	queue_redraw()


func _attach_shoot_behavior(shoot_range: float, cooldown: float) -> void:
	var b := ShootBehavior.new()
	b.name = "AttackBehavior"
	b.shoot_range = shoot_range
	b.cooldown_max = cooldown
	add_child(b)
	attack_behavior = b


func _attach_grenade_behavior(throw_range: float, cooldown: float) -> void:
	var b := GrenadeBehavior.new()
	b.name = "AttackBehavior"
	b.throw_range = throw_range
	b.cooldown_max = cooldown
	add_child(b)
	attack_behavior = b


func _apply_visual() -> void:
	# Load sprite texture if available for this type
	if _sprite_textures.has(enemy_type):
		var tex: Texture2D = _sprite_textures[enemy_type]
		body_sprite.texture = tex
		body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		body_sprite.scale = Vector2(VISUAL_SCALE, VISUAL_SCALE)
		body_sprite.visible = true
		_has_sprite = true
		# Flash shader — nie rusza modulate, nie koliduje z innymi efektami
		_flash_mat = ShaderMaterial.new()
		_flash_mat.shader = _FLASH_SHADER
		body_sprite.material = _flash_mat
		# Shadow = czarna sylwetka sprite'a (shader usuwa kolory, zostaje tylko kształt)
		shadow_sprite.texture = tex
		shadow_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var shadow_mat := ShaderMaterial.new()
		shadow_mat.shader = _SHADOW_SHADER
		shadow_mat.set_shader_parameter("shadow_alpha", 0.38)
		shadow_sprite.material = shadow_mat
		# Transform2D: spłaszcza sylwetkę w Y + skos w prawo → wygląda jak cień na podłodze
		# Shadow jest dzieckiem BodySprite — local space bez VISUAL_SCALE, stopy na tex_h/2
		shadow_sprite.texture = tex
		shadow_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		shadow_sprite.scale = Vector2.ONE  # parent (BodySprite) już ma VISUAL_SCALE
		shadow_sprite.modulate = Color.WHITE
		if shadow_sprite.material == null:
			var mat := ShaderMaterial.new()
			mat.shader = _SHADOW_SHADER
			mat.set_shader_parameter("look_right", true)
			mat.set_shader_parameter("shadow_alpha", 0.5)
			mat.set_shader_parameter("skew_strength", 0.4)
			shadow_sprite.material = mat
		shadow_sprite.visible = true
	else:
		body_sprite.visible = false
		shadow_sprite.visible = false

	match enemy_type:
		EnemyType.RUSHER:
			var shape: CircleShape2D = collision_shape.shape
			shape.radius = 4.0
		EnemyType.TANK:
			var shape: CircleShape2D = collision_shape.shape
			shape.radius = 7.0
		EnemyType.GRENADIER:
			var shape: CircleShape2D = collision_shape.shape
			shape.radius = 6.0
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _is_dying:
		return
	# Knockback decays over time (additive, not override)
	if _knockback_timer > 0.0:
		_knockback_timer -= delta
		_knockback_power = lerpf(_knockback_power, 0.0, 8.0 * delta)
	else:
		_knockback_power = 0.0
		_knockback_dir = Vector2.ZERO

	_find_target()
	if not is_instance_valid(target):
		return

	# Sprite direction + movement wobble
	if _has_sprite:
		body_sprite.flip_h = target.global_position.x < global_position.x
		if shadow_sprite.material is ShaderMaterial:
			(shadow_sprite.material as ShaderMaterial).set_shader_parameter("look_right", not body_sprite.flip_h)
		if velocity.length() > 5.0:
			body_sprite.rotation = sin(Time.get_ticks_msec() * 0.01 + _anim_offset) * 0.08
		else:
			body_sprite.rotation = lerpf(body_sprite.rotation, 0.0, 10.0 * delta)

	var dist_to_target := global_position.distance_to(target.global_position)
	var direction := (target.global_position - global_position).normalized()
	var separation := _get_separation_force()
	# Knockback added to every velocity (additive, not override — ref: brotato-clone-4)
	var knockback := _knockback_dir * _knockback_power

	# Behavior composition — opcjonalny child node przejmuje sterowanie
	# (ShootBehavior, GrenadeBehavior). Brak behavior = default melee chase.
	var handled := false
	if attack_behavior and attack_behavior.has_method("process_attack"):
		handled = attack_behavior.process_attack(direction, dist_to_target, separation, knockback, delta)
	if not handled:
		_melee_behavior(delta, direction, separation + knockback, dist_to_target)


## Soft-collision separation using VisionArea (O(n) local, not O(n²) global)
## ref: brotato-clone-4 enemy.gd — vision_area.get_overlapping_areas()
## Scaling: gdy jest tłum, siła rośnie kwadratowo żeby utrzymać >= 18px nawet przy 40+ wrogach.
func _get_separation_force() -> Vector2:
	const SEPARATION_RADIUS := 18.0
	const SEPARATION_BASE_STRENGTH := 180.0   # baseline (było 120, za słabe)
	var force := Vector2.ZERO
	var neighbor_count: int = 0
	for area in vision_area.get_overlapping_areas():
		var other := area.owner
		if not is_instance_valid(other) or other == self:
			continue
		var diff: Vector2 = global_position - other.global_position
		var dist: float = diff.length()
		if dist < SEPARATION_RADIUS and dist > 0.01:
			# Im więcej sąsiadów blisko, tym silniejsze pchnięcie od KAŻDEGO
			# (kompensuje "tłok" gdy wielu wrogów ciśnie z każdej strony)
			neighbor_count += 1
			# Quadratic falloff: 1x przy 18px, 4x przy 9px (skok blisko)
			var t: float = 1.0 - (dist / SEPARATION_RADIUS)
			var falloff: float = t * t * 2.0 + t  # kwadratowo + liniowo
			force += diff.normalized() * falloff * SEPARATION_BASE_STRENGTH
	# Bonus przy ścisku — gdy >= 4 sąsiadów, dodatkowy +30% siły
	if neighbor_count >= 4:
		force *= 1.0 + (neighbor_count - 3) * 0.1
	return force


func take_damage(amount: int) -> void:
	if not health_component.is_alive():
		return
	# HP delegowane do komponentu — on_unit_died sygnał wywoła _die() automatycznie
	health_component.take_damage(amount)
	_spawn_damage_number(amount)
	_flash_hit()


func _flash_hit() -> void:
	if _flash_mat:
		# Shader flash — żółty, nie rusza modulate (nie koliduje z i-frames)
		_flash_mat.set_shader_parameter("flash_color", Vector4(1.0, 1.0, 0.15, 1.0))
		_flash_mat.set_shader_parameter("flash_amount", 1.0)
		var tween := create_tween()
		tween.tween_method(
			func(v: float): _flash_mat.set_shader_parameter("flash_amount", v),
			1.0, 0.0, 0.15
		)
	else:
		# Fallback dla _draw()-only enemies (brak sprite'a)
		modulate = Color(1.0, 1.0, 0.2)
		var tween := create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	# Scale punch — zawsze wracaj do VISUAL_SCALE (nie do bieżącej skali, która mogła być już powiększona)
	if _has_sprite and body_sprite:
		var base_scale := Vector2(VISUAL_SCALE, VISUAL_SCALE)
		body_sprite.scale = base_scale * 1.3
		var punch_tween := create_tween()
		punch_tween.tween_property(body_sprite, "scale", base_scale, 0.12).set_ease(Tween.EASE_OUT)


func _spawn_damage_number(amount: int) -> void:
	if not SettingsManager.damage_numbers_enabled:
		return
	var dn := preload("res://src/systems/damage_number.gd").new()
	dn.value = amount
	dn.global_position = global_position + Vector2(0, -8)
	get_tree().current_scene.add_child(dn)


func _die() -> void:
	if _is_dying:
		return
	_is_dying = true
	# Disable collision immediately so other enemies don't react to corpse
	collision_shape.set_deferred("disabled", true)
	EventBus.enemy_killed.emit(self, global_position)
	EventBus.enemy_killed_at.emit(global_position)
	EventBus.loot_dropped.emit(global_position, gold_value)
	GameManager.add_xp(xp_value)
	var death_fx := ParticleFactory.create_death_puff(global_position)
	get_tree().current_scene.add_child(death_fx)
	_play_death_animation()


func _play_death_animation() -> void:
	# Flash white then shrink to zero before freeing
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.05)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(queue_free)


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


## Melee AI: chase → wind-up → hit + knockback → cooldown → chase
func _melee_behavior(delta: float, direction: Vector2, separation: Vector2, dist: float) -> void:
	match _attack_state:
		0:  # CHASE
			velocity = direction * move_speed + separation
			move_and_slide()
			if dist < ATTACK_RANGE:
				_attack_state = 1
				_attack_timer = WINDUP_TIME
				velocity = Vector2.ZERO
		1:  # WIND-UP (stop, prepare to strike)
			velocity = separation * 0.3
			move_and_slide()
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_do_contact_attack()
				_attack_state = 2
				_attack_timer = ATTACK_PAUSE
		2:  # COOLDOWN (wait before chasing again)
			velocity = separation * 0.5
			move_and_slide()
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_attack_state = 0


func _do_contact_attack() -> void:
	if not is_instance_valid(target):
		return
	var dist := global_position.distance_to(target.global_position)
	if dist < ATTACK_RANGE + 6.0 and target is Soldier:
		target.take_damage(attack_damage)
		# Knockback self away from target (additive)
		var kb_dir := (global_position - target.global_position).normalized()
		_apply_knockback(kb_dir, KNOCKBACK_FORCE)


func _apply_knockback(dir: Vector2, force: float) -> void:
	_knockback_dir = dir
	_knockback_power = force
	_knockback_timer = KNOCKBACK_DURATION


# NOTE: _shoot_at_target / _throw_grenade / _EnemyGrenade przeniesione do
# behaviors/shoot_behavior.gd i behaviors/grenade_behavior.gd
