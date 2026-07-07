## CrateDrop — rzadka skrzynka z nagrodą (drop z bossów/elitarnych wrogów)
class_name CrateDrop
extends Area2D

var wave: int = 1
var _collected: bool = false
var _bob_time: float = 0.0
var _has_sprite: bool = false
var _crate_sprite: Sprite2D = null

var _crate_texture: Texture2D = preload("res://assets/sprites/loot/crate.png")


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # squad layer
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	# Crate sprite
	if _crate_texture:
		_crate_sprite = Sprite2D.new()
		_crate_sprite.texture = _crate_texture
		_crate_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_crate_sprite.scale = Vector2(0.1, 0.1)  # 10/200 * 2× for visibility
		add_child(_crate_sprite)
		_has_sprite = true
	# Auto-despawn after 15 seconds
	var timer := get_tree().create_timer(15.0)
	timer.timeout.connect(queue_free)
	EventBus.crate_dropped.emit(global_position)


func _draw() -> void:
	# Outer glow (keep even with sprite)
	draw_circle(Vector2.ZERO, 10.0, Color(1.0, 0.85, 0.2, 0.25 + 0.15 * sin(_bob_time * 3.0)))
	if not _has_sprite:
		# Crate body fallback
		draw_rect(Rect2(-6, -5, 12, 10), Color(0.6, 0.4, 0.15))
		# Crate lid
		draw_rect(Rect2(-7, -7, 14, 3), Color(0.5, 0.35, 0.1))
		# Lock/clasp
		draw_rect(Rect2(-1.5, -5, 3, 3), Color(1.0, 0.85, 0.3))
	# Sparkle (keep even with sprite)
	var spark_alpha: float = 0.5 + 0.5 * sin(_bob_time * 5.0)
	draw_circle(Vector2(0, -9), 1.5, Color(1.0, 1.0, 0.7, spark_alpha))


func _physics_process(delta: float) -> void:
	_bob_time += delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body.is_in_group("squad"):
		_collected = true
		var sparkle := ParticleFactory.create_loot_sparkle(global_position)
		get_tree().current_scene.add_child(sparkle)
		_grant_reward()
		queue_free()


func _grant_reward() -> void:
	var roll: float = randf()
	if roll < 0.35:
		# Bonus gold (50-150 scaled by wave)
		var gold_amount: int = 50 + wave * 20 + randi() % 50
		GameManager.gold += gold_amount
		EventBus.crate_reward.emit("+$%d" % gold_amount, global_position)
	elif roll < 0.65:
		# Random passive item
		var all_items := PassiveItem.get_all_items()
		all_items.shuffle()
		if GameManager.get_passive_count() < GameManager.get_max_passive_slots():
			var item: PassiveItem = all_items[0]
			GameManager.add_passive(item)
			EventBus.crate_reward.emit(item.item_name, global_position)
		else:
			# Slots full — give gold instead
			var gold_amount: int = 80 + wave * 15
			GameManager.gold += gold_amount
			EventBus.crate_reward.emit("+$%d (pełne sloty)" % gold_amount, global_position)
	else:
		# Tiered weapon upgrade — upgrade a random soldier's weapon
		var tier: WeaponData.Tier = WeaponData.get_random_tier_for_wave(wave)
		# Ensure at least UNCOMMON from crate
		if tier == WeaponData.Tier.COMMON:
			tier = WeaponData.Tier.UNCOMMON
		var soldiers := get_tree().get_nodes_in_group("squad")
		if soldiers.size() > 0:
			var soldier: Soldier = soldiers[randi() % soldiers.size()]
			var new_weapon := WeaponData.create_tiered(soldier.weapon.type, tier)
			soldier.set_weapon(new_weapon)
			GameManager._apply_passives_to_soldier(soldier)
			var tier_name: String = WeaponData.TIER_NAMES[tier]
			EventBus.crate_reward.emit("%s T%s" % [new_weapon.weapon_name.split(" T")[0], tier_name], global_position)
		else:
			var gold_amount: int = 100
			GameManager.gold += gold_amount
			EventBus.crate_reward.emit("+$%d" % gold_amount, global_position)
