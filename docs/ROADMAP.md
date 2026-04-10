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
- ✅ **Wybór stylu graficznego** — Placeholder _draw() circles → docelowo pixel art

---

## Faza 1 — Prototyp (MVP) ✅

> Cel: Grywalny prototyp z jedną postacią, jedną mapą i podstawową mechaniką walki.

👉 [Zadania Fazy 1](../../issues?q=is%3Aissue+label%3Aphase-1)

### 1.1 Ruch i sterowanie
- ✅ **System ruchu postaci** — Wirtualny joystick do sterowania oddziałem (mobile-first)
- ✅ **Kamera** — Śledzenie oddziału gracza z widokiem z góry (zoom 1.5×)
- ✅ **Kolizje** — System kolizji ze środowiskiem (walls, debris) + warstwy kolizji

### 1.2 Walka
- ✅ **System strzelania** — Auto-aim z predictive aiming + orbitująca broń (WeaponPivot)
- ✅ **Typy broni (podstawowe)** — Karabin (szybki ogień), Strzelba (5 pocisków), Pistolet (precyzja)
- ⬜ **Nowe typy broni** — SMG (bardzo szybki ogień, niski DMG), Sniper Rifle (wolny, wysoki DMG, duży range), Granatnik ręczny (AoE, wolny, splash)
- ✅ **System obrażeń** — HP, obrażenia, śmierć, flash damage, Simple Health Bar addon
- ✅ **Wrogowie (podstawowi)** — 3 typy: Grunt, Rusher, Tank z AI (dążenie do gracza)

### 1.3 Mapa i fale
- ✅ **Generowanie areny** — Arena z losowymi przeszkodami (debris)
- ✅ **System fal** — Spawning w falach o rosnącej trudności (+15% stats/fala)
- ✅ **Warunek zwycięstwa/przegranej** — Przetrwanie 5 fal lub śmierć → Game Over z restartem

---

## Faza 2 — Systemy bazowe ✅

> Cel: Dodanie kluczowych systemów: loot, sklep, klasy żołnierzy.

👉 [Zadania Fazy 2](../../issues?q=is%3Aissue+label%3Aphase-2)

### 2.1 System lootu
- ✅ **Drop z wrogów** — Wrogowie upuszczają złoto po śmierci (skalowane per fala)
- ✅ **Zbieranie przedmiotów** — Automatyczne z 0.3s opóźnieniem (widoczny drop)
- ⬜ **Rzadkie skrzynki (Crate Drop)** — Bossowie i elitarni wrogowie (5-10% chance) dropują skrzynki z losową nagrodą: pasywka / broń wyższego tieru / bonus gold. Auto-pickup, floating text reward
- ✅ **Inwentarz** — System inventory w GameManager, śledzenie pasywnych przedmiotów, wyświetlanie w STATS

### 2.2 Sklep między falami
- ✅ **Interfejs sklepu** — UI z ScrollContainer, sekcje REKRUTACJA + SKLEP, przycisk DALEJ
- ✅ **Asortyment** — Bronie, pancerz, apteczki + wyszarzanie posiadanych broni
- ✅ **Ekonomia** — Zwiększone dropy złota, bonus za falę (25+15×wave), obniżone ceny sklepu, luck-based gold bonus
- ⬜ **Reroll asortymentu** — Przycisk odświeżenia oferty pasywek za złoto (koszt rosnący: 10→20→40)
- ⬜ **Banish przedmiotów** — Trwałe usunięcie itemu z puli runu (`item_pool.erase()`), max 3 banishe per run

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
- ⬜ **Rozszerzenie puli pasywek (12→16)** — Apteczka Polowa (heal co 10s), Tarcza Kinetyczna (block 1 hit co 15s), Celownik Laserowy (+crit chance), Plecak Taktyczny (+1 slot pasywny), Buty Szturmowe (+speed po killu na 3s), Maska Gazowa (immune na AoE 50%), Zapalnik (+fire DoT do pocisków), Lornetka (+vision range)
- ✅ **Synergie (proste)** — 3 tagi (Szybkość/Obrona/Ofensywa), bonus za 3+: unik 10% / armor -3 / +15% DMG
- ✅ **Panel ekwipunku** — StatsPanel z siatką pasywek, kolorami, synergami + sklep z rotującymi ofertami
- ⬜ **Tiery broni (I→V)** — `tier: int` w WeaponData, mnożnik statów: Common ×1.0 (⬜biały) → Uncommon ×1.25 (🟩zielony) → Rare ×1.5 (🟦niebieski) → Epic ×1.85 (🟪fioletowy) → Legendary ×2.25 (🟨złoty). Wyższe tiery w sklepie od późniejszych fal + drop ze skrzynek
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
- ⬜ **Screen shake** — Przy eksplozjach, śmierci, atakach bossów
- ⬜ **Damage numbers** — Floating numbers (żółte normalne, czerwone crit, duże boss damage)
- ⬜ **Hit stop / hit flash** — Krótkie freeze-frame na zabójstwo wroga
- ⬜ **Particle effects** — Muzzle flash, bullet trails, explosion particles, loot sparkle
- ⬜ **Kill streak / combo** — Wizualny feedback za szybkie zabijanie (np. „×10 KILL STREAK!")
- ⬜ **Camera zoom pulse** — Subtelny zoom na dużych eventach (boss spawn, wave clear)

### 4.2 Art i animacje
- ⬜ **Sprite'y postaci** — Pixel art sprity żołnierzy (per klasa, idle/walk/shoot/death)
- ⬜ **Sprite'y wrogów** — Pixel art sprity wrogów + bossów
- ⬜ **Tilemapy tematyczne** — Unikalne zestawy kafelków per arena (dżungla/pustynia/bunkier)
- ⬜ **UI skin** — Spójny military/industrial pixel art theme
- ⬜ **Kontrastowy outline** — CanvasItem shader: biały outline gracz, czerwony bossy
- ⬜ **Zarządzanie paletą barw** — Kontrastowe pociski wrogów vs tło areny

### 4.3 Dźwięk
- ⬜ **SFX walki** — Strzały (per broń), eksplozje, trafienia, śmierć
- ⬜ **SFX UI** — Zakup, level-up, wave start/clear, loot pickup
- ⬜ **Muzyka** — Menu, walka (inna per arena), boss fight, zwycięstwo/porażka
- ⬜ **Dynamiczny mix** — Muzyka intensywniejsza w późnych falach

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
- ⬜ **Fat finger friendly** — Przyciski min 48×48px, duże panele, wybaczające hitboxy
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
