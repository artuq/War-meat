## WaveData — konfiguracja zakresu fal (Brotato-style data-driven)
## Designer edytuje .tres w inspektorze, programista nie musi nic pisać.
## Ref: brotato-clone/resources/waves/wave_data.gd
class_name WaveData
extends Resource

@export var from_wave: int = 1
@export var to_wave: int = 5

@export_group("Timing")
@export var wave_duration: float = 30.0  ## sekundy bazowe (wave == from_wave)
@export var wave_duration_increase_per_wave: float = 5.0  ## +sek za każdą falę powyżej from_wave
@export var initial_spawn_interval: float = 0.5
@export var min_spawn_interval: float = 0.15
@export var spawn_acceleration: float = 0.03  ## interval -= acc * delta * 10

@export_group("Enemies")
@export var units: Array[WaveUnitData] = []

@export_group("Scaling")
@export_range(0.0, 1.0, 0.01) var enemy_hp_increase_per_wave: float = 0.15
@export_range(0.0, 1.0, 0.01) var enemy_damage_increase_per_wave: float = 0.10

@export_group("Boss")
@export var spawn_boss_on_last_wave: bool = true


func is_valid_for_wave(wave: int) -> bool:
	return wave >= from_wave and wave <= to_wave


## Losuje typ wroga zgodnie z weights, respektując min_wave per unit
func pick_enemy_type(wave: int, rng: RandomNumberGenerator = null) -> int:
	var available: Array[WaveUnitData] = []
	var weights: Array[float] = []
	for unit in units:
		if unit and wave >= unit.min_wave and unit.weight > 0.0:
			available.append(unit)
			weights.append(unit.weight)
	if available.is_empty():
		return 0  # fallback Grunt
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var idx: int = rng.rand_weighted(weights)
	return available[idx].enemy_type


func get_wave_duration(wave: int) -> float:
	return wave_duration + maxi(wave - from_wave, 0) * wave_duration_increase_per_wave
