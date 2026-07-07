## ParticleFactory — factory for one-shot CPUParticles2D effects
class_name ParticleFactory
extends RefCounted


static func create_muzzle_flash(pos: Vector2, direction: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.amount = 6
	p.lifetime = 0.12
	p.explosiveness = 1.0
	p.global_position = pos
	p.direction = Vector2(direction.x, direction.y)
	p.spread = 25.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 80.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = Color(1.0, 0.9, 0.3, 0.9)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.85, 0.2, 1.0))
	gradient.set_color(1, Color(1.0, 0.4, 0.1, 0.0))
	p.color_ramp = gradient
	p.finished.connect(p.queue_free)
	return p


static func create_bullet_trail(pos: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.amount = 3
	p.lifetime = 0.15
	p.explosiveness = 0.8
	p.global_position = pos
	p.direction = Vector2.ZERO
	p.spread = 180.0
	p.initial_velocity_min = 5.0
	p.initial_velocity_max = 15.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.5
	p.color = Color(1.0, 0.95, 0.5, 0.5)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.95, 0.5, 0.4))
	gradient.set_color(1, Color(1.0, 0.8, 0.3, 0.0))
	p.color_ramp = gradient
	p.finished.connect(p.queue_free)
	return p


static func create_hit_sparks(pos: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.amount = 8
	p.lifetime = 0.2
	p.explosiveness = 1.0
	p.global_position = pos
	p.direction = Vector2.ZERO
	p.spread = 180.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 60.0
	p.gravity = Vector2(0, 40)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(1.0, 0.7, 0.2)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.8, 0.3, 1.0))
	gradient.set_color(1, Color(0.8, 0.3, 0.1, 0.0))
	p.color_ramp = gradient
	p.finished.connect(p.queue_free)
	return p


static func create_explosion(pos: Vector2, radius: float = 40.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.amount = 16
	p.lifetime = 0.35
	p.explosiveness = 0.9
	p.global_position = pos
	p.direction = Vector2.ZERO
	p.spread = 180.0
	p.initial_velocity_min = radius * 0.5
	p.initial_velocity_max = radius * 1.2
	p.gravity = Vector2(0, 20)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	p.color = Color(1.0, 0.6, 0.1)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.9, 0.3, 1.0))
	gradient.add_point(0.3, Color(1.0, 0.4, 0.1, 0.8))
	gradient.set_color(1, Color(0.3, 0.1, 0.1, 0.0))
	p.color_ramp = gradient
	p.finished.connect(p.queue_free)
	return p


static func create_death_puff(pos: Vector2, color: Color = Color(0.6, 0.1, 0.1)) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.amount = 10
	p.lifetime = 0.3
	p.explosiveness = 0.9
	p.global_position = pos
	p.direction = Vector2.ZERO
	p.spread = 180.0
	p.initial_velocity_min = 15.0
	p.initial_velocity_max = 40.0
	p.gravity = Vector2(0, -10)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color = color
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 0.9))
	gradient.set_color(1, Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, 0.0))
	p.color_ramp = gradient
	p.finished.connect(p.queue_free)
	return p


static func create_loot_sparkle(pos: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.amount = 5
	p.lifetime = 0.4
	p.explosiveness = 0.7
	p.global_position = pos
	p.direction = Vector2(0, -1)
	p.spread = 40.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 50.0
	p.gravity = Vector2(0, -20)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(1.0, 0.85, 0.2)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 0.5, 1.0))
	gradient.set_color(1, Color(1.0, 0.85, 0.2, 0.0))
	p.color_ramp = gradient
	p.finished.connect(p.queue_free)
	return p
