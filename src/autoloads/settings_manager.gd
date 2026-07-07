## SettingsManager — ustawienia gracza (ConfigFile-based)
extends Node

const SETTINGS_PATH := "user://settings.cfg"

# --- Audio ---
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 0.5  # matches default bus layout (-6 dB)

# --- Gameplay ---
var screen_shake_enabled: bool = true
var damage_numbers_enabled: bool = true
var vibrations_enabled: bool = true
var joystick_sensitivity: float = 1.0
var joystick_deadzone: float = 12.0  ## px; QA: 5px za mało na dotyk — palec dryfuje

# --- Performance ---
var target_fps: int = 60
var battery_saver: bool = false


func _ready() -> void:
	load_settings()
	_apply_all()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("gameplay", "screen_shake", screen_shake_enabled)
	config.set_value("gameplay", "damage_numbers", damage_numbers_enabled)
	config.set_value("gameplay", "vibrations", vibrations_enabled)
	config.set_value("gameplay", "joystick_sensitivity", joystick_sensitivity)
	config.set_value("gameplay", "joystick_deadzone", joystick_deadzone)
	config.set_value("performance", "target_fps", target_fps)
	config.set_value("performance", "battery_saver", battery_saver)
	config.save(SETTINGS_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = config.get_value("audio", "master_volume", 1.0)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	music_volume = config.get_value("audio", "music_volume", 0.5)
	screen_shake_enabled = config.get_value("gameplay", "screen_shake", true)
	damage_numbers_enabled = config.get_value("gameplay", "damage_numbers", true)
	vibrations_enabled = config.get_value("gameplay", "vibrations", true)
	joystick_sensitivity = config.get_value("gameplay", "joystick_sensitivity", 1.0)
	joystick_deadzone = config.get_value("gameplay", "joystick_deadzone", 12.0)
	target_fps = config.get_value("performance", "target_fps", 60)
	battery_saver = config.get_value("performance", "battery_saver", false)


func _apply_all() -> void:
	apply_audio()
	apply_fps()


func apply_audio() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("SFX", sfx_volume)
	_set_bus_volume("Music", music_volume)


func apply_fps() -> void:
	Engine.max_fps = target_fps


func set_battery_saver_mode(enabled: bool) -> void:
	battery_saver = enabled
	if enabled:
		target_fps = 30
	else:
		target_fps = 60
	apply_fps()
	save_settings()


func play_haptic(duration_ms: int = 50) -> void:
	if vibrations_enabled:
		Input.vibrate_handheld(duration_ms)


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if linear <= 0.01:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))
