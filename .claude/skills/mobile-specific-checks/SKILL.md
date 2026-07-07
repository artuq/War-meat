# mobile-specific-checks/SKILL.md
# Load when: analizujesz mobile QA, planujesz release na Google Play
# Skip when: pracujesz nad mechanikami gameplay (genre-related)

## Mobile-only concerns które nie istnieją w PC games

Te rzeczy musimy testować bo jesteśmy mobile-first (Android). Klasycznie ignorowane
w gatunkach typu Brotato (głównie PC), ale dla nas KLUCZOWE.

## 1. Interruption handling — przerwy w sesji

**Co się dzieje gdy:**
- Połączenie telefoniczne przerywa grę?
- SMS / push notification przychodzi?
- Alarm odpala się?
- Użytkownik wciska Home → wraca do gry?
- Bateria pada do 5% i system pokazuje alert?

**Reguły dla War-Meat:**
- Gra MUSI auto-pause gdy app idzie do background
- Stan MUSI zapisać się (save mid-run automatyczny)
- Po powrocie: pause menu z "Resume" jasny i widoczny
- Wave timer NIE może się resetować

**Test:**
```bash
# Symulacja w Godot:
# 1. Uruchom grę
# 2. Wciśnij Cmd+H (macOS) / Home button (mobile)
# 3. Wróć do okna gry
# Oczekiwane: pause menu lub state zachowany
```

## 2. Battery / Resource consumption

**Czerwone flagi:**
- Bateria spada > 15%/h podczas grania
- Telefon nagrzewa się powyżej 40°C
- App pożera > 500 MB RAM
- CPU usage > 50% w idle (menu)

**Diagnostyka:**
- Godot debug overlay: F8 = monitor performance
- Android `adb shell dumpsys batterystats`
- Co mogłoby drenować: nieczyszczone particles, unbounded queue_free, leaki Tween

**Reguły dla War-Meat:**
- Brak `_process` na node'ach niepotrzebnie aktywnych w menu
- Particles `one_shot=true` zawsze
- Tween.kill() przed nowym tween
- Pause emituje physics_process(false) globalnie

## 3. Network behavior — choć nie multiplayer

War-Meat to single-player, ale **inicjalny download/install** wymaga sieci:
- Wi-Fi → bez sieci: gra startuje OK
- Wifi → 3G podczas grania (na razie unrelevant, ale kiedyś leaderboard?)
- Brak sieci podczas Play Store update — czy app może odzyskać?

## 4. Storage permissions / app sandbox

**Google Play wymaga:**
- Zapis tylko w `user://` (Godot scope) — odpowiada `/Android/data/com.warmeat/files/`
- Brak zapisu w `/sdcard/` bez special permission
- Brak czytania zdjęć/kontaktów (nie potrzebujemy)
- Crash report — czy nie wysyłamy bez zgody?

**Reguły dla War-Meat:**
- `SaveManager` używa tylko `user://` paths ✓
- `tests/screenshots/` w `res://` — DEV only, nie w production build
- AndroidManifest.xml — sprawdź `<uses-permission>` które są niepotrzebne

## 5. Touch input quirks

**Mobile-specific bugi:**
- "Ghost tap" — przypadkowy dotyk gdy palec opiera się o ekran
- Multi-touch: 2 palce naraz (joystick + przycisk) działa?
- Edge swipes (system back gesture) NIE może triggerować akcji gry
- Pinch zoom — czy nie psuje viewport gry

**Reguły dla War-Meat:**
- Floating joystick wykrywa pojedynczy palec ✓ (zaimplementowane)
- Co jeśli palec lewy NA joysticku + palec prawy NA pause button?
- Czy `gui_input` w shop nie blokuje system gesture'ów?

## 6. App Store / Google Play compliance

**Content rating (Pegi/ESRB):**
- War-Meat ma kreskówkową przemoc → PEGI 7 / ESRB E10+
- Brak in-app messaging → niżej rating
- Brak in-app purchases (na razie) → niżej

**Tech requirements:**
- Target SDK = aktualny (API 34 / Android 14 obecnie)
- 64-bit support obowiązkowy od 2019
- App Bundle (.aab) zamiast .apk od 2021
- Privacy policy URL wymagany jeśli zbierasz cokolwiek (analytics, crash reports)

**Reguły dla War-Meat (release prep):**
- [ ] Privacy policy URL (nawet jeśli "no data collected")
- [ ] Content rating questionnaire wypełniony
- [ ] App icon w wszystkich wymaganych rozmiarach (48, 72, 96, 144, 192px)
- [ ] Screenshoty Play Store (2-8 sztuk, każdy 320-3840px wide)
- [ ] Feature graphic (1024×500)
- [ ] Krótki opis (80 char) + długi opis (4000 char)

## 7. Performance benchmarks (target: low-end Android)

| Metryka | Target (Pixel 6) | Min (Galaxy A13) |
|---|---|---|
| FPS średnie | 60 | 30 |
| FPS minimum | 45 | 24 |
| Memory | < 256MB | < 384MB |
| Cold start | < 3s | < 5s |
| APK size | < 30MB | < 50MB |
| Battery | < 5%/h | < 10%/h |

## 8. Co JA mogę wykryć ze screenshotów + state JSON

| Mobile bug | Czy widać w screen+state? |
|---|---|
| Interruption pause | Częściowo: pause menu screenshot |
| Battery drain | NIE — wymaga real device |
| Touch quirks | NIE — wymaga real device |
| Storage permissions | Częściowo: sprawdzić code |
| Compliance | NIE — manual review |
| FPS na real device | Częściowo: state JSON może mieć fps_target |

## Coverage matrix po dodaniu mobile checks

| Concern | Mamy? | Notatki |
|---|---|---|
| Interruption handling | ❌ | Wymaga real device test |
| Battery monitoring | ❌ | Wymaga adb / Android Studio |
| Touch input edge cases | ❌ | Wymaga real touch |
| Storage permissions | 🟡 | Code review tylko |
| Google Play compliance | ❌ | Pre-release checklist |
| Performance per device | ❌ | Wymaga Firebase Test Lab |

**Wniosek:** Dużo z tych rzeczy wymaga real Android device, którego nie mamy w current setup.  
**Sugestia:** Firebase Test Lab — testuje na realnych telefonach w chmurze Google.
