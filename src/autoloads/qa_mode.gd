## QAMode — autonomiczny pilot gry dla automatycznego QA
## Aktywuje się gdy w argumentach jest `--qa-mode`.
## Robi: auto-start misji, auto-ruch squadu, event-driven screenshots, exit po N sekundach.
##
## Użycie z terminala:
##   godot --path . -- --qa-mode --qa-duration=60
extends Node

var active: bool = false
var duration: float = 60.0       # 0 = nieskończony (interaktywny tryb)
var auto_player: bool = true     # false = grasz sam, eventy się łapią
var elapsed: float = 0.0
var screenshot_count: int = 0
var _last_heartbeat: float = 0.0
const HEARTBEAT_INTERVAL: float = 5.0

# Auto-player state
var _ai_angle: float = 0.0
var _ai_radius: float = 200.0

# Model-based testing — chronological log of state transitions (EventBus signals)
# Format: [{event: "wave_started", payload: {wave: 1}, time: 5.2}, ...]
var transition_log: Array = []

# Deterministic RNG seed (capture or replay)
var rng_seed: int = 0

# Replay mode — pass --qa-replay=path/to/inputs.json
var replay_mode: bool = false
var record_mode: bool = false
var replay_input_log: Array = []   # loaded from JSON for replay
var input_log: Array = []           # captured for record


func _ready() -> void:
	var args := OS.get_cmdline_args()
	print("[QAMode] Args received: ", args)
	# Sprawdź zarówno cmdline_args jak i cmdline_user_args (Godot 4 dzieli je przy --)
	var user_args := OS.get_cmdline_user_args()
	print("[QAMode] User args: ", user_args)
	var all_args := args + user_args
	var has_flag := false
	for a in all_args:
		if a == "--qa-mode":
			has_flag = true
			break
	if not has_flag:
		print("[QAMode] No --qa-mode flag, exiting silently")
		return
	active = true
	for arg in all_args:
		if arg.begins_with("--qa-duration="):
			duration = float(arg.split("=")[1])
		elif arg == "--qa-interactive":
			auto_player = false
			duration = 0.0
		elif arg == "--qa-record":
			record_mode = true
			auto_player = false  # to TY grasz, my nagrywamy
			duration = 0.0
		elif arg.begins_with("--qa-replay="):
			replay_mode = true
			auto_player = false  # input z pliku, nie z AI
			var path: String = arg.split("=")[1]
			_load_replay(path)
		elif arg.begins_with("--qa-seed="):
			rng_seed = int(arg.split("=")[1])

	# Deterministic seed: jeśli nie podany → wygeneruj nowy i zapisz
	if rng_seed == 0:
		rng_seed = Time.get_unix_time_from_system() if not replay_mode else 0
	seed(rng_seed)
	print("[QA Mode] RNG seed = %d" % rng_seed)
	print("[QA Mode] ACTIVE — duration=%ss, record=%s, replay=%s" % [duration, record_mode, replay_mode])
	_clear_screenshots()
	call_deferred("_bootstrap")


func _load_replay(path: String) -> void:
	if not FileAccess.file_exists(path):
		# Spróbuj relative do projektu
		path = "res://" + path if not path.begins_with("res://") else path
	if not FileAccess.file_exists(path):
		push_error("[QA Mode] Replay file not found: " + path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		replay_input_log = parsed.get("inputs", [])
		rng_seed = int(parsed.get("seed", 0))
		print("[QA Mode] Loaded replay: %d frames, seed=%d" % [replay_input_log.size(), rng_seed])
	f.close()


func _bootstrap() -> void:
	# Czekaj aż GameManager i inne autoloady się załadują
	await get_tree().create_timer(0.5).timeout
	_connect_event_signals()
	# Skip menu — załaduj prosto arenę
	await get_tree().create_timer(1.0).timeout
	_auto_start_mission()


func _auto_start_mission() -> void:
	# Wymuszamy load areny (jungle = domyślna, zawsze odblokowana)
	if not GameManager.unlocked_arenas.has("jungle"):
		GameManager.unlocked_arenas = ["jungle"]
	GameManager.current_arena = ArenaModifier.create_jungle()
	GameManager.restoring_run = false
	print("[QA Mode] Loading arena: jungle")
	get_tree().change_scene_to_file("res://src/maps/arena.tscn")
	# Daj scenom czas na _ready
	await get_tree().create_timer(2.0).timeout
	_capture("mission_started")
	print("[QA Mode] Mission running")


func _connect_event_signals() -> void:
	# Mission lifecycle — zarówno capture jak i log transitions
	EventBus.mission_started.connect(func(): _log_transition("mission_started"))
	EventBus.wave_started.connect(func(w):
		_log_transition("wave_started", {"wave": w})
		_capture("wave_%d_start" % w))
	EventBus.wave_cleared.connect(func(w):
		_log_transition("wave_cleared", {"wave": w})
		_capture("wave_%d_cleared" % w))
	EventBus.shop_opened.connect(func():
		_log_transition("shop_opened")
		_capture("shop_opened"))
	EventBus.shop_closed.connect(func():
		_log_transition("shop_closed")
		_capture("shop_closed"))
	EventBus.upgrade_panel_requested.connect(func():
		_log_transition("upgrade_panel_requested")
		_capture("upgrade_panel"))
	EventBus.upgrade_panel_completed.connect(func(): _log_transition("upgrade_panel_completed"))
	EventBus.level_up.connect(func(l):
		_log_transition("level_up", {"level": l})
		_capture("level_%d" % l))
	EventBus.squad_wiped.connect(func():
		_log_transition("squad_wiped")
		_capture("squad_wiped"))
	EventBus.mission_won.connect(func():
		_log_transition("mission_won")
		_capture("mission_won"))
	EventBus.mission_lost.connect(func():
		_log_transition("mission_lost")
		_capture("mission_lost"))
	# Burst — 3 klatki dla detekcji ruchu
	EventBus.soldier_damaged.connect(func(_s): _capture_burst("soldier_hit"))
	EventBus.enemy_killed.connect(func(_e, _p): _capture_burst("kill"))


func _log_transition(event: String, payload: Dictionary = {}) -> void:
	transition_log.append({
		"event": event,
		"payload": payload,
		"time": elapsed,
	})


func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	# Heartbeat screenshot co 5s
	if elapsed - _last_heartbeat >= HEARTBEAT_INTERVAL:
		_last_heartbeat = elapsed
		_capture("heartbeat_%03ds" % int(elapsed))
	# Auto-zamknij panele tylko w trybie automatycznym (interactive = Ty klikasz)
	if auto_player:
		_maybe_auto_close_panels()
	# Koniec testu (duration=0 = nieskończony interaktywny)
	if duration > 0 and elapsed >= duration:
		_finish_run()


func _physics_process(delta: float) -> void:
	if not active:
		return
	var squad := _find_squad()
	# REPLAY: feed recorded inputs do squadu, ignoruj live input
	if replay_mode:
		var frame_idx: int = _replay_frame
		_replay_frame += 1
		if frame_idx < replay_input_log.size():
			var entry: Dictionary = replay_input_log[frame_idx]
			var dir := Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
			if squad and squad.has_method("_move_squad"):
				squad._move_squad(dir, delta)
		return
	# RECORD: capture aktualny input vector każdą klatkę
	if record_mode:
		var v := _read_input_vector()
		input_log.append({"f": _record_frame, "x": v.x, "y": v.y, "t": elapsed})
		_record_frame += 1
		return
	# AUTO-PLAYER: krąg
	if auto_player and squad and squad.has_method("_move_squad"):
		_ai_angle += delta * 0.3
		var d := Vector2(cos(_ai_angle), sin(_ai_angle))
		squad._move_squad(d, delta)


var _replay_frame: int = 0
var _record_frame: int = 0


func _read_input_vector() -> Vector2:
	# Gra używa VirtualJoystick — czytaj bezpośrednio z joysticka squadu
	var squad := _find_squad()
	if squad and "_joystick" in squad and squad._joystick != null:
		return squad._joystick.get_direction()
	# Fallback: InputMap (keyboard debug)
	if InputMap.has_action("move_left") and InputMap.has_action("move_right") \
			and InputMap.has_action("move_up") and InputMap.has_action("move_down"):
		return Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return Vector2.ZERO


func _maybe_auto_close_panels() -> void:
	if get_tree().current_scene == null:
		return
	var up_panel := get_tree().current_scene.get_node_or_null("UpgradePanel")
	if up_panel and up_panel.visible:
		# Nie znamy struktury — wybierz "Skip" (najprostsze)
		if up_panel.has_method("_on_skip"):
			up_panel._on_skip()
	# Zamknij shop po 2 sekundach pokazania (już go screenshotujemy)
	var shop := get_tree().current_scene.get_node_or_null("ShopUI")
	if shop and shop.visible and shop.has_method("_on_continue"):
		# Zamknij od razu — to AI test, nie symulacja zakupów
		shop._on_continue()


func _find_squad() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("Squad")


## Burst — 3 klatki w ciągu 0.1s (before/during/after).
## Pozwala wykryć: trajektorię pocisku, ruch wroga po knockbacku, zniknięcie po śmierci.
## Throttled — max 1 burst na sekundę żeby nie zapchać dysku.
var _last_burst_time: float = -10.0

func _capture_burst(label: String) -> void:
	if not active:
		return
	if elapsed - _last_burst_time < 1.0:
		return  # throttle
	_last_burst_time = elapsed
	_capture("%s_t0" % label)
	await get_tree().create_timer(0.05, true).timeout
	_capture("%s_t1" % label)
	await get_tree().create_timer(0.05, true).timeout
	_capture("%s_t2" % label)


func _capture(label: String) -> void:
	if not active:
		return
	screenshot_count += 1
	await RenderingServer.frame_post_draw
	var viewport := get_viewport()
	if viewport == null:
		return
	var img := viewport.get_texture().get_image()
	if img == null:
		return
	var dir := DirAccess.open("res://tests")
	if dir and not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")
	var basename := "%03d_%s" % [screenshot_count, label]
	var png_path := "res://tests/screenshots/%s.png" % basename
	var json_path := "res://tests/screenshots/%s.json" % basename
	img.save_png(png_path)
	# State dump obok PNG — analiza nie polega tylko na pixelach
	_dump_state(json_path, label)
	print("[QA Mode] 📸 %s + state" % png_path)


# ── STATE DUMP — pełny stan gry w JSON ────────────────────────

func _dump_state(path: String, label: String) -> void:
	var state := {
		"label": label,
		"frame_index": screenshot_count,
		"elapsed": elapsed,
		"timestamp_ms": Time.get_ticks_msec(),
		# Game state
		"game": _collect_game_state(),
		"soldiers": _collect_soldiers(),
		"enemies": _collect_enemies(),
		"projectiles": _collect_projectiles(),
		# Computed metrics — auto-rule checks
		"metrics": _compute_metrics(),
		# UI states
		"ui": _collect_ui_state(),
	}
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(state, "  "))
		f.close()


func _collect_game_state() -> Dictionary:
	return {
		"current_wave": GameManager.current_wave,
		"gold": GameManager.gold,
		"level": GameManager.level,
		"xp": GameManager.xp,
		"enemies_killed": GameManager.enemies_killed,
		"streak_speed_bonus": GameManager.streak_speed_bonus,
		"streak_damage_bonus": GameManager.streak_damage_bonus,
		"passives_count": GameManager.passive_items.size(),
		"is_mission_active": GameManager.is_mission_active,
	}


func _collect_soldiers() -> Array:
	var result: Array = []
	for s in get_tree().get_nodes_in_group("squad"):
		if not is_instance_valid(s):
			continue
		var entry := {
			"pos": [s.global_position.x, s.global_position.y],
			"hp": s.hp if "hp" in s else -1,
			"max_hp": s.max_hp if "max_hp" in s else -1,
			"is_invulnerable": s.is_invulnerable if "is_invulnerable" in s else false,
			"class": s.soldier_class.class_name if (s.soldier_class and "class_name" in s.soldier_class) else "?",
		}
		result.append(entry)
	return result


func _collect_enemies() -> Array:
	var result: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var entry := {
			"pos": [e.global_position.x, e.global_position.y],
			"hp": e.hp if "hp" in e else -1,
			"type": e.enemy_type if "enemy_type" in e else -1,
			"is_dying": e._is_dying if "_is_dying" in e else false,
			"knockback_power": e._knockback_power if "_knockback_power" in e else 0.0,
		}
		result.append(entry)
	return result


func _collect_projectiles() -> Array:
	var result: Array = []
	# Projectiles są w current_scene jako Area2D — szukamy po klasie
	for n in get_tree().current_scene.get_children() if get_tree().current_scene else []:
		if n is Projectile:
			result.append({
				"pos": [n.global_position.x, n.global_position.y],
				"dir": [n.direction.x, n.direction.y],
				"damage": n.damage,
				"is_crit": n.is_crit,
			})
	return result


func _compute_metrics() -> Dictionary:
	# Auto-checki regulowane: znajdź naruszenia reguł z game-mechanics/SKILL.md
	var metrics := {
		"min_enemy_separation": -1.0,
		"avg_enemy_separation": -1.0,
		"enemies_within_18px": 0,  # BUG jeśli > 0 (separation rule)
		"enemies_overlap_soldier": 0,  # BUG jeśli > 0 (stuck-on-player)
		"enemies_with_knockback": 0,
		"soldier_count": 0,
		"enemy_count": 0,
		"projectile_count": 0,
	}
	var enemies: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and "_is_dying" in e and not e._is_dying:
			enemies.append(e)
	var soldiers: Array = []
	for s in get_tree().get_nodes_in_group("squad"):
		if is_instance_valid(s):
			soldiers.append(s)
	metrics["enemy_count"] = enemies.size()
	metrics["soldier_count"] = soldiers.size()

	# Min separation między wrogami (kluczowe dla reguły SEPARATION_RADIUS=18)
	if enemies.size() >= 2:
		var min_dist := INF
		var sum_dist := 0.0
		var pair_count := 0
		var violations := 0
		for i in range(enemies.size()):
			for j in range(i + 1, enemies.size()):
				var d: float = enemies[i].global_position.distance_to(enemies[j].global_position)
				if d < min_dist: min_dist = d
				sum_dist += d
				pair_count += 1
				if d < 18.0: violations += 1
		metrics["min_enemy_separation"] = min_dist
		metrics["avg_enemy_separation"] = sum_dist / pair_count if pair_count > 0 else 0.0
		metrics["enemies_within_18px"] = violations

	# Wrogowie nakładający się na żołnierzy (przyklejanie)
	for s in soldiers:
		for e in enemies:
			if s.global_position.distance_to(e.global_position) < 14.0:  # collision radius ~12 + buffer
				metrics["enemies_overlap_soldier"] += 1

	# Knockback w trakcie (czy mechanizm działa)
	for e in enemies:
		if "_knockback_power" in e and e._knockback_power > 0.01:
			metrics["enemies_with_knockback"] += 1

	# Liczba pocisków na ekranie
	if get_tree().current_scene:
		for n in get_tree().current_scene.get_children():
			if n is Projectile:
				metrics["projectile_count"] += 1
	return metrics


func _collect_ui_state() -> Dictionary:
	var scene := get_tree().current_scene
	if scene == null:
		return {}
	var shop := scene.get_node_or_null("ShopUI")
	var upgrade := scene.get_node_or_null("UpgradePanel")
	var hud := scene.get_node_or_null("HUD")
	var stats_open := false
	var preview_card := "none"
	if shop and "_stats_open" in shop:
		stats_open = shop._stats_open
	if shop and "_stats_column" in shop and shop._stats_column and "current_preview_card" in shop._stats_column:
		if shop._stats_column.current_preview_card != null:
			preview_card = "set"
	return {
		"shop_visible": shop.visible if shop else false,
		"upgrade_panel_visible": upgrade.visible if upgrade else false,
		"hud_visible": hud.visible if hud else false,
		"stats_panel_open": stats_open,
		"preview_card_state": preview_card,
		"paused": get_tree().paused,
	}


func _clear_screenshots() -> void:
	var dir := DirAccess.open("res://tests/screenshots")
	if dir == null:
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".png"):
			dir.remove(f)
		f = dir.get_next()


func _finish_run() -> void:
	if not active:
		return
	active = false
	print("[QA Mode] DONE — captured %d screenshots in %ss" % [screenshot_count, int(elapsed)])
	_write_report()
	_write_recording()
	get_tree().quit(0)


func _notification(what: int) -> void:
	# Zapisz nagranie również gdy użytkownik zamyka okno (Cmd+Q / X)
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if active and record_mode:
			_write_report()
			_write_recording()


func _write_report() -> void:
	var report := {
		"qa_mode": true,
		"duration": elapsed,
		"screenshots_taken": screenshot_count,
		"timestamp": Time.get_datetime_string_from_system(),
		"seed": rng_seed,
		"transitions": transition_log.size(),
		"input_frames": input_log.size(),
		"record_mode": record_mode,
		"replay_mode": replay_mode,
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/reports"))
	var f := FileAccess.open("res://tests/reports/qa_mode_report.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(report, "  "))
		f.close()
	# Zawsze zapisuj transition_log — przyda się check_state_model.py
	var tf := FileAccess.open("res://tests/reports/transition_log.json", FileAccess.WRITE)
	if tf:
		tf.store_string(JSON.stringify({"seed": rng_seed, "transitions": transition_log}, "  "))
		tf.close()


func _write_recording() -> void:
	# Tylko w record_mode → pełny dump do replay
	if not record_mode:
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/recordings"))
	var ts: String = Time.get_datetime_string_from_system().replace(":", "-")
	var path := "res://tests/recordings/%s.json" % ts
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"seed": rng_seed,
			"duration": elapsed,
			"inputs": input_log,
			"transitions": transition_log,
		}, "  "))
		f.close()
		print("[QA Mode] 💾 Recording saved: %s (%d input frames, %d transitions)" \
				% [path, input_log.size(), transition_log.size()])
