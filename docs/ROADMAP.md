# 🗺️ WAR MEAT — Roadmapa Projektu

> Poniżej znajduje się plan rozwoju gry podzielony na fazy.
> Szczegółowe zadania są śledzone jako [GitHub Issues](../../issues).
> Aby wygenerować issues z tego planu, uruchom workflow **Create Issues from Roadmap** w zakładce Actions.

---

## Faza 0 — Fundament projektu ✅

> Cel: Przygotowanie środowiska, dokumentacji i podstawowej struktury projektu.

👉 [Zadania Fazy 0](../../issues?q=is%3Aissue+label%3Aphase-0)

- ✅ **Wybór silnika gry** — Godot 4.6 (GDScript, Mobile renderer)
- ✅ **Konfiguracja repozytorium** — Struktura katalogów, `.gitignore`, CI/CD
- ✅ **Utworzenie Game Design Document (GDD)** — Szczegółowy dokument opisujący mechaniki
- ✅ **Określenie docelowej platformy** — Mobile (Android) — landscape 640×360
- ✅ **Wybór stylu graficznego** — Placeholder _draw() circles → docelowo **High-res Pixel Art** (128 px source, Enter the Gungeon style, Linear texture filter, scale-down w Godot)

---

## Faza 1 — Prototyp (MVP) ✅

> Cel: Grywalny prototyp z jedną postacią, jedną mapą i podstawową mechaniką walki.

👉 [Zadania Fazy 1](../../issues?q=is%3Aissue+label%3Aphase-1)

### 1.1 Ruch i sterowanie
- ✅ **System ruchu postaci** — Wirtualny joystick do sterowania oddziałem (mobile-first)
- ✅ **Kamera** — Śledzenie oddziału gracza z widokiem z góry (zoom 2.0×)
- ✅ **Kolizje** — System kolizji ze środowiskiem (walls, debris) + warstwy kolizji

### 1.2 Walka
- ✅ **System strzelania** — Auto-aim z predictive aiming + orbitująca broń (WeaponPivot)
- ✅ **Typy broni (podstawowe)** — Karabin (szybki ogień), Strzelba (5 pocisków), Pistolet (precyzja)
- ✅ **Nowe typy broni** — SMG (bardzo szybki ogień, niski DMG), Sniper Rifle (wolny, wysoki DMG, duży range), Granatnik ręczny (AoE, wolny, splash)
- ✅ **System obrażeń** — HP, obrażenia, śmierć, flash damage, Simple Health Bar addon
- ✅ **Wrogowie (podstawowi)** — 3 typy: Grunt, Rusher, Tank z AI (dążenie do gracza)

### 1.3 Mapa i fale
- ✅ **Generowanie areny** — Arena z losowymi przeszkodami (debris)
- ✅ **System fal** — Spawning w falach o rosnącej trudności (+15% stats/fala). Camera-edge spawning (30px poza widokiem kamery). Szybki spawn: 0.5s→0.15s
- ✅ **Popcorn enemies** — Grunt HP 12 (było 30), Rusher HP 8 (było 15) — szybko giną, duże hordy
- ✅ **Warunek zwycięstwa/przegranej** — Przetrwanie 5 fal lub śmierć → Game Over z restartem

---

## Faza 2 — Systemy bazowe ✅

> Cel: Dodanie kluczowych systemów: loot, sklep, klasy żołnierzy.

👉 [Zadania Fazy 2](../../issues?q=is%3Aissue+label%3Aphase-2)

### 2.1 System lootu
- ✅ **Drop z wrogów** — Wrogowie upuszczają złoto po śmierci (skalowane per fala)
- ✅ **Zbieranie przedmiotów** — Automatyczne z 0.3s opóźnieniem (widoczny drop)
- ✅ **Rzadkie skrzynki (Crate Drop)** — Bossowie i elitarni wrogowie (5-10% chance) dropują skrzynki z losową nagrodą: pasywka / broń wyższego tieru / bonus gold. Auto-pickup, floating text reward
- ✅ **Inwentarz** — System inventory w GameManager, śledzenie pasywnych przedmiotów, wyświetlanie w STATS

### 2.2 Sklep między falami
- ✅ **Interfejs sklepu** — UI z ScrollContainer, sekcje REKRUTACJA + SKLEP, przycisk DALEJ
- ✅ **Asortyment** — Bronie, pancerz, apteczki + wyszarzanie posiadanych broni
- ✅ **Ekonomia** — Zwiększone dropy złota, bonus za falę (25+15×wave), obniżone ceny sklepu, luck-based gold bonus
- ✅ **Reroll asortymentu** — Przycisk odświeżenia oferty za złoto (koszt rosnący: 10→20→40→80)
- ✅ **Banish przedmiotów** — Trwałe usunięcie itemu z puli runu, max 3 banishe per run
- ✅ **Unified 5-Card Shop** — Jedna pula 5 kart (bronie+pasywki+konsumable+rekruci) zamiast osobnych sekcji

### 2.3 Klasy żołnierzy
- ✅ **System klas** — SoldierClass Resource (Szturmowiec, Snajper, Medyk)
- ✅ **Atrybuty klas** — Unikalne HP/SPD/DMG/kolor/broń domyślna + medyk heal pasywny
- ✅ **Rekrutacja** — Sekcja w sklepie, max 4 żołnierzy, koszt skalowany (200→300→400)

### 2.4 System atrybutów
- ✅ **Statystyki postaci** — HP, atak (damage_mult), szybkość, zasięg + panel STATS
- ✅ **Statystyka „szczęścia"** — Luck per klasa, crit chance (luck/200, ×2 DMG), gold bonus (+1%/luck), Talizman Szczęścia w sklepie
- ✅ **Poziomowanie** — System XP (50×level), +10 HP na level, pasek XP w HUD

---

## Faza 3 — Areny i progresja

> Cel: System tematycznych aren z bossami, ekwipunek ze slotami, meta-progresja, nowi wrogowie.
> Kierunek: Arena-survivor (Brotato-style) — czysta walka arenowa, zero misji liniowych.

👉 [Zadania Fazy 3](../../issues?q=is%3Aissue+label%3Aphase-3)

### 3.1 System aren tematycznych
- ✅ **Ekran wyboru areny** — Mapa/lista z 3 arenami, progresja liniowa (odblokuj kolejną po ukończeniu)
- ✅ **Arena: Dżungla** — Gęste debris, mniejsza widoczność. Modyfikator: +20% spawn rate, dominacja Rusherów
- ✅ **Arena: Pustynia** — Otwarta przestrzeń, mało osłon. Modyfikator: wrogowie +15% range, piasek -10% speed
- ✅ **Arena: Bunkier** — Ciasne korytarze, dużo ścian. Modyfikator: wybuchające beczki, więcej ciężkich wrogów
- ✅ **ArenaModifier Resource** — `spawn_rate_mult`, `enemy_pool_weights`, `environment_hazards`, `visual_theme`
- ✅ **Skalowanie trudności** — 5 fal + boss na fali 5. Dżungla=łatwa, Pustynia=średnia, Bunkier=trudna

### 3.2 Ekwipunek i synergie
- ✅ **Siatka ekwipunku** — 8 slotów pasywnych (PassiveItem Resource) zastępuje stary `inventory: Dictionary`
- ✅ **Slot system** — Refactor `GameManager.inventory` na `passive_items: Array[PassiveItem]` z limitem 8
- ✅ **Nowe pasywne przedmioty** — Amulet Szybkości, Stalowy Pancerz, Lunetka, Adrenalina, Nóż Bojowy, Kamizelka, Napój Energetyczny + Talizman Szczęścia
- ✅ **Rozszerzenie puli pasywek (8→16)** — Apteczka Polowa, Tarcza Kinetyczna, Celownik Laserowy, Plecak Taktyczny, Buty Szturmowe, Maska Gazowa, Zapalnik, Lornetka
- ✅ **Synergie (proste)** — 3 tagi (Szybkość/Obrona/Ofensywa), bonus za 3+: unik 10% / armor -3 / +15% DMG
- ✅ **Panel ekwipunku** — StatsPanel z siatką pasywek, kolorami, synergami + sklep z rotującymi ofertami
- ✅ **Tiery broni (I→V)** — `tier: Tier` w WeaponData, mnożnik statów: Common ×1.0 → Uncommon ×1.25 → Rare ×1.5 → Epic ×1.85 → Legendary ×2.25
- ⬜ **Color coding itemów** — Kolorowe obramowania broni i pasywek w UI sklepu, HUD i ekwipunku. Kolor = natychmiastowa informacja o tier/wartości na 640×360
- ⬜ **Ewolucje broni** — System Recipe: broń max lv + konkretna pasywka = epicka ewolucja (np. Strzelba + Amulet Szybkości = Dragon Breath). EvolutionData Resource + Dictionary recept + check w sklepie
- ⬜ **Wizualna ewolucja broni** — Zmiana wyglądu broni i kolorów pocisków po ewolucji/max upgrade

### 3.3 Nowi wrogowie i bossowie
- ✅ **Strzelec** — Stoi w miejscu, strzela z dystansu (nowa scena enemy)
- ✅ **Granatnik** — AoE damage z ostrzegawczym indicatorem przed wybuchem
- ✅ **Boss: Dżungla** — Szybki boss z dash + summon Rusherów
- ✅ **Boss: Pustynia** — Snajperski boss z dalekiego zasięgu + burst pocisków
- ✅ **Boss: Bunkier** — Tank boss z tarczą + faza berserka
- ✅ **System bossów** — Boss scene z fazami HP (100%→50%→25%), unikalne patterny ataku

### 3.4 Meta-progresja (uproszczona)
- ✅ **Hub Screen** — TabContainer z 3 zakładkami: Areny, Ulepszenia, Klasy + wyświetlanie surowców
- ✅ **Permanentne ulepszenia** — 3 typy: Wzmocnienie HP (5 lvl), Trening Bojowy (5 lvl), Dodatkowy Slot (2 lvl) za surowce
- ✅ **Odblokowywanie klas** — Inżynier (dżungla), Zwiadowca (pustynia), Ciężki (bunkier) — za surowce po ukończeniu areny
- ✅ **Save system** — JSON save/load: odblokowane areny, ulepszenia, surowce, klasy (`user://warmeat_save.json`)

### 3.5 Narracja (minimalna)
- ✅ **Briefing przed areną** — 1-2 zdania flavor text w DialogBox (skippable), pauza przed startem fal
- ✅ **Dialog po bossie** — 3-4 linijki po pokonaniu bossa areny (all_waves_cleared)
- ✅ **DialogBox scene** — Komponent CanvasLayer: portret emoji + tekst + Dalej/Skip + pauza gry
- ⬜ **Handlarz w sklepie** — Postać NPC komentująca postępy (1-2 zdania flavor text co parę fal)
- ⬜ **Environmental storytelling** — Elementy tła map: klatki lab (bunkier), szkielety pojazdów (pustynia), ruiny (dżungla)

---

## Faza 4 — Polish, game feel i balans

> Cel: Soczystość rozgrywki (game feel), finalna oprawa audio-wizualna, balans, UI/UX.
> Priorytet: Gra z auto-aimem musi wyglądać i brzmieć rewelacyjnie przy koszeniu setki wrogów.

👉 [Zadania Fazy 4](../../issues?q=is%3Aissue+label%3Aphase-4)

### 4.1 Game feel (priorytet!)
- ✅ **Screen shake** — Przy eksplozjach, śmierci, atakach bossów. Podłączony jako child Camera2D w arena.tscn
- ✅ **Damage numbers** — Floating numbers (żółte normalne, czerwone crit, duże boss damage). Spawner w enemy.gd + boss.gd `take_damage()`
- ✅ **Hit stop / hit flash** — Krótkie freeze-frame na zabójstwo wroga. Node w arena.tscn, `Engine.time_scale = 0.05`
- ✅ **Particle effects** — Muzzle flash, hit sparks, death puff, explosion, loot sparkle (CPUParticles2D)
- ✅ **Kill streak / combo** — CanvasLayer w arena.tscn, anchor CENTER_TOP (nie nakłada się na HUD), 2s combo window, min 3 kills
- ✅ **Camera zoom pulse** — Subtelny zoom na wave clear i all waves cleared
- ✅ **Loot bounce + idle bob** — Spawn: scale 0→1.2→1.0 tween, ciągły sinus bob (3Hz, ±0.15px)
- ✅ **Enemy white outline** — `draw_arc()` biały ring (radius+1.5) na wszystkich typach wrogów
- ✅ **Enemy separation (Boids)** — Soft-collision: 14px radius, 60 siła odpychania, wrogowie tworzą „chmarę" zamiast jednej kropki
- ✅ **Enemy knockback** — Odrzut po uderzeniu (120 force, 0.2s, friction 0.85×), wróg odskakuje od gracza
- ✅ **Melee AI wind-up** — 3-stanowy system: CHASE → WIND-UP (0.15s stop) → ATAK + knockback → COOLDOWN (0.4s) → CHASE. ~0.75s cykl ataku

### 4.2 Art i animacje (High-res Pixel Art — modular)

> Szczegółowy plan: [ART_PLAN.md](ART_PLAN.md) (~100 assetów, zero animacji klatkowych)
> Workflow: Gem generuje ≥1024 px source → user downscale w Aseprite (Nearest Neighbor) → Godot Linear filter
> Style guide: [war_meat_gem_prompt_v3.txt](../assets/art_pipeline/war_meat_gem_prompt_v3.txt) + [war_meat_gem_knowledge_v3.txt](../assets/art_pipeline/war_meat_gem_knowledge_v3.txt)
> Podejście: Statyczne sprite'y + procedural animation (Tween, flip_h, wobble, shader)

**P0 — System setup (kod, 0 assetów):**
- ✅ **flip_h facing** — Żołnierze patrzą w stronę wroga (weapon target). Wrogowie flip_h w stronę gracza
- ✅ **Movement wobble** — sin() rotation ±4.5° na body sprite podczas ruchu
- ⬜ **Weapon recoil tween** — Cofnięcie sprite broni o 3px + powrót w 0.08s przy strzale
- ✅ **hit_flash (kod)** — Modulate flash: czerwony Color(1,0.3,0.3) + scale punch ×1.3 na 0.15s przy trafieniu
- ⬜ **Death splat system** — Sprite decal na ziemi po śmierci wroga (zostaje do końca fali)
- ✅ **Shadow system** — Sprite2D czarny owal pod każdą jednostką (alpha 0.2)

**P1 — Żołnierze (8 assetów):**
- ✅ **Body sprites** — Wszystkie klasy zintegrowane (Assault, Engineer, Heavy, Medic, Scout, Sniper)
- ✅ **Hand sprite** — Hand.svg (4×4 px), przyklejona do broni via HandBack/HandFront nodes
- ✅ **Shadow sprite** — Shadow.svg owal pod każdą jednostką

**P2 — Wrogowie (9 assetów):**
- ✅ **Enemy sprites** — Wszystkie 5 typów gotowych (Grunt, Rusher, Tank, Shooter, Grenadier) zintegrowane w kodzie
- ⬜ **Boss sprites** — 3 bossów (24-28px) + 1 shield overlay

**P3 — Bronie (7 assetów):**
- 🔶 **Weapon sprites** — 1/7 gotowych (Karabin.svg zintegrowany w soldier.gd). Pozostałe: Pistolet, Strzelba, SMG, Sniper, Granatnik, Nóż (tier → tint w kodzie)

**P4 — Pociski + FX (12 assetów):**
- ⬜ **Bullet sprites** — 5 typów (standard, crit, enemy, rakieta, sniper trail)
- ⬜ **FX sprites** — Muzzle flash (2-3), hit spark (2), death splat (2+1 boss)

**P5 — Loot + UI (~32 assetów):**
- ✅ **Loot sprites** — Coin.svg, Crate.svg (zintegrowane w loot_drop.gd)
- 🔶 **UI skin** — 1/x (Panel BG.svg zintegrowane jako tło popupów/paneli). Do zrobienia: button (3 stany) + card frames (5 tierów) + ikony pasywek (16)

**P6 — Tilemapy (~30 assetów):**
- ⬜ **Tilemapy tematyczne** — 3 areny × ~10 tile'i (floor, wall, dekoracje)

**Art:**
- ✅ **Kontrastowy outline** — Biały `draw_arc` outline na wszystkich wrogach (placeholder). Docelowo: CanvasItem shader
- ⬜ **Zarządzanie paletą barw** — Kontrastowe pociski wrogów vs tło areny. Tła ciemne, jednostki jasne (kontrast ≥ 3:1)

### 4.3 Audio (SUNO AI + Godot)

> Szczegółowy plan: [AUDIO_PLAN.md](AUDIO_PLAN.md) (~85 assetów, SUNO generacja + pitch-shifting w Godocie)
> Podejście: Brotato juiciness + Cannon Fodder militarny klimat. Dynamiczny mix muzyki.

**P0 — System audio (kod, 0 assetów):**
- ✅ **AudioBus layout** — Master → SFX (0dB) + Music (-6dB) w default_bus_layout.tres
- ✅ **SoundManager autoload** — Singleton: play_music/play_music_layered/play_weapon_sfx/play_stinger, pooling 16×2D+4×global, pitch rand ±10%
- ✅ **Voice limiting** — Max 4 weapon voices, kill najstarszych
- ✅ **AudioStreamPlayer2D** — Pozycjonowany dźwięk strzału per żołnierz w soldier.gd

**P0 — SFX Walki (~45 assetów, Bfxr/Kenney — NIE SUNO):**
- 🔶 **Weapon SFX** — 2/21 gotowe (rifle_01.wav, rifle_02.wav — zintegrowane w soldier.gd). Pozostałe: 6 typów × 3 warianty (do wygenerowania w Bfxr / sfxr / pobrania z Kenney.nl)
  - ⚠️ QA: SUNO SFX "szczekają" (brak transjentu) — wszystkie nowe SFX **tylko WAV**, nie MP3 (~50ms padding)
- ⬜ **Impact SFX** — Hit normal/crit/boss/shield × 3 warianty = 12
- ⬜ **Death SFX** — Grunt-Rusher/Tank-Heavy/Boss × 2 warianty = 6
- ⬜ **Explosion SFX** — Granat/Beczka × 2 warianty = 4
- ⬜ **Reload SFX** — 1 typ × 2 warianty = 2

**P1 — SFX Feedback i UI (~20 assetów, SUNO):**
- ⬜ **Loot SFX** — Coin pickup, vacuum, crate drop/open, HP pickup (5)
- ⬜ **Shop SFX** — Buy, sell, reroll, banish, error (5)
- ⬜ **Progression SFX** — Level up, wave start/clear, kill streak, recruit, game over (6)
- ⬜ **Navigation SFX** — Hover, press, panel open/close (4)
- ⬜ **Loot pitch ramp** — Rosnący ton przy zbieraniu monet pod rząd (kod)

**P2 — Muzyka (~12 tracków, SUNO):**
- ✅ **Menu + Hub themes** — menu_theme.mp3, hub_theme.mp3 (zintegrowane w main_menu.gd, hub_screen.gd) — 🔶 **TODO: konwersja MP3 → OGG** (ffmpeg snippet w AUDIO_PLAN.md sec 7.3) — MP3 dodaje ~50ms ciszy na początku
- 🔶 **Arena themes** — 1/3 aren gotowych: jungle_base.mp3 + jungle_intense.mp3 (layered w arena.gd). Brak: pustynia, bunkier. 🔶 TODO: konwersja MP3→OGG
- ⬜ **Boss theme** — 1 uniwersalny track loop
- 🔶 **Stingery** — 1/3: victory_stinger.mp3 (wave_manager.gd). Brak: Defeat, Shop/Inter-wave. 🔶 TODO: konwersja MP3→OGG (krytyczne dla stingera — padding opóźnia trigger)
- ✅ **Dynamic music system** — play_music_layered() crossfade base↔intense via set_music_intensity(0..1)
- ✅ **Music transitions** — Fade in/out/crossfade między scenami (1-2s), stop_music()

**P3 — Polish audio (~8 assetów):**
- ⬜ **Formation/command SFX** — Gwizdek dowódcy, radio chatter
- ⬜ **Environment ambient** — 3 areny loop (jungle, desert, bunker)
- ⬜ **Low HP effect** — Heartbeat loop + low-pass filter (2000→800 Hz) + music duck -6dB
- ⬜ **Haptic feedback** — Wibracje Android: eksplozja 100ms, boss hit 50ms, level up 200ms
- ⬜ **Dodge/dash SFX** — Jeśli dash mechanic zostanie dodany

### 4.4 Balans
- ⬜ **Balans broni** — DPS normalizacja per tier, każda broń ma swoją niszę, tiery nie powodują power creep
- ⬜ **Balans klas** — Każda klasa użyteczna, żadna dominująca
- ⬜ **Krzywa trudności** — Progresywna per arena, potwierdzona playtestingiem
- ⬜ **Balans ekonomii** — Tempo zarobków vs ceny per tier areny

### 4.5 UI/UX
- ⬜ **Menu główne** — Start, Kontynuuj, Ustawienia
- ⬜ **Ekran wyników** — Zabici, złoto, czas, najlepsza seria, ocena (S/A/B/C)
- ⬜ **Tutorial** — Overlay hints na pierwszą arenę
- ⬜ **Ustawienia** — Głośność, czułość joysticka, wibracje
- ⬜ **Toggle dostępności** — Screen shake on/off, Damage numbers on/off, 30/60 FPS, tryb baterii
- ✅ **Fat finger friendly** — Dialog: DALEJ 160×56, SKIP 100×56. HUD: HP bar 20px, XP 12px, fonty +2-4pt. Pause button 44×44. Shop: karty 80px min, fonty 8-9pt
- ✅ **Pause menu** — CanvasLayer (layer 20) z dimmer overlay. Przyciski KONTYNUUJ / RESTART / MENU GŁÓWNE (160×48). `process_mode=ALWAYS`
- ⬜ **Scroll inertia touch** — Fizyka scrollowania dopasowana do touch

---

## Faza 5 — Testowanie i wydanie

> Cel: Stabilizacja, optymalizacja mobilna, beta-testy, publikacja Google Play.

👉 [Zadania Fazy 5](../../issues?q=is%3Aissue+label%3Aphase-5)

- ⬜ **QA wewnętrzne** — Przejście 3 aren, test bossów, test save/load
- ⬜ **Testy wydajności** — Target: 60 FPS z 50+ entities na mobile
- ⬜ **Optymalizacja mobilna** — Draw call batching, object pooling (pociski, wrogowie)
- ⬜ **Auto-Save mid-wave** — NOTIFICATION_APPLICATION_PAUSED → autopauza + zapis stanu gry
- ⬜ **Testy cyklu życia apki** — Minimalizowanie, połączenie, powiadomienia, low RAM kill → graceful recovery
- ⬜ **Beta-testy** — APK do wybranych graczy, zbieranie feedbacku
- ⬜ **Naprawa bugów** — Iteracja na podstawie feedbacku beta
- ⬜ **Materiały marketingowe** — Screenshoty, trailer gameplay (30s), opis sklepu
- ⬜ **Wydanie v1.0** — Publikacja na Google Play
