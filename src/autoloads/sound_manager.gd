## SoundManager — globalny system audio (muzyka + SFX pooling)
extends Node

@export var library: AudioLibrary = preload("res://src/data/audio_library.tres")

# --- Music players ---
var _music_player: AudioStreamPlayer = null
var _music_intense: AudioStreamPlayer = null
var _current_music_path: String = ""
var _current_intense_path: String = ""
var _music_tween: Tween = null
var _intense_tween: Tween = null
var _bus_tween: Tween = null
var _shop_ducked: bool = false
var _stinger_player: AudioStreamPlayer = null

# --- SFX pool ---
const SFX_POOL_SIZE: int = 16
var _sfx_pool: Array[AudioStreamPlayer2D] = []
var _sfx_pool_idx: int = 0

# --- Non-positional SFX ---
const SFX_GLOBAL_POOL_SIZE: int = 4
var _sfx_global_pool: Array[AudioStreamPlayer] = []
var _sfx_global_idx: int = 0

# --- Weapon SFX variants ---
var _weapon_variants: Dictionary = {
	"rifle": [
		preload("res://assets/audio/sfx/weapons/rifle_01.wav"),
		preload("res://assets/audio/sfx/weapons/rifle_02.wav"),
		preload("res://assets/audio/sfx/weapons/rifle_03.wav"),
	],
	"shotgun": [
		load("res://assets/audio/sfx/weapons/shotgun_01.wav"),
		load("res://assets/audio/sfx/weapons/shotgun_02.wav"),
	],
	"pistol": [
		load("res://assets/audio/sfx/weapons/pistol_01.wav"),
		load("res://assets/audio/sfx/weapons/pistol_02.wav"),
	],
	"smg": [
		load("res://assets/audio/sfx/weapons/smg_01.wav"),
		load("res://assets/audio/sfx/weapons/smg_02.wav"),
	],
	"sniper": [
		load("res://assets/audio/sfx/weapons/sniper_01.wav"),
	],
	"melee": [
		load("res://assets/audio/sfx/weapons/melee_01.wav"),
		load("res://assets/audio/sfx/weapons/melee_02.wav"),
	],
	"grenade": [
		load("res://assets/audio/sfx/weapons/grenade_01.wav"),
		load("res://assets/audio/sfx/weapons/grenade_02.wav"),
	],
}

# --- UI SFX ---
var _ui_sfx: Dictionary = {
	"shop_buy":     load("res://assets/audio/sfx/ui/shop_buy.wav"),
	"shop_reroll":  load("res://assets/audio/sfx/ui/shop_reroll.wav"),
	"level_up":     load("res://assets/audio/sfx/ui/level_up.wav"),
	"upgrade_pick": load("res://assets/audio/sfx/ui/upgrade_pick.wav"),
	"wave_start":   load("res://assets/audio/sfx/ui/wave_start.wav"),
	"wave_complete":load("res://assets/audio/sfx/ui/wave_complete.wav"),
}

# --- Enemy SFX ---
var _enemy_sfx: Dictionary = {
	"enemy_death":  load("res://assets/audio/sfx/enemies/enemy_death.wav"),
	"enemy_hit":    load("res://assets/audio/sfx/enemies/enemy_hit.wav"),
	"boss_roar":    load("res://assets/audio/sfx/enemies/boss_roar.wav"),
	"boss_death":   load("res://assets/audio/sfx/enemies/boss_death.wav"),
	"boss_appear":  load("res://assets/audio/sfx/enemies/boss_appear.wav"),
}

# --- Music tracks ---
var _music_tracks: Dictionary = {
	"menu": preload("res://assets/audio/music/menu/menu_theme.mp3"),
	"hub": preload("res://assets/audio/music/hub_theme.mp3"),
	"jungle_base": preload("res://assets/audio/music/arena_jungle/jungle_base.mp3"),
	"jungle_intense": preload("res://assets/audio/music/arena_jungle/jungle_intense.mp3"),
	"victory": preload("res://assets/audio/music/victory_stinger.mp3"),
}

# Voice limiting per category
var _voice_counts: Dictionary = {}
const MAX_VOICES: Dictionary = {
	"weapon": 3,
	"impact": 8,
}

# Per-category cooldown to prevent same-frame phasing
var _category_cooldowns: Dictionary = {}
const CATEGORY_COOLDOWN_MS: Dictionary = {
	"weapon": 40,  # minimum 40ms between weapon SFX
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Music players
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.volume_db = -6.0
	add_child(_music_player)

	_music_intense = AudioStreamPlayer.new()
	_music_intense.bus = "Music"
	_music_intense.volume_db = -40.0  # starts silent
	add_child(_music_intense)

	# SFX 2D pool (positional)
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer2D.new()
		player.bus = "SFX"
		player.max_distance = 500.0
		add_child(player)
		_sfx_pool.append(player)

	# SFX global pool (non-positional)
	for i in SFX_GLOBAL_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_global_pool.append(player)

	# Dedicated stinger player — Music bus so it's never muted by duck_for_shop
	_stinger_player = AudioStreamPlayer.new()
	_stinger_player.bus = "Music"
	add_child(_stinger_player)


# --- MUSIC ---

func _kill_music_tweens() -> void:
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	if _intense_tween and _intense_tween.is_valid():
		_intense_tween.kill()
	_music_tween = null
	_intense_tween = null


func play_music(track_name: String, fade_in: float = 1.0) -> void:
	if track_name == _current_music_path:
		return
	_current_music_path = track_name
	_current_intense_path = ""

	if not _music_tracks.has(track_name):
		stop_music()
		return

	_kill_music_tweens()
	var stream: AudioStream = _music_tracks[track_name]
	if _music_player.playing:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -40.0, 0.5)
		_music_tween.tween_callback(func():
			_music_player.stream = stream
			_music_player.volume_db = -40.0
			_music_player.play()
			_music_tween = create_tween()
			_music_tween.tween_property(_music_player, "volume_db", -6.0, fade_in)
		)
	else:
		_music_player.stream = stream
		_music_player.volume_db = -40.0
		_music_player.play()
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -6.0, fade_in)

	# Stop intense layer
	if _intense_tween and _intense_tween.is_valid():
		_intense_tween.kill()
	_music_intense.stop()
	_music_intense.volume_db = -40.0


func play_music_layered(base_name: String, intense_name: String, fade_in: float = 1.0) -> void:
	if base_name == _current_music_path and intense_name == _current_intense_path:
		return
	_current_music_path = base_name
	_current_intense_path = intense_name
	_kill_music_tweens()

	if _music_tracks.has(base_name):
		_music_player.stream = _music_tracks[base_name]
		_music_player.volume_db = -40.0
		_music_player.play()
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -6.0, fade_in)

	if _music_tracks.has(intense_name):
		_music_intense.stream = _music_tracks[intense_name]
		_music_intense.volume_db = -40.0
		_music_intense.play()


func set_music_intensity(intensity: float) -> void:
	if _current_intense_path == "":
		return
	# Base volume: -6 at 0 intensity → -20 at 1.0
	_music_player.volume_db = lerpf(-6.0, -20.0, intensity)
	# Intense volume: -40 at 0 intensity → -6 at 1.0
	_music_intense.volume_db = lerpf(-40.0, -6.0, intensity)


func stop_music(fade_out: float = 0.5) -> void:
	_current_music_path = ""
	_current_intense_path = ""
	_kill_music_tweens()
	if _music_player.playing:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -40.0, fade_out)
		_music_tween.tween_callback(_music_player.stop)
	if _music_intense.playing:
		_intense_tween = create_tween()
		_intense_tween.tween_property(_music_intense, "volume_db", -40.0, fade_out)
		_intense_tween.tween_callback(_music_intense.stop)


func play_stinger(track_name: String) -> void:
	if not _music_tracks.has(track_name):
		return
	if _stinger_player.playing:
		_stinger_player.stop()
	_stinger_player.stream = _music_tracks[track_name]
	_stinger_player.volume_db = -3.0
	_stinger_player.pitch_scale = 1.0
	_stinger_player.play()


# --- SFX ---

func play_weapon_sfx(weapon_type: String, pos: Vector2, pitch_variance: float = 0.15) -> void:
	if not _weapon_variants.has(weapon_type):
		return
	# Voice limiting
	var count: int = _voice_counts.get("weapon", 0)
	if count >= MAX_VOICES.get("weapon", 3):
		return
	# Per-category cooldown — prevent same-frame phasing
	var now_ms: int = Time.get_ticks_msec()
	var last_ms: int = _category_cooldowns.get("weapon", 0)
	var cd: int = CATEGORY_COOLDOWN_MS.get("weapon", 40)
	if now_ms - last_ms < cd:
		return
	_category_cooldowns["weapon"] = now_ms
	_voice_counts["weapon"] = count + 1

	var variants: Array = _weapon_variants[weapon_type]
	var stream: AudioStream = variants[randi() % variants.size()]
	var player := _get_pooled_player()
	player.stream = stream
	player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	player.global_position = pos
	player.volume_db = -8.0
	player.play()
	player.finished.connect(func(): _voice_counts["weapon"] = maxi(_voice_counts.get("weapon", 1) - 1, 0), CONNECT_ONE_SHOT)


func play_sfx_2d(stream: AudioStream, pos: Vector2, volume_db: float = 0.0, pitch_variance: float = 0.05) -> void:
	var player := _get_pooled_player()
	player.stream = stream
	player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	player.global_position = pos
	player.volume_db = volume_db
	player.play()


# --- WAVE TRANSITIONS ---

func _kill_bus_tween() -> void:
	if _bus_tween and _bus_tween.is_valid():
		_bus_tween.kill()
	_bus_tween = null


## Duck music & clear SFX pool when entering shop
func duck_for_shop(fade_time: float = 0.5) -> void:
	# Kill any in-flight player-level music tweens too
	_kill_music_tweens()
	_kill_bus_tween()
	# Stop cutscene audio if still running
	if _cutscene_music_player and _cutscene_music_player.playing:
		_cutscene_music_player.stop()
	# Immediately mute SFX bus to kill any in-flight sounds
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_mute(sfx_bus, true)
	for player in _sfx_pool:
		if player.playing:
			player.stop()
	for player in _sfx_global_pool:
		if player.playing:
			player.stop()
	_voice_counts.clear()
	# Snap music player volume back to nominal (remove any cutscene ducking)
	if _music_player:
		_music_player.volume_db = -6.0
	if _music_intense:
		_music_intense.volume_db = -40.0
	# Duck music bus to -20 dB
	var bus_idx := AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		_bus_tween = create_tween()
		_bus_tween.tween_method(func(db: float): AudioServer.set_bus_volume_db(bus_idx, db),
			AudioServer.get_bus_volume_db(bus_idx), -20.0, fade_time)
	_shop_ducked = true


## Restore music bus when returning to arena — no-op if duck_for_shop was never called
func resume_from_shop(fade_time: float = 0.8) -> void:
	if not _shop_ducked:
		return
	_shop_ducked = false
	_kill_bus_tween()
	# Restore SFX bus to user settings
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		if SettingsManager.sfx_volume > 0.01:
			AudioServer.set_bus_mute(sfx_bus, false)
			AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(SettingsManager.sfx_volume))
	# Fade music bus back to user's preferred volume
	var bus_idx := AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		var target_db: float = linear_to_db(maxf(SettingsManager.music_volume, 0.02))
		_bus_tween = create_tween()
		_bus_tween.tween_method(func(db: float): AudioServer.set_bus_volume_db(bus_idx, db),
			AudioServer.get_bus_volume_db(bus_idx), target_db, fade_time)


# --- POOL ---

func _get_pooled_player() -> AudioStreamPlayer2D:
	var player := _sfx_pool[_sfx_pool_idx]
	_sfx_pool_idx = (_sfx_pool_idx + 1) % SFX_POOL_SIZE
	if player.playing:
		player.stop()
	return player


func _get_global_player() -> AudioStreamPlayer:
	var player := _sfx_global_pool[_sfx_global_idx]
	_sfx_global_idx = (_sfx_global_idx + 1) % SFX_GLOBAL_POOL_SIZE
	if player.playing:
		player.stop()
	return player


# --- CUTSCENE AUDIO ---

var _cutscene_sfx_player: AudioStreamPlayer = null
var _cutscene_music_player: AudioStreamPlayer = null

const CUTSCENE_SFX_PATHS: Dictionary = {
	"alarm":        "res://assets/audio/sfx/cutscene/cutscene_alarm.wav",
	"drill":        "res://assets/audio/sfx/cutscene/cutscene_drill.wav",
	"rumble":       "res://assets/audio/sfx/cutscene/cutscene_rumble.wav",
	"radio_static": "res://assets/audio/sfx/cutscene/cutscene_radio_static.wav",
	"leaves":       "res://assets/audio/sfx/cutscene/cutscene_leaves.wav",
	"heartbeat":    "res://assets/audio/sfx/cutscene/cutscene_heartbeat.wav",
	"march_drums":  "res://assets/audio/sfx/cutscene/cutscene_march_drums.wav",
}

const CUTSCENE_MUSIC_PATHS: Dictionary = {
	"cave_ambient": "res://assets/audio/music/cutscenes/cutscene_cave_ambient.mp3",
	"tense":        "res://assets/audio/music/cutscenes/cutscene_tense.mp3",
	"march":        "res://assets/audio/music/cutscenes/cutscene_march.mp3",
	"victory_end":  "res://assets/audio/music/cutscenes/cutscene_victory_end.mp3",
}


func play_cutscene_sfx(sfx_id: String) -> void:
	var path: String = CUTSCENE_SFX_PATHS.get(sfx_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	if _cutscene_sfx_player == null:
		_cutscene_sfx_player = AudioStreamPlayer.new()
		_cutscene_sfx_player.bus = "SFX"
		add_child(_cutscene_sfx_player)
	_cutscene_sfx_player.stream = load(path)
	_cutscene_sfx_player.play()


func play_cutscene_music(music_id: String) -> void:
	var path: String = CUTSCENE_MUSIC_PATHS.get(music_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	if _cutscene_music_player == null:
		_cutscene_music_player = AudioStreamPlayer.new()
		_cutscene_music_player.bus = "Music"
		_cutscene_music_player.volume_db = -8.0
		add_child(_cutscene_music_player)
	_cutscene_music_player.stream = load(path)
	_cutscene_music_player.play()


func stop_cutscene_audio(fade_time: float = 1.0) -> void:
	if _cutscene_sfx_player and _cutscene_sfx_player.playing:
		_cutscene_sfx_player.stop()
	if _cutscene_music_player and _cutscene_music_player.playing:
		var t := create_tween()
		t.tween_property(_cutscene_music_player, "volume_db", -80.0, fade_time)
		t.tween_callback(_cutscene_music_player.stop)


# --- UI & ENEMY SFX ---

func play_ui(sfx_id: String) -> void:
	var stream: AudioStream = _ui_sfx.get(sfx_id)
	if stream == null:
		return
	var player := _get_global_player()
	player.stream = stream
	player.play()


func play_enemy_sfx(sfx_id: String, position: Vector2 = Vector2.ZERO) -> void:
	var stream: AudioStream = _enemy_sfx.get(sfx_id)
	if stream == null:
		return
	if position == Vector2.ZERO:
		var player := _get_global_player()
		player.stream = stream
		player.play()
	else:
		var player := _get_pooled_player()
		player.stream = stream
		player.global_position = position
		player.play()


func fade_music_volume(target_db: float, duration: float = 0.5) -> void:
	if _music_player == null:
		return
	_kill_music_tweens()
	_kill_bus_tween()
	var bus_idx := AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, 0.0)
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", target_db, duration)
	# _music_intense is NOT touched here — its volume is owned by set_music_intensity only.
	# Always reset it to silent so it doesn't bleed through after cutscene restore.
	if _music_intense != null:
		if _intense_tween and _intense_tween.is_valid():
			_intense_tween.kill()
		_music_intense.volume_db = -40.0
