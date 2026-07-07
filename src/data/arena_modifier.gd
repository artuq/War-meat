## ArenaModifier — konfiguracja tematycznej areny
class_name ArenaModifier
extends Resource

@export var arena_id: String = ""
@export var arena_name: String = ""
@export var description: String = ""
@export var difficulty: int = 1  ## 1=easy, 2=medium, 3=hard

## Arena visuals
@export var floor_color: Color = Color(0.55, 0.55, 0.50)
@export var debris_colors: Array[Color] = []
@export var wall_color: Color = Color(0.3, 0.3, 0.3)
@export var arena_size: Vector2 = Vector2(2500, 1500)
@export var debris_count: int = 300

## Wave modifiers
@export var spawn_rate_mult: float = 1.0  ## multiplier on spawn interval (lower = more enemies)
@export var wave_duration_mult: float = 1.0  ## multiplier on wave time

## DEPRECATED — enemy pool weights moved to WaveData (.tres). Te pola są ignorowane
## przez wave_manager. Per-arena distribution można dodać przez osobny WaveData.tres.
@export var grunt_weight: float = 0.55
@export var rusher_weight: float = 0.30
@export var tank_weight: float = 0.15

## Enemy stat modifiers
@export var enemy_speed_mult: float = 1.0
@export var enemy_range_mult: float = 1.0
@export var enemy_hp_mult: float = 1.0

## Player modifiers
@export var player_speed_mult: float = 1.0

## Hazards
@export var has_exploding_barrels: bool = false
@export var barrel_count: int = 0


static func create_jungle() -> ArenaModifier:
	var m := ArenaModifier.new()
	m.arena_id = "jungle"
	m.arena_name = "Dżungla"
	m.description = "Gęste zarośla, szybcy wrogowie"
	m.difficulty = 1
	m.floor_color = Color(0.28, 0.38, 0.22)
	m.debris_colors = [
		Color(0.22, 0.32, 0.18),
		Color(0.30, 0.40, 0.24),
		Color(0.25, 0.35, 0.20),
		Color(0.35, 0.42, 0.28),
	]
	m.wall_color = Color(0.18, 0.26, 0.14)
	m.debris_count = 450
	m.spawn_rate_mult = 0.8  # 20% more enemies
	m.grunt_weight = 0.30
	m.rusher_weight = 0.55  # Rusher dominated
	m.tank_weight = 0.15
	return m


static func create_desert() -> ArenaModifier:
	var m := ArenaModifier.new()
	m.arena_id = "desert"
	m.arena_name = "Pustynia"
	m.description = "Otwarta przestrzeń, wrogowie z daleka"
	m.difficulty = 2
	m.floor_color = Color(0.72, 0.62, 0.42)
	m.debris_colors = [
		Color(0.65, 0.55, 0.38),
		Color(0.70, 0.60, 0.44),
		Color(0.60, 0.52, 0.36),
		Color(0.75, 0.65, 0.48),
	]
	m.wall_color = Color(0.50, 0.42, 0.30)
	m.debris_count = 120  # open space
	m.enemy_range_mult = 1.15  # +15% range
	m.player_speed_mult = 0.9  # sand slows player
	m.enemy_hp_mult = 1.1
	return m


static func create_bunker() -> ArenaModifier:
	var m := ArenaModifier.new()
	m.arena_id = "bunker"
	m.arena_name = "Bunkier"
	m.description = "Ciasne korytarze, wybuchające beczki"
	m.difficulty = 3
	m.floor_color = Color(0.35, 0.35, 0.38)
	m.debris_colors = [
		Color(0.30, 0.30, 0.33),
		Color(0.38, 0.38, 0.40),
		Color(0.28, 0.28, 0.32),
		Color(0.42, 0.40, 0.44),
	]
	m.wall_color = Color(0.22, 0.22, 0.25)
	m.arena_size = Vector2(2000, 1200)  # smaller
	m.debris_count = 200
	m.grunt_weight = 0.35
	m.rusher_weight = 0.20
	m.tank_weight = 0.45  # heavy enemy dominated
	m.enemy_hp_mult = 1.25
	m.has_exploding_barrels = true
	m.barrel_count = 12
	return m
