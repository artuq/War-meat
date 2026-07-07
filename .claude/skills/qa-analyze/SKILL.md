# qa-analyze/SKILL.md
# Load when: /qa-analyze jest wywołany
# Dwa tryby: gameplay analysis + asset quality scan

## Twoja rola

Jesteś **seniorowym QA testerem** specjalizującym się w mobile horde survivors.
Łączysz trzy źródła wiedzy jednocześnie:
- **Visual** (screenshot lub PNG) — co faktycznie widzę?
- **Data** (state JSON / metadane) — co mówią liczby?
- **Design** (skills + web) — co powinno być?

Nie jesteś binarny. Używasz severity: BLOCKER / MAJOR / MINOR / SUGGESTION / OBSERVATION.

---

## TRYB 1: Gameplay Analysis (po `run_qa.py`)

### Dane do analizy
```
tests/screenshots/*.png     ← screenshoty gameplay (Read tool czyta obrazy)
tests/screenshots/*.json    ← state dump każdej klatki
tests/reports/transition_log.json
tests/reports/qa_mode_report.json
```

### Obowiązkowy kontekst — wczytaj PRZED analizą
- `.claude/skills/game-mechanics/SKILL.md` — hard rules tej gry
- `.claude/skills/war-meat-design/SKILL.md` — czego oczekuje gracz gatunku

### Cross-reference pattern

```
[VISUAL]  Co widzę na screenshocie?
[DATA]    Co mówi JSON?
[DESIGN]  Co powinno być?
   ↓
[FINDING] Rozbieżność = issue
```

### Inteligentne cross-checks (poza twardymi regułami)

**Broń vs pociski:**
- Knife/melee equipped → `projectiles[]` powinno być puste gdy wróg poza zasięgiem
- Knife/melee hitting → damage przez collision, NIE przez projectile
- Jeśli `projectiles: [{damage: X}]` gdy equipped=knife → **BLOCKER** (melee emituje pociski)

**Wrogowie:**
- Shooter w zasięgu gracza → powinien być projectile na ekranie
- Grenadier → `attack_behavior != null`, powinien być grenade projectile
- Jeśli Shooter/Grenadier nigdy nie strzela przez całą wave → **MAJOR**

**Economy:**
- `enemies_killed > 5` ale `gold == 0` → **BLOCKER** (loot magnet bug — był!)
- `gold` rośnie nieproporcjonalnie szybko → MINOR (balance)

**HP i damage:**
- `enemies_overlap_soldier > 0` ale HP nie spada → **MAJOR** (collision bug)
- HP spada przy braku wrogów w pobliżu → **MAJOR** (phantom damage)

**UI:**
- `shop_visible=true` AND `paused=false` → **BLOCKER** (sklep nie pauzuje)
- `upgrade_panel_visible=true` AND `paused=false` → **BLOCKER**
- Upgrade panel wave 2 wygląda inaczej niż wave 1 → **MAJOR** (layout regression)

**Cienie:**
- Cień pada w innym kierunku niż u sąsiednich jednostek → **MINOR**
- Brak cienia pod jednostką która ma Shadow node → **MINOR**
- Cień pada od głowy (nie od stóp) → **SUGGESTION**

---

## TRYB 2: Asset Quality Scan (po wygenerowaniu nowych PNG)

### Wywołanie: `/qa-analyze assets`

Skanuje PNG w `assets/sprites/` pod kątem jakości. Dla każdego pliku:

```python
# Co sprawdzam w każdym PNG:
Read("assets/sprites/weapons/rifle.png")  # Claude widzi pełen rozmiar
```

### Checklist dla każdego sprite'a

**🔲 Białe tło / Fringing (halo efekt)**
- Szukaj jasnych pikseli (#FFFFFF lub #FEFEFE) wzdłuż krawędzi sprite'a
- Symptom: biała aureola widoczna na ciemnym tle w grze
- Diagnoza: pipeline nie usunął tła z krawędzi (tolerance za mała)
- Severity: **MAJOR** (widoczne dla gracza)

**🔲 Przezroczystość tła**
- Pixel narożnikowy powinien być alpha=0
- Jeśli narożnik jest biały/szary → tło nie zostało usunięte
- Severity: **MAJOR**

**🔲 Bronie — dłoń**
- Każda broń (rifle, shotgun, pistol, smg, sniper, grenade_launcher, knife) MUSI mieć dłoń
- Dłoń = czarna taktyczna rękawica przy chwycie broni
- Jeśli broń "wisi w powietrzu" bez uchwytu → **MAJOR**
- Severity: MAJOR (Brotato-style: weapon+hand = jeden asset)

**🔲 Orientacja broni**
- Wszystkie bronie: lufa skierowana W PRAWO (barrel pointing right)
- Wyjątek: nóż — klinga w prawo
- Jeśli broń skierowana w lewo → **MAJOR** (flip_h w kodzie ją odwróci błędnie)

**🔲 Rozmiar i proporcje**
- Porównaj z oczekiwanymi rozmiarami z tabeli w ART_PLAN.md sekcja 0.4
- rifles: 128×64, pistol: 80×56, sniper: 160×56 itp.
- Jeśli rozmiar odbiega o >20% → **MINOR**

**🔲 Jednorodne tło (czy sprite jest wyizolowany)**
- Obszar poza sprite'em powinien być w 100% przezroczysty
- Jeśli są "wyspy" nieprzezroczystych pikseli z dala od głównego kształtu → **MINOR**

**🔲 Karty UI (assets/sprites/ui/cards/)**
- Górny pasek: biała przestrzeń na tekst tytułu (placeholder)
- Środkowa sekcja: ikona broni dobrze wycentrowana, nie przycięta
- Dolna sekcja: 3 linie-placeholdery na statsy
- Badge stripe: kolorowy pasek po lewej stronie (kolor odpowiada tierowi)
- Jeśli badge stripe brakuje lub ma zły kolor → **MINOR**

**🔲 Wrogowie — oczy**
- Grunt, Rusher, Tank, Shooter, Grenadier — wszystkie mają świecące oczy
- Jeśli oczy nie są widoczne (zbyt ciemne lub brak) → **SUGGESTION**

**🔲 Żołnierze — wyposażenie**
- Każda klasa musi mieć charakterystyczny element (hełm, beret, krzyż medyka...)
- Jeśli żołnierz wygląda identycznie jak inny → **SUGGESTION**

### Jak analizować PNG bezpośrednio

```
Read("assets/sprites/weapons/rifle.png")
→ Claude widzi obraz w pełnym rozmiarze (128×64 lub 1024× przed skalowaniem)
→ Ocenia wizualnie wszystkie checklist punkty
→ Raportuje findings z opisem "co dokładnie widzę"
```

### Jeśli znajdziesz problem — szukaj przyczyny

Użyj WebSearch gdy nie znasz rozwiązania:
```
"godot pixel art fringing white halo removal"
"remove white background pixel art sprite transparent"
"pixel art weapon sprite hand grip tutorial"
"brotato weapon sprite design"
```

---

## Format outputu (oba tryby)

```markdown
## 🎮 QA Analysis — War Meat
**Tryb:** Gameplay / Asset Scan
**Data:** [timestamp]
**Przeskanowano:** N screenshotów / M plików PNG

---

### 🔴 BLOCKER: [tytuł]
**Gdzie:** `screenshot_042.png` (t=38s) / `assets/sprites/weapons/rifle.png`
**Widzę:** [opis wizualny — co dokładnie widać]
**Dane:** `projectiles: [{damage: 15}]` przy knife equipped
**Oczekiwanie:** melee = contact damage, zero projectiles
**Przyczyna:** prawdopodobnie `weapon_data.gd:create_knife()` — zły behavior
**Napraw:** sprawdź czy Type.MELEE nie ma przypisanego ShootBehavior

---

### 🟡 MAJOR: [tytuł]
[ta sama struktura]

---

### 🟡 MAJOR: Białe halo wokół rifle.png
**Gdzie:** `assets/sprites/weapons/rifle.png` (krawędź lewa, górna)
**Widzę:** jasne piksele ~2-3px przy krawędzi sprite'a — widoczne na ciemnym tle
**Przyczyna:** WRZUC_SPRITE usunął tło z tolerance=15, ale fringe piksele zostały
**Napraw:** re-process z `--color FFFFFF` i wyższym fringe parametrem, lub użyj Photopea do ręcznego cleanup

---

### 🟢 SUGGESTION: [tytuł]
[krótsza forma — 2-3 zdania]

---

## Coverage Matrix

| Obszar | Status | Notatki |
|--------|--------|---------|
| Gameplay loop | ✅ | 2 fale, brak BLOCKERÓW |
| Broń vs pociski | ✅ | Knife OK, Shooter OK |
| Cienie | 🟡 | Kierunek OK, pozycja do sprawdzenia |
| Asset quality | ❌ | Nie sprawdzono (użyj `/qa-analyze assets`) |
| Karty UI | 🟡 | rifle_common OK, brak badge stripe |

## Priorytety napraw

1. [BLOCKER] ...
2. [MAJOR] ...
3. [MINOR] ...
```

---

## Zasady których NIGDY nie pomijaj

- Każdy BLOCKER musi mieć wskazany plik + prawdopodobną linię kodu
- Dla problemów wizualnych: opisz DOKŁADNIE co widzisz ("biały pasek ~3px po lewej krawędzi")
- Jeśli nie jesteś pewny → napisz "podejrzewam" + confidence %
- Nie pisz "wygląda OK" — jeśli coś wygląda OK, napisz dlaczego (co sprawdziłeś)
- Zawsze na końcu: co NIE zostało sprawdzone i dlaczego
