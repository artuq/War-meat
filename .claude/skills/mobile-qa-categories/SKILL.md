# mobile-qa-categories/SKILL.md
# Load when: analizujesz pełen run, planujesz coverage, robisz release-readiness check
# Skip when: debugujesz konkretny bug

## 9-kategoryjna profesjonalna ramka QA (industry standard)

Adaptowane z mobile QA best practices. Każda kategoria = oddzielna domena testów.
Dla każdej znaj **kluczowe pytania** i **co wykrywać**.

### 1. Setup / Environment

**Pytania:**
- Czy gra instaluje się bez błędów na świeżej instalacji?
- Czy uninstall usuwa wszystkie pliki (no leftover w `user://`)?
- Czy ustawienia (volume, joystick sensitivity) zachowują się po restarcie?
- Czy save folder tworzy się poprawnie?

**Co testować w War-Meat:**
- `user://settings.json` — czy się zapisuje
- `user://save.json` — czy mid-run save działa
- Co jeśli aplikacja zamknięta w trakcie wave?
- Co jeśli SaveManager.load_run() trafia na uszkodzony JSON?

### 2. Functional Testing

**Pytania:**
- Czy każda akcja gracza działa (ruch, strzał, interakcja)?
- Czy collision detection działa — nie przebija przez ściany?
- Czy save/load gry działa w 100%?
- Czy gracz może "zbreakować" grę przez nieoczekiwane akcje?

**Co testować w War-Meat:**
- Squad nie przechodzi przez ściany areny
- Strzelanie w 4 kierunkach
- Wave transition działa
- Shop close podczas pauzy gry
- Co jeśli wszyscy żołnierze zginą w trakcie shopa?

### 3. UX / UI

**Pytania:**
- Czy menu są jasne, przyciski podświetlają się?
- Czy działa na różnych rozdzielczościach?
- Czy tooltips są intuicyjne?
- Czy error messages pojawiają się kiedy trzeba?
- Czy keyboard/controller nawigacja jest płynna? (dla nas: TYLKO touch)

**Co testować w War-Meat:**
- Czy menu główne wygląda OK w portrait/landscape?
- Czy 📊 toggle stats panel działa w 100%?
- Czy hover/touch na karcie sklepu pokazuje stats?
- Co się dzieje gdy gracz tapnie 10× w shop button szybko?

### 4. Graphics / Audio / Visuals

**Pytania:**
- Czy tekstury są ostre, brak missing assets?
- Czy animacje są płynne, transitions OK?
- Czy efekty cząsteczkowe (eksplozje, dust) nie laggują?
- Czy SFX synchronizują się z gameplay?
- Czy muzyka się loopuje, volume sliders, mute działają?

**Co testować w War-Meat:**
- Sprite fringing (białe halo) — sprawdzaj na ciemnym tle
- Animacja śmierci wroga — czy wszystkie frames się pokazują
- Czy `flash_amount` shader resetuje do 0 po hit
- Czy `play_weapon_sfx` synchronizuje z `_shoot_at` muzzle flash

### 5. Performance / Stability

**Pytania:**
- FPS pod różnymi obciążeniami?
- Spadki FPS w heavy action (40+ wrogów)?
- Stress test długie sesje (30 min)?
- Memory leaks lub spikes?
- Jak gra wraca po crash/network interruption?

**Co testować w War-Meat:**
- FPS przy spawn 100 wrogów (boss wave)
- Memory po 5 wave cycles
- Czy spawn_telegraph particles są czyszczone
- Czy zombie LootDrops znikają po wave end

### 6. Localization / Text

**Pytania:**
- Wszystkie stringi przetłumaczone i wyświetlają się?
- Czy tekst mieści się w UI (no clipping/overflow)?
- Czy fonty czytelne, styl konsystentny?
- Czy interpunkcja, gramatyka, special chars OK?
- Czy zmiana języka działa bez restartu?

**Co testować w War-Meat (PL):**
- Czy polskie znaki (ą, ł, ć, ż, ź, ó, ę, ń, ś) renderują się w fontach?
- Czy długie napisy ("Snajperskie celowniki +12% zasięgu") nie obcinają się?
- Czy wszystkie UI mają polskie tłumaczenia (brak "TODO_TRANSLATE")?

### 7. Compatibility

**Pytania:**
- Różne OS, drivery, GPU?
- Różne rozdzielczości, fullscreen/windowed?
- Mobile: różne urządzenia, wersje Androida?
- Controller support (dla nas: N/A, tylko touch)?
- Performance na low-end i high-end hardware?

**Co testować w War-Meat:**
- Android 9 (min API 28?) vs Android 14
- Pixel 6 (high-end) vs Samsung Galaxy A13 (low-end)
- Aspect ratio 16:9, 19.5:9, 20:9
- Pierwsze uruchomienie po Play Store install

### 8. Regression Testing

**Pytania:**
- Po każdym fixie — czy bug zniknął I nie wprowadził nowych?
- Czy okoliczne systemy działają?
- Czy regresja jest iteracyjna (nie czekaj do końca)?

**Co testować w War-Meat:**
- Po każdej zmianie w enemy.gd → re-test combat, separation, knockback
- Po zmianie wave_data.tres → re-test progresji wave 1-5
- Każdy fixed bug → test który go reprodukuje w `tests/unit/test_regression_*.gd`

### 9. Release Readiness

**Pytania:**
- Zgodność z Play Store / App Store guidelines?
- Pakowanie — no debug files leftover?
- Wersjonowanie i changelog OK?
- Brak krytycznych bugów?
- Submission docs (icons, screenshots, trailers) gotowe?

**Co testować w War-Meat (Google Play):**
- Privacy policy URL podany?
- Content rating (PEGI/ESRB) odpowiedni?
- APK size < 50MB (warning) / < 100MB (max base)?
- Build target SDK = aktualny (Android 14)?
- `--debug` build wycięty z release APK?

## Coverage Matrix dla War-Meat

| Kategoria | Coverage obecnie | Brakuje |
|---|---|---|
| 1. Setup | 30% | uninstall test, settings persistence |
| 2. Functional | 70% | edge cases, "break the game" |
| 3. UX/UI | 50% | rapid-tap stress, all aspect ratios |
| 4. Graphics/Audio | 60% | particle cleanup, SFX sync |
| 5. Performance | 40% | long session, memory leak |
| 6. Localization | 10% | polish chars, text overflow audit |
| 7. Compatibility | 0% | only tested on Mac/Godot editor |
| 8. Regression | 80% | każdy fix ma test |
| 9. Release | 0% | nie zaczęliśmy Play Store flow |

## Jak używać

Przy analizie pełnego runu, **systematycznie przejdź przez 9 kategorii**.  
Dla każdej zapytaj: "czy coś z tego widać/nie widać w tym runie?"  
Nie wszystko da się sprawdzić z auto-runu (np. uninstall) — wskaż takie luki.
