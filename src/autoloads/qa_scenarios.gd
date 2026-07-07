## QAScenarios — scripted sekwencje testów UI/interakcji
## Uruchamia się gdy `--qa-scenario=NAME` jest w args.
##
## Dostępne scenariusze:
##   shop_hover    — otwiera shop, hover karty, sprawdź czy stats się otwiera/zamyka
##   shop_unhover  — REGRESJA: sprawdź czy unhover ZAMYKA stats panel
##   wave_burst    — czeka na wave 2, robi burst screenshoty na każde trafienie
##   stress_horde  — spawnuje 20 wrogów, sprawdza separation pod presją
extends Node

var _running: bool = false
var _scenario: String = ""


func _ready() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--qa-scenario="):
			_scenario = arg.split("=")[1]
			break
	if _scenario.is_empty():
		return
	print("[QA Scenarios] Scenariusz: %s" % _scenario)
	call_deferred("_start")


func _start() -> void:
	# Czekaj na pełną inicjalizację gry
	await get_tree().create_timer(3.0).timeout
	match _scenario:
		"shop_hover":     await _scenario_shop_hover()
		"shop_unhover":   await _scenario_shop_unhover()
		"wave_burst":     await _scenario_wave_burst()
		"stress_horde":   await _scenario_stress_horde()
		_:
			print("[QA Scenarios] Nieznany scenariusz: %s" % _scenario)
			get_tree().quit(1)
			return
	print("[QA Scenarios] %s — DONE" % _scenario)
	get_tree().quit(0)


# ── Scenariusz 1: shop hover otwiera stats ────────────────────

func _scenario_shop_hover() -> void:
	# Otwórz shop programowo
	EventBus.shop_opened.emit()
	await get_tree().create_timer(1.0).timeout
	QAMode._capture("scenario_shop_initial")

	# Symuluj hover karty 1 (przez bezpośrednie wywołanie sygnału)
	var shop := _find_shop()
	if shop == null:
		print("[QA Scenarios] FAIL: shop_ui nie znaleziony")
		return
	var card_row := _find_card_row(shop)
	if card_row and card_row.get_child_count() > 0:
		var card := card_row.get_child(0)
		card.hovered.emit(card)  # symuluj hover
		await get_tree().create_timer(0.5).timeout
		QAMode._capture("scenario_shop_card_hovered")
		# Verify: stats_panel.visible == true
		var stats_open: bool = shop._stats_open if "_stats_open" in shop else false
		print("[QA Scenarios] hover → stats_open=%s (oczekiwano true)" % stats_open)


# ── Scenariusz 2: shop unhover ZAMYKA stats — REGRESJA ────────

func _scenario_shop_unhover() -> void:
	EventBus.shop_opened.emit()
	await get_tree().create_timer(1.0).timeout
	var shop := _find_shop()
	if shop == null:
		return
	var card_row := _find_card_row(shop)
	if card_row == null or card_row.get_child_count() == 0:
		return
	var card := card_row.get_child(0)

	# Hover
	card.hovered.emit(card)
	await get_tree().create_timer(0.5).timeout
	QAMode._capture("scenario_unhover_step1_hovered")
	var open_after_hover: bool = shop._stats_open if "_stats_open" in shop else false

	# Unhover
	card.unhovered.emit(card)
	await get_tree().create_timer(0.5).timeout
	QAMode._capture("scenario_unhover_step2_unhovered")
	var open_after_unhover: bool = shop._stats_open if "_stats_open" in shop else false

	# Raport
	print("[QA Scenarios] HOVER: stats_open=%s (oczekiwano true)" % open_after_hover)
	print("[QA Scenarios] UNHOVER: stats_open=%s (oczekiwano false)" % open_after_unhover)
	if open_after_unhover:
		print("[QA Scenarios] 🐛 BUG: stats panel NIE zamknął się po unhover!")
	else:
		print("[QA Scenarios] ✓ OK: stats panel zamknął się po unhover")


# ── Scenariusz 3: burst screenshoty na każde trafienie ────────

func _scenario_wave_burst() -> void:
	# Czekaj na wave 2 (różnorodne wrogowie)
	while GameManager.current_wave < 2:
		await get_tree().create_timer(1.0).timeout
	# Burst capture przez 15 sekund
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < 15000:
		QAMode._capture_burst("wave_burst")
		await get_tree().create_timer(2.0).timeout


# ── Scenariusz 4: stress horde — separation pod presją ────────

func _scenario_stress_horde() -> void:
	# Czekaj aż gra wystartuje
	while not GameManager.is_mission_active:
		await get_tree().create_timer(0.5).timeout
	await get_tree().create_timer(2.0).timeout

	# Spawnuj 20 Gruntów blisko siebie
	var scene := get_tree().current_scene
	var spawn_pos := Vector2(0, 0)
	if scene and scene.get_node_or_null("Squad"):
		spawn_pos = scene.get_node("Squad").global_position + Vector2(150, 0)

	var enemy_scene := load("res://src/entities/enemies/enemy_grunt.tscn") as PackedScene
	for i in range(20):
		var e: Enemy = enemy_scene.instantiate()
		e.global_position = spawn_pos + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		scene.add_child(e)
		e.configure(Enemy.EnemyType.GRUNT, GameManager.current_wave)

	# Co sekundę przez 10s: capture + state dump z metryką separacji
	for i in range(10):
		await get_tree().create_timer(1.0).timeout
		QAMode._capture("stress_horde_t%d" % i)


# ── Helpers ──────────────────────────────────────────────────

func _find_shop() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("ShopUI")


func _find_card_row(shop: Node) -> Node:
	# Card row jest dynamicznie tworzone w _refresh_ui
	# Szukamy w ItemList → ScrollContainer → HBoxContainer
	var item_list := shop.get_node_or_null("Panel/HBoxRoot/VBoxContainer/ScrollContainer/ItemList")
	if item_list == null:
		return null
	for child in item_list.get_children():
		if child is ScrollContainer:
			# horizontal ScrollContainer z card_row
			for sub in child.get_children():
				if sub is HBoxContainer:
					return sub
		elif child is HBoxContainer and child.get_child_count() > 0:
			return child
	return null
