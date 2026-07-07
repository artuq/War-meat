# game-mechanics/SKILL.md
# Load when: analizujesz wyniki QA, piszesz testy, weryfikujesz zachowanie gry
# Skip when: edytujesz UI, piszesz shadery, pracujesz z assetami

## Reguły Combat — MUSZĄ być prawdziwe

| Reguła | Wartość | Plik | Historia |
|--------|---------|------|---------|
| I-frame duration | 0.5s | soldier.gd:IFRAME_DURATION | QA bug: podwójny dmg |
| Knockback force (projectile) | 90.0 | projectile.gd:38 | QA bug: wrogowie nie odpychani |
| Knockback decay | lerpf 8.0×delta | enemy.gd:221 | |
| Soldier z_index | 2 (nad wrogami) | soldier.tscn | QA bug: zakryty przez wrogów |
| Min damage z armor | 1 (nie 0) | soldier.gd:take_damage | |

## Reguły Enemy — MUSZĄ być prawdziwe

| Reguła | Wartość | Plik | Historia |
|--------|---------|------|---------|
| Separation radius | 18.0px | enemy.gd:271 | Zwiększone z 14 (sesja 2) |
| Separation strength | 120.0 | enemy.gd:272 | Zwiększone z 55 (sesja 2) |
| Configure() — PO add_child | obligatoryjne | wave_manager.gd:118 | Bug: health_component null |
| Grenadier weight | > 0 (= 1.0) | wave_default.tres | BUG REGRESJA: był = 0 |
| Shooter ma ShootBehavior | po configure() | enemy_shooter.tscn | |
| Grenadier ma GrenadeBehavior | po configure() | enemy_grenadier.tscn | |

## Reguły Wave Spawning

| Reguła | Wartość |
|--------|---------|
| Wave 1 | TYLKO Grunt (min_wave=1) |
| Wave 2+ | Rusher (min_wave=2, weight=3.0) |
| Wave 3+ | Tank (min_wave=3), Shooter (min_wave=3) |
| Wave 4+ | Grenadier (min_wave=4, weight=1.0) |
| Wave duration | base=30s + 5s/wave |
| Boss wave | ostatnia fala (to_wave=5) |

## Reguły Shop / Upgrade

| Reguła | Wartość | Historia |
|--------|---------|---------|
| upgrade_panel_requested PRZED shop_opened | obligatoryjne | Flow bug |
| Stats panel domyślnie ukryty | custom_min_size.x = 0 | Mobile UX |
| Stats panel szerokość po otwarciu | 185px | |
| Karty sklepu szerokość | 130px (stała) | Mobile UX |
| CARD_COUNT | 5 (horizontal scroll) | |

## Reguły Kill Streak

| Próg | Speed bonus | Damage bonus | Label |
|------|-------------|--------------|-------|
| 3+ kills | +10% | 0% | KILL STREAK |
| 5+ kills | +15% | +10% | HOT! |
| 10+ kills | +25% | +20% | ON FIRE! |
| Combo window | 2.0s | | |

## Reguły HealthComponent

- `setup(max, true)` → pełne HP
- `set_max(n)` → nie resetuje current (tylko clips)
- `take_damage(0)` → nie emituje sygnałów (brak efektu)
- `is_alive()` → true gdy current_health > 0
- `on_unit_died` emituje DOKŁADNIE RAZ gdy hp → 0

## Visual BUG patterns — EXPLICIT failure detection

### Patrz na każdy screenshot WG TEJ LISTY. Każdy punkt = osobny test.

### A. Sprite fringing (background nie usunięty)
**SZUKAJ:** jasne piksele wokół krawędzi sprite'a — białe/jasno-szare halo  
**Sprawdzaj:** soldier sprite, weapon sprite, enemy sprites na ciemnym/zielonym tle  
**FAIL JEŚLI:** widzisz biały/jasny outline >= 1px wokół postaci (a nie celowy outline z shadera)  
**FIX:** PNG ma anti-aliased edges z białego BG. Reprocessing przez `tools/process_sprite.py` z properly removed background.

### B. Hover/unhover desync w sklepie
**Wymaga 2 kolejnych screenshotów:** `_hover_card_X` i `_after_unhover`  
**SZUKAJ:** stats panel (lewy panel z liczbami) widoczny W TYM SAMYM screenshocie gdzie żadna karta nie jest podświetlona (brak niebieskiej obwódki)  
**FAIL JEŚLI:** stats panel visible AND żadna karta nie hovered  
**FIX:** `_on_card_unhovered` w shop_ui.gd nie wywołuje `_set_stats_open(false)`

### C. Enemy stacking (separation < 18px)
**Sprawdź state JSON:** `metrics.min_enemy_separation`  
**FAIL JEŚLI:** `min_enemy_separation < 18.0` AND `enemy_count >= 2`  
**Visual sanity:** dwóch wrogów wizualnie zlanych w jeden kształt  
**FIX:** SEPARATION_STRENGTH w enemy.gd za niski lub VisionArea.collision_layer błędny.

### D. Enemy stuck on player (przyklejanie)
**Sprawdź state JSON:** `metrics.enemies_overlap_soldier`  
**FAIL JEŚLI:** > 0 dla kilku kolejnych screenshotów (wrogowie nie są odpychani po dłuższym czasie)  
**Visual:** żołnierz na ścianie wrogów, brak prześwitu  
**FIX:** Knockback od projectile nie działa (projectile.gd:38) lub jest za słaby (90.0 może być mało).

### E. Projectile miss (niecelne strzały)
**Wymaga frame sequence:** 3 kolejne klatki z `projectiles` w state JSON  
**FAIL JEŚLI:** projectile blisko wroga AND wróg się nie poruszył AND nie ma flash effect AND projectile_count nie zmalał  
**Analiza:** sprawdź `dir` pocisku vs target pos — gdzie pocisk leci?  
**FIX:** Predictive aiming w soldier.gd._shoot_at może być źle (`time_to_hit = dist / projectile_speed`)

### F. Soldier zakryty przez wrogów (z_index)
**Sprawdź state:** liczba enemies wokół soldiera vs widoczność  
**Visual:** czy widać soldier_sprite chociaż w środku tłumu?  
**FAIL JEŚLI:** w gęstej hordzie żołnierz całkowicie zniknięty  
**FIX:** soldier.tscn musi mieć z_index=2

### G. Kill streak czytelność
**Wymaga screenshota w trakcie streak (`heartbeat_*` gdy `streak_speed_bonus > 0`)**  
**FAIL JEŚLI:** tekst "ON FIRE!"/"HOT!" zlewa się z tłem (brak outline) LUB niewidoczny LUB wycentrowany za nisko (na środku gry)  
**FIX:** outline_size w kill_streak.gd musi być >= 4

### H. Shop card overflow / cut-off
**SZUKAJ:** karta sklepu częściowo ucięta na prawej krawędzi  
**OK:** ostatnia karta "peek-a-boo" = celowy hint scrollowania (~30% widoczne)  
**FAIL JEŚLI:** TEKST karty obcięty (np. "Snajper..." zamiast "Snajper") na 2-4 kartach

### I. Wave 1 ma non-Grunt wrogów
**Sprawdź state JSON:** `enemies[].type` przy `current_wave == 1`  
**FAIL JEŚLI:** jakikolwiek enemy.type != 0 podczas wave 1  
**FIX:** wave_default.tres min_wave dla non-Grunt musi być >= 2

### J. Floating joystick nie pojawia się przy dotyku
**Trudne wykryć ze screenshotów (statyczne).** Sprawdź state JSON: gdy `auto_player==false` i jest input — czy `squad.global_position` się zmienia?

## Visual — POPRAWNE wzorce (POSITIVE assertions)

- **Wave 1**: tylko brązowe blob enemies (Grunty)
- **Wave 2+**: różne typy (Rusher kolczasty, Tank fioletowy, Shooter, Grenadier)
- **Kill streak text**: outline 5px czarny, czytelny na każdym tle, w górnej części ekranu (offset_top=58)
- **Shop**: 4 pełne karty + 5. peek-a-boo (~30% widoczne na prawej)
- **Stats panel**: domyślnie 0px szerokości, otwiera się TYLKO przy hover karty lub klik 📊
- **Soldier**: widoczny nad wrogami w hordzie (z_index=2)
- **Damage numbers**: pojawiają się gdy wróg dostaje obrażenia
- **Coins**: żółte krążki przy zabitym wrogu, dryfują w stronę gracza

## Progi Performance (Android)

| Metryka | Minimum | Cel |
|---------|---------|-----|
| FPS | 30 | 60 |
| Pamięć | < 512MB | < 256MB |
| Czas startu | < 5s | < 3s |
