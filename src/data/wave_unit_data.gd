## WaveUnitData — pojedynczy wpis spawn pool: typ wroga + waga losowania
## Edytowalne w inspektorze. Brotato-clone ref: resources/waves/wave_unit_data.gd
class_name WaveUnitData
extends Resource

@export_enum("Grunt", "Rusher", "Tank", "Shooter", "Grenadier") var enemy_type: int = 0
@export_range(0.0, 100.0, 0.1) var weight: float = 1.0
@export_range(1, 50) var min_wave: int = 1  ## od którego wave zaczyna się pojawiać
