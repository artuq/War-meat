## LootDrop — loot upuszczony przez wroga (złoto)
class_name LootDrop
extends Area2D

# Coin magnet — Brotato/Survivor.io standard: coins lecą do gracza w promieniu MAGNET_RADIUS
const MAGNET_RADIUS: float = 120.0      # px — gdy soldier bliżej, coin go ścigaja
const MAGNET_SPEED: float = 320.0       # px/s przy maksymalnym przyciąganiu

var value: int = 10
var _can_pickup: bool = false
var _bob_time: float = 0.0
var _has_sprite: bool = false

# Top-down scatter: XY slide with friction, sprite Y animates the visual bounce.
var _slide_vel: Vector2 = Vector2.ZERO
var _bounce_y: float = 0.0    # sprite Y offset — visual only, node doesn't move vertically
var _bounce_vy: float = -55.0 # initial upward visual spring

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("loot")
	body_entered.connect(_on_body_entered)
	# Scatter in a random XY direction — no Y gravity (this is top-down)
	var angle := randf_range(0.0, TAU)
	_slide_vel = Vector2(cos(angle), sin(angle)) * randf_range(25.0, 55.0)
	get_tree().create_timer(0.45).timeout.connect(func(): _can_pickup = true)
	_bob_time = randf() * TAU
	_has_sprite = sprite.texture != null


func _process(delta: float) -> void:
	# Coin magnet — leć do najbliższego soldiera w promieniu MAGNET_RADIUS
	if _can_pickup:
		var nearest := _nearest_soldier()
		if nearest:
			var to_soldier: Vector2 = nearest.global_position - global_position
			var dist: float = to_soldier.length()
			if dist < MAGNET_RADIUS and dist > 0.1:
				# Im bliżej, tym silniejsze ciągnięcie (smooth approach)
				var pull_strength: float = 1.0 - (dist / MAGNET_RADIUS) * 0.5  # 0.5-1.0
				position += to_soldier.normalized() * MAGNET_SPEED * pull_strength * delta
				# Pickup gdy bardzo blisko (mniejszy threshold niż collision radius)
				if dist < 14.0:
					_pickup(nearest)
					return

	# Ground slide — friction stops it quickly
	_slide_vel = _slide_vel.lerp(Vector2.ZERO, 7.0 * delta)
	position += _slide_vel * delta

	# Visual bounce on sprite only (not node position)
	if _bounce_y < 0.0 or _bounce_vy < 0.0:
		_bounce_vy += 200.0 * delta
		_bounce_y = minf(_bounce_y + _bounce_vy * delta, 0.0)
		if _bounce_y >= 0.0:
			_bounce_vy = 0.0
			_bounce_y = 0.0
		sprite.position.y = _bounce_y
		return

	# Idle bob after landing
	_bob_time += delta * 3.0
	if _has_sprite:
		var pulse: float = 1.0 + sin(_bob_time * 2.0) * 0.08
		sprite.scale = Vector2(0.22, 0.22) * pulse
		sprite.position.y = sin(_bob_time) * 1.2


func _draw() -> void:
	if _has_sprite:
		return
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.85, 0.1))
	draw_arc(Vector2.ZERO, 3.0, 0, TAU, 24, Color(0.8, 0.65, 0.0), 1.0)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("squad") and _can_pickup:
		_pickup(body)


func _pickup(_body: Node2D) -> void:
	EventBus.loot_collected.emit(value)
	queue_free()


func _nearest_soldier() -> Node2D:
	var best: Node2D = null
	var best_dist: float = INF
	for s in get_tree().get_nodes_in_group("squad"):
		if not is_instance_valid(s):
			continue
		var d: float = global_position.distance_to(s.global_position)
		if d < best_dist:
			best_dist = d
			best = s
	return best
