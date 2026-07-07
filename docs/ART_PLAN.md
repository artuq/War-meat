# 🎨 WAR MEAT — Art Plan (High-res Pixel Art / Modular)

> Podejście: **Modular sprite + procedural animation**
> Zero tradycyjnych animacji klatkowych. Pojedyncze statyczne sprite'y + Tween/kod w Godocie.
> Referens: **Enter the Gungeon, Dead Cells**, Brotato, Vampire Survivors

---

## 0. Style Upgrade — High-res Pixel Art (kwiecień 2026)

> 🆕 **Zmiana stylu**: porzucamy nierealistyczne 16×16 (AI nie potrafi tego generować natywnie) na rzecz **High-res Pixel Art** — sprite'y rysowane w wysokiej rozdzielczości (128 px bazowe), z zachowaną estetyką pikselową (flat fill, ostre krawędzie, paleta), ale z miejscem na detal: rzemienie, śruby, faktura tkaniny, wyraziste kontury.

### 0.1 Filozofia stylu

- **Source resolution**: 128×128 dla bazowej postaci gracza (8× względem starego 16×16).
- **Game render**: Godot skaluje sprite'y przez `VISUAL_SCALE = 0.5` ustawiane na Sprite2D per-soldier w kodzie (nie na root node — żeby nie skalować kolizji). 128 px source → 64 px na ekranie. Tekstury importowane z **Texture Filter: Linear** dla płynnej rotacji (movement wobble, recoil) bez schodków.
- **Detal a piksele**: w 128 px mieści się ~5–8 razy więcej "informacji" niż w 16 px — używamy tego na detale militarne (paski na hełmie, naszywki, łuski na pancerzu, fałdy munduru), ale **zachowujemy flat shading**: max 3 odcienie na element (highlight + base + shadow), zero gradientów.
- **Widok (CRITICAL)**: **Near front-facing 3/4 view angled slightly to the right (Brotato-style)**. Postać patrzy na gracza, lekko skręcona w prawo. Oba ramiona/barki widoczne. Twarz widoczna (oba oczy). To idealna baza pod **360° auto-aim** — broń może obracać się dookoła bez zmiany pozy postaci. **NIE side profile (Gungeon), NIE pełny front, NIE isometric.** Wrogowie i bossowie mają ten sam 3/4 view (patrzą na gracza), bronie zostają side view (orbitują w `WeaponPivot`, niezależnie od body).
- **Estetyka**: **Enter the Gungeon meets Brotato** — chibi proporcje, ostre piksele, czytelna sylwetka, nasycone kolory militarne.

### 0.2 Workflow generacji (Imagen 3 — PNG + image conditioning)

## 0.1 Ustawienia Nano Banana Pro — tabela referencyjna

| Typ assetu | Model | Aspect Ratio | Resolution | Image Reference |
|-----------|-------|-------------|------------|-----------------|
| Żołnierze (body) | Nano Banana Pro | **1:1** | **1K** | Brak (Assault = wzorzec) / Assault.png |
| Wrogowie | Nano Banana Pro | **1:1** | **1K** | Grunt.png lub Assault.png |
| Bossowie | Nano Banana Pro | **1:1** | **1K** | Tank.png |
| Bronie | Nano Banana Pro | **4:3** | **1K** | Karabin.png |
| Pociski (std) | Nano Banana Pro | **16:9** | **1K** | — |
| FX, splaty, loot | Nano Banana Pro | **1:1** | **1K** | — |
| Karty shop/upgrade | Nano Banana Pro | **3:4** | **1K** | rifle_common.png |
| Karty rekrutów | Nano Banana Pro | **3:4** | **1K** | rifle_common.png + Assault.png |
| Cutscenki (tło) | Nano Banana Pro | **16:9** | **1K** | — |
| Tile'e terenu | Nano Banana Pro | **16:9** | **1K** | — |

> ⚠️ **Zawsze**: output z AI Studio = JPG z białym tłem → przeciągnij na WRZUC_SPRITE → gotowe.
> ⚠️ **Nie zmieniaj** liczby kroków (steps) ani CFG — defaulty działają najlepiej.
> ⚠️ **Liczba obrazów**: generuj **4 naraz** i wybierz najlepszy.

---

> **Zasada**: Generujemy PNG sprite'y przez **Nano Banana Pro** (`gemini-3-pro-image-preview`) w Google AI Studio.
> Spójność stylu zapewniamy przez **image conditioning** — pierwszy wygenerowany sprite dołączamy jako obraz-wzorzec do każdego kolejnego promptu.
>
> **Dlaczego to działa?**
> — Nano Banana Pro widząc obraz referencyjny **kopiuje styl** — grubość outline'u, proporcje chibi, flat shading
> — `palette_enforcer.py` (już w projekcie) normalizuje kolory hex po generacji → eliminuje dryfowanie palety
> — Brak problemów z SVG (Gemini tekstowy generował front-view zamiast side view)

1. **Generuj sprite wzorcowy** (Assault) w AI Studio — bez obrazu ref:
   - Nano Banana Pro, aspect ratio **1:1**, resolution **1K**
   - Użyj promptu Assault z sekcji 1.1. Model zwróci **JPG 1024×1024 z białym tłem** — to prawidłowe.
2. **(Opcjonalnie) Ręczna korekta** w Photopea (https://photopea.com) jeśli mimo nowego promptu nadal widać szczątkowe kształty rąk:
   - Otwórz JPG → gumka (Eraser, E) → usuń artefakty → Plik → Zapisz jako → JPG
   - Powinno być **rzadko potrzebne** — nowe prompty z "Brotato body prop" i "ZERO skin pixels below chin" eliminują problem u źródła
3. **Przetwórz** (drag-and-drop): Przeciągnij JPG na `tools/dist/WRZUC_SPRITE.exe`
   - Automatycznie: waliduje rozmiar (ostrzeże jeśli nie 1024×1024) → usuwa białe tło `#FFFFFF` → snapuje paletę WAR MEAT → resize do 128×128 → zapisuje `assets/sprites/soldiers/Assault.png`
4. **Każdy kolejny sprite** — w AI Studio:
   - Kliknij ikonę "attach image" → załaduj przetworzone `Assault.png` jako obraz referencyjny
   - Prompt z sekcji 1.1 z prefiksem `"Generate in the EXACT same pixel art style as the reference image."`
5. **Repeat** drag-and-drop na `WRZUC_SPRITE.exe` dla każdego outputu
6. **Godot import**: `Texture Filter = Linear`, `Mipmaps = Off`, `Fix Alpha Border: true`

### 0.3 Format plików — PNG-first (SVG tylko geometryczne)

| Typ assetu | Format | Powód |
|------------|--------|-------|
| Postacie (body, wrogowie, bossowie) | **PNG** | Nano Banana Pro generuje raster — lepsza jakość postaci niż SVG XML |
| Bronie | **PNG** | Imagen 3 z image conditioning — spójny styl |
| ~~Hand~~ | ~~PNG~~ | ⚠ **DEPRECATED** — dłoń jest baked-in do sprite'ów broni (Brotato-style). `Hand.svg` pozostaje w repo jako legacy fallback. |
| Shadow, Shield Overlay | **PNG** | Generowane Nano Banana Pro — spójny styl pikselowy z postaciami |
| Loot (coin/crate/gem) | **PNG** | Generowane Nano Banana Pro — spójny styl pikselowy z resztą |
| UI ikony pasywek | **SVG** | Skalowalne wektory |
| FX (muzzle flash, splat, hit spark) | **PNG** 32–256 px | Miękki glow — raster wymagany |
| Tile'e terenu | **PNG** 64×64 px | Seamless textury — wymagany raster |
| UI ramki/panele/buttony | **PNG** 9-patch | Tekstura metaliczna z Imagena |

### 0.4 Tabela konwersji rozmiarów (16 → 128 base)

| Asset | Old (16-base) | **New (128-base source)** | Game scale | Screen size |
|-------|---------------|----------------------------|------------|-------------|
| Player body | 16×16 | **128×128** | **0.50** (VISUAL_SCALE w kodzie) | ~64 px |
| Hand | 4×4 | **32×32** (PNG) | **0.50** | ~16 px — deprecated (baked into weapons) |
| Shadow | 12×4 | **96×32** (PNG) | **0.50** | ~48×16 px |
| Grunt | 10×10 | **80×80** | 0.20 | ~16 px |
| Rusher | 8×8 | **64×64** | 0.20 | ~13 px |
| Tank | 14×14 | **112×112** | 0.20 | ~22 px |
| Shooter | 10×10 | **80×80** | 0.20 | ~16 px |
| Grenadier | 12×12 | **96×96** | 0.20 | ~19 px |
| Jungle Boss | 24×24 | **192×192** | 0.20 | ~38 px |
| Desert Boss | 24×24 | **192×192** | 0.20 | ~38 px |
| Bunker Boss | 28×28 | **224×224** | 0.20 | ~45 px |
| Shield overlay | 16×16 | **128×128** | 0.20 | ~26 px |
| Karabin | 16×6 | **128×64** | target_width=16 px | ~16 px szerokość |
| Pistolet | 10×5 | **80×56** | target_width=16 px | ~16 px szerokość |
| Strzelba | 14×7 | **112×72** | target_width=16 px | ~16 px szerokość |
| SMG | 12×5 | **96×56** | target_width=16 px | ~16 px szerokość |
| Sniper Rifle | 20×5 | **160×56** | target_width=16 px | ~16 px szerokość |
| Granatnik | 16×8 | **128×80** | target_width=16 px | ~16 px szerokość |
| Nóż | 10×4 | **80×48** | target_width=16 px | ~16 px szerokość |
| Bullet (std) | 4×2 | **32×16** | 0.20 | ~6×3 px |
| Bullet (crit) | 5×3 | **40×24** | 0.20 | ~8×5 px |
| Rocket | 6×4 | **48×32** | 0.20 | ~10×6 px |
| Sniper trail | 6×2 | **48×16** | 0.20 | ~10×3 px |
| Muzzle flash | 8×8 | **64×64** | 0.20 | ~13 px |
| Hit spark | 6×6 | **48×48** | 0.20 | ~10 px |
| Death splat | 16×16 | **128×128** | 0.20 | ~26 px |
| Death splat (boss) | 32×32 | **256×256** | 0.20 | ~51 px |
| Coin | 6×6 | **48×48** (SVG) | 0.20 | ~10 px |
| XP gem | 5×5 | **40×40** (SVG) | 0.20 | ~8 px |
| Crate | 10×10 | **80×80** (SVG) | 0.20 | ~16 px |
| **Tile floor** ⚠ | 16×16 | **64×64** (4× tylko) | 0.5 | 32 px na tile |
| **Tile wall** ⚠ | 16×16 | **64×64** (4× tylko) | 0.5 | 32 px na tile |
| UI panel BG | 48×48 | **192×192** (9-patch) | varies | varies |
| UI button | 96×32 | **384×128** | 0.5 | 192×64 px |
| UI card frame | 24×32 | **192×256** | 0.5 | 96×128 px |
| UI passive icon | 16×16 | **64×64** (SVG) | varies | varies |

> ⚠ **Tile'e**: NIE skalujemy 8× (zbyt duża waga VRAM przy ~30 tile'ach × powtórzenia). Tile'e idą **4×** (16→64). To nadal pozwala na Linear filtering bez szpetnego rozmycia.

### 0.5 Stan istniejących SVG (przed upgrade)

Istniejące assety pozostają jako tymczasowe placeholdery — będą **podmieniane na nowe wygenerowane sprite'y** w nowym stylu:

- ✅ `soldiers/` — Assault/Engineer/Heavy/Medic/Scout/Sniper/Hand/Shadow — wszystkie PNG zintegrowane
- ✅ `enemies/` — Grunt/Rusher/Tank/Shooter/Grenadier/boss_jungle/boss_desert/boss_bunker/shield_overlay — wszystkie PNG zintegrowane
- ✅ `weapons/` — rifle/pistol/shotgun/smg/sniper_rifle/knife/grenade_launcher — wszystkie PNG zintegrowane
- ✅ `loot/` — coin.png, crate.png — podmienione
- ✅ `projectiles/` — bullet_standard/bullet_crit/bullet_enemy/bullet_sniper/rocket — assety na miejscu
- ✅ `fx/` — death_splat/hit_spark/muzzle_flash/death_splat_boss — assety na miejscu
- ✅ `Panel BG.svg`, `Hand.svg` (geometryczne) — mogą zostać jako SVG

### 0.6 Godot import settings (per category)

```
# Wszystkie PNG sprite'y postaci/wrogów/broni/FX:
Texture Filter: Linear
Mipmaps: false
Compress Mode: Lossless
Fix Alpha Border: true

# Tile'e:
Texture Filter: Linear (lub Nearest jeśli wolisz "ostre" pixele tła)
Mipmaps: false
Compress Mode: Lossless

# UI 9-patch:
Texture Filter: Linear
Mipmaps: false
Compress Mode: Lossless
```

W kodzie: zamiast skalowania per Sprite2D, ustawić `scale` na rodzicu (np. `Soldier` node → `scale = Vector2(0.2, 0.2)`). Dzięki Linear filtering rotacja (wobble, recoil) będzie **gładka**, a nie pikselowa-schodkowa.

---

## Stan wyjściowy

~~Cała gra używa `_draw()` prymitywów (draw_circle, draw_arc, draw_line).~~
~~Zero shaderów, zero flip_h, zero logiki kierunku patrzenia.~~

**Aktualny stan (kwiecień 2026):**
- ✅ Outline shader (`assets/shaders/outline.gdshader`) — działa na żołnierzach
- ✅ Assault body SVG (`assets/sprites/soldiers/Assault.svg`) — podłączony, z fallback `_draw()`
- ✅ Hand SVG (`assets/sprites/soldiers/Hand.svg`) — podłączony
- ✅ Shadow SVG (`assets/sprites/soldiers/Shadow.svg`) — podłączony
- ✅ Grunt SVG (`assets/sprites/enemies/Grunt.svg`) — podłączony, z fallback `_draw()`
- ✅ Karabin SVG (`assets/sprites/weapons/Karabin.svg`) — jedyna broń z sprite'em
- ✅ Coin SVG (`assets/sprites/loot/coin.svg`) — istnieje plik
- ✅ Crate SVG (`assets/sprites/loot/crate.svg`) — podłączony w crate_drop
- ✅ Kenney UI Pack — `button_square_depth.png` używany w arena select
- ⬜ Reszta klas/wrogów/broni → fallback `_draw()`
- ⬜ Pociski, FX, bossowie, tilemapy, UI skin → brak sprite'ów

**Dostępne ale NIEPODŁĄCZONE asset packi:**
- 🔸 Kenney Top-Down Shooter (~500 tile'i, 9 postaci, 3 bronie)
- 🔸 Gun Collection (7 typów broni w PNG/SVG/AI — Bullet, Grenade, Melee, Pistols, Rifle, Shotgun, SMG, Snipers)

---

## 1. Budowa postaci — system modułowy

Każda jednostka (gracz i wróg) składa się z **oddzielnych warstw sprite'ów**, nie z jednego arkusza animacji.

### 1.1 Żołnierz gracza (6 klas × 3 sprite'y = 18 assetów)

| Warstwa | Ilość klatek | Rozmiar source | Format | Opis |
|---------|-------------|----------------|--------|------|
| **Body** | 1 na klasę | **128×128 px** | PNG | Statyczny tułów skierowany w prawo. Kolor/sylwetka unikalna per klasa. Detale: paski, śruby, fałdy. Generowane z Imagen 3 / Nano Banana Pro + image conditioning. |
| ~~**Hand**~~ | ~~1 wspólna~~ | ~~**32×32 px**~~ | ~~PNG~~ | ⚠ **DEPRECATED** — dłoń jest teraz generowana jako część sprite'a broni (Brotato-style). Oddzielny `Hand.svg` nie jest potrzebny. |
| **Shadow** | 1 wspólna | **96×32 px** | PNG | 🔄 Półprzezroczysty czarny owal pod postacią (generowany Nano Banana Pro). `modulate.a = 0.5` |

**Klasy do narysowania (body PNG, 128×128 px, w grze scale ~0.20):**
- ✅ Szturmowiec (Assault) — `Assault.png`
- ✅ Snajper (Sniper) — `Sniper.png`
- ✅ Medyk (Medic) — `Medic.png`
- ✅ Inżynier (Engineer) — `Engineer.png`
- ✅ Zwiadowca (Scout) — `Scout.png`
- ✅ Ciężki (Heavy) — `Heavy.png`

**🎨 KONCEPCJA ARTYSTYCZNA — WAR MEAT SAUSAGE SOLDIERS:**
> Żołnierze to kiełbasy. Nie wiedzą, że są kiełbasami. Służą Ojczyźnie z pełną powagą. Ton: **deadpan serious** — absolutnie zero puszczania oka do gracza. Każda kiełbasa nosi mundur z takim samym dostojeństwem jak generał. To jest ich normalność.
>
> **Anatomia kiełbasy-żołnierza:** Zamiast ludzkiego ciała — cylindryczny, lekko baryłkowaty korpus kiełbasy. "Głowa" to górna zaokrąglona część kiełbasy wystawająca ponad kołnierz kamizelki — brak szyi, brak ucha, dwa małe, poważne oczy wprost na powierzchni kiełbasy. Spodnia część korpusu zwęża się w wojskowe buty/spodnie. Wojskowy ekwipunek (hełm, kamizelka, plecak) siedzi na kiełbasie dokładnie tak samo jak na człowieku.

**🤖 Prompty Imagen 3 / Nano Banana Pro — Żołnierze (1:1, 1K, ~1024×1024 → downscale do 128×128):**

> **PREFIX ŻOŁNIERZ (SAUSAGE):** `2D game sprite, pixel art style, near front-facing 3/4 view angled slightly to the right (Brotato-style). Character looks towards the viewer but is oriented rightwards. NOT side profile, NOT pure front view, NOT isometric. Hard pixel edges, NO anti-aliasing. Dark navy outline 2px on all visible shapes. Flat shading: max 3 tones per element (highlight/base/shadow), NO gradients, NO soft shading. BODY CONCEPT — DEADPAN SERIOUS SAUSAGE SOLDIER: the character's entire body is a plump sausage (cylindrical, slightly barrel-shaped, smooth casing). The sausage wears full military gear completely seriously — this is perfectly normal in this world. SAUSAGE HEAD: the top rounded portion of the sausage casing protrudes above the vest/collar area — NO separate neck, NO human face shape. Two small round dark eyes (#1a1a2e, 3px each) sit side-by-side on the upper sausage surface, facing forward with a deadpan earnest expression. NO mouth, NO nose, NO eyebrows — just two serious beady eyes on smooth sausage casing. SAUSAGE BODY STRUCTURE: the sausage torso is covered by the tactical vest — vest shoulders extend wide, NO arms or hands visible (arms are separate game engine sprites). The bottom of the sausage tapers into stubby military trousers and boots. This is a Brotato-style body prop — NO weapon held, NO ground shadow, NO scene, NO floor. Background: FLAT SOLID WHITE #FFFFFF ONLY. Square 1:1 canvas. WAR MEAT palette (SAUSAGE ADDITIONS): frankfurter casing #e8a060 / sausage shadow #b86a30 / bratwurst tan #d49050 / weisswurst cream #e8d0a0 / smoked kielbasa #9a4a20 / chorizo red-brown #c06030 / MILITARY: olive uniform #5a6e3a / dark olive #3d4a28 / navy outline #1a1a2e / tactical gray #4a4a4a / steel #8c8c8c / mid gray #6b6b6b / gold detail #ffd700 / blue armor #2a4a7a / armor highlight #4a6e9e / brown wood #8b6914 / orange accent #e07020 / beret brown #a0845c / blue lens #4a9eff / red cross #cc0000 / white #ffffff.`
>
> **Assault — Frankfurter** (generuj BEZ obrazu referencyjnego — to wzorzec stylu): `[PREFIX ŻOŁNIERZ (SAUSAGE)] Assault class — a standard FRANKFURTER sausage soldier. Sausage casing: warm orange-pink (#e8a060 base, #b86a30 shadow on left side, #f0c090 highlight on right). Two small earnest dark eyes on upper sausage surface — completely deadpan. Round gray combat helmet (#6b6b6b + #4a4a4a shadow + #8c8c8c highlight) sits directly on top of the sausage — no head underneath, just helmet on sausage. Black chin strap (#1a1a2e) wraps the sausage. Olive military uniform torso visible behind dark tactical vest (#4a4a4a), both shoulder straps, 3-4 magazine pouches, thin strap lines (#1a1a2e). Small gold regiment patch (#ffd700). Olive pants (#5a6e3a + #3d4a28). Black boots (#1a1a2e). The sausage appears to take its military duties with complete seriousness.` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `soldiers` → resize **128**.
>
> **Sniper — Chorizo** (dołącz Assault.png jako image reference): `Generate in the EXACT SAME pixel art style, palette, outline thickness and sausage proportions as the reference image. [PREFIX ŻOŁNIERZ (SAUSAGE)] Sniper class — a lean CHORIZO sausage soldier, slightly more elongated than the Frankfurter. Sausage casing: reddish-brown (#c06030 base, #8a4020 shadow, #d08050 highlight) with subtle dark speckle texture on casing. Two small calculating eyes — still deadpan, but somehow convey focus. Flat soft beret (#a0845c + #6b5a3a shadow) sits directly on the rounded sausage top, small metal badge (#8c8c8c). Raised goggles resting on the sausage surface (gray frame #4a4a4a + blue lenses #4a9eff). Slim dark olive tactical vest (#3d4a28), bandolier strap diagonally across (#4a4a4a) with 5-6 brass bullet tips (#ffd700). Narrow olive pants (#5a6e3a). Black boots (#1a1a2e).` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `soldiers` → resize **128**.
>
> **Medic — Weißwurst** (dołącz Assault.png jako image reference): `Generate in the EXACT SAME pixel art style, palette, outline thickness and sausage proportions as the reference image. [PREFIX ŻOŁNIERZ (SAUSAGE)] Medic class — a pale WEISSWURST sausage soldier. Sausage casing: cream-white (#e8d0a0 base, #c0a870 shadow on left, #f5ecd0 highlight on right) — noticeably lighter/paler than other classes. Two small caring eyes on the pale sausage surface — deadpan but somehow conveying duty to heal. Round gray helmet (#6b6b6b + #4a4a4a shadow) with bold WHITE CROSS symbol on right side (#ffffff rectangles). Dark tactical vest (#4a4a4a) over the pale sausage. Large red cross patch on left vest front (#cc0000 cross on #ffffff background). Brown medical bag on right hip (#8b6914 + #6b5a14 shadow) with white cross. Olive pants (#5a6e3a). Black boots (#1a1a2e).` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `soldiers` → resize **128**.
>
> **Engineer — Kiełbasa Śląska** (dołącz Assault.png jako image reference): `Generate in the EXACT SAME pixel art style, palette, outline thickness and sausage proportions as the reference image. [PREFIX ŻOŁNIERZ (SAUSAGE)] Engineer class — a sturdy KIELBASA SLASKA sausage soldier, slightly wider and more practical-looking. Sausage casing: medium smoky tan (#d49050 base, #9a6020 shadow, #e0b070 highlight) with faint diagonal casing creases. Two small focused eyes — a sausage that has seen some things and fixed them. Gray combat helmet (#6b6b6b + #4a4a4a shadow) with thick ORANGE stripe (#e07020) across the top. Olive uniform (#5a6e3a) with tactical vest. Goggles hanging around the sausage neck-area (gray frame #4a4a4a + blue lenses #4a9eff). Tool belt on waist: wrench (#8c8c8c) and screwdriver (#8c8c8c + #8b6914 grip). Olive pants (#5a6e3a). Black boots (#1a1a2e).` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `soldiers` → resize **128**.
>
> **Scout — Parówka** (dołącz Assault.png jako image reference): `Generate in the EXACT SAME pixel art style, palette, outline thickness and sausage proportions as the reference image. [PREFIX ŻOŁNIERZ (SAUSAGE)] Scout class — a small slender COCKTAIL SAUSAGE / PAROWKA soldier, noticeably thinner and shorter than other classes. Sausage casing: pale pinkish-tan (#e8a060 lighter variant, #d09050 shadow, #f0c080 highlight) — smooth, minimal casing texture. Two small alert quick-darting eyes — the most alert sausage on the battlefield, still deadpan. Tactical headscarf/wrap (#3d4a28) tied tightly around the slim sausage top. Slim olive vest (#5a6e3a, minimal pouches, smooth silhouette). Small compact binoculars on chest strap (#4a4a4a body + #1a1a2e lenses). Olive pants (#5a6e3a) with kneepads (#4a4a4a). Black boots (#1a1a2e).` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `soldiers` → resize **128**.
>
> **Heavy — Bratwurst** (dołącz Assault.png jako image reference): `Generate in the EXACT SAME pixel art style, palette, outline thickness and sausage proportions as the reference image. [PREFIX ŻOŁNIERZ (SAUSAGE)] Heavy class — a massive BRATWURST sausage soldier, visibly fatter and wider than all other classes (~15% broader silhouette). Sausage casing: thick golden-brown bratwurst color (#d49050 base, #9a5a20 deep shadow, #e8c080 bright highlight) — slightly grilled-looking with subtle darker stripe on top surface. Two small stoic immovable eyes — this sausage has taken hits and will take more. Gray combat helmet (#6b6b6b + #4a4a4a shadow) with extra brow guard plate (#4a4a4a) on front — sits wide on the fat sausage. Thick blue armor plates (#2a4a7a + #4a6e9e highlight) bolted directly onto the sausage body — 6+ metal rivets (#8c8c8c). Heavy olive pants (#5a6e3a + #3d4a28). Heavy black reinforced boots (#1a1a2e).` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `soldiers` → resize **128**.

> **Hand (JPG z AI Studio → resize 32×32 PNG):** Generuj w AI Studio z Assault.png jako image reference. Prompt: `Generate in the EXACT SAME pixel art style, palette and outline thickness as the reference image. 2D game sprite, pixel art, ONE single closed fist in a black tactical glove, viewed from the side as if gripping an invisible weapon horizontally. The fist FILLS most of the canvas (occupies ~80% of frame width and height) — large, bold, clearly visible. Black tactical glove (#1a1a2e base + #4a4a4a knuckle highlights, optional small #8c8c8c metal stud). 2px dark navy outline (#1a1a2e) hugging ONLY the silhouette of the fist itself. ABSOLUTELY NO circular frame, NO ring, NO border, NO badge, NO icon background, NO container shape around the fist. NO arm, NO wrist, NO weapon — only the gloved fist as a free-floating object. Hard pixel edges, NO anti-aliasing, flat shading max 2 tones, NO gradients. Background MUST be FLAT SOLID WHITE #FFFFFF filling the entire canvas (every pixel that is not the fist must be pure white #FFFFFF) — NOT transparent, NOT checkered, NOT any other color. Square 1:1 canvas.` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `soldiers` → resize **32**.
>
> **Shadow (JPG z AI Studio → resize 96×32 PNG):** Generuj w AI Studio (BEZ image reference — to czysta geometria). Prompt: `2D game asset, ONE single horizontal solid black ellipse (#1a1a2e), wide and flat (3:1 horizontal aspect ratio), perfectly horizontal, centered on canvas. The ellipse FILLS the canvas: ~90% of canvas width, ~30% of canvas height. Pure solid #1a1a2e fill, NO outline, NO ring, NO border, NO frame around the ellipse, NO gradient, NO blur, NO soft edges, NO shadow under the ellipse, NO additional shapes — ONE ellipse only. Hard pixel edges, NO anti-aliasing. Background MUST be FLAT SOLID WHITE #FFFFFF filling the entire canvas (every pixel that is not the black ellipse must be pure white #FFFFFF) — NOT transparent, NOT checkered. Square 1:1 canvas.` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `soldiers` → resize **96x32** (wpisz dokładnie tak — szerokość×wysokość) → opcja `--no-palette` (czysta czerń + biel, palety nie potrzeba). Alpha kontrolowana w Godocie przez `modulate.a = 0.5`.

### 1.2 Wrogowie (5 typów × 1 sprite = 5 assetów + bossowie)

| Typ | Rozmiar | Opis |
|-----|---------|------|
| ✅ **Grunt** | **80×80 PNG** | Ciemnoczerwony, prosty, okrągły. Detale: pęknięta skorupa, oczy świecące |
| ✅ **Rusher** | **64×64 PNG** | Mały, ostry, kanciasty + pomarańczowe akcenty (oczy/kolce) |
| ✅ **Tank** | **112×112 PNG** | Masywny + fioletowe płyty pancerza, nity, pęknięcia |
| ✅ **Shooter** | **80×80 PNG** | Cienki, z niebieską optyką/celownikiem, anteną |
| ✅ **Grenadier** | **96×96 PNG** | Okrągły + żółto-oliwkowy ładunek wybuchowy z lontem |

**Bossowie (3 × 1 sprite):**

| Boss | Rozmiar | Opis |
|------|---------|------|
| ✅ **Jungle** (`boss_jungle.png`) | **192×192 PNG** | Zielony, organiczny, macki/liany, świecące oczy |
| ✅ **Desert** (`boss_desert.png`) | **192×192 PNG** | Złoty, snajperski, pustynny camo, długa lufa |
| ✅ **Bunker** (`boss_bunker.png`) | **224×224 PNG** | Szary, metaliczny mech, tarcza energetyczna |

Każdy boss: +1 sprite shield overlay (**128×128** PNG półprzezroczysty) ✅ `shield_overlay.png`

**🤖 Prompty Imagen 3 / Nano Banana Pro — Wrogowie (1:1, 1K, dołącz Assault.png lub Grunt.png jako image reference dla spójnego stylu):**

> **PREFIX WROGA:** `2D game sprite, pixel art style, near front-facing 3/4 view angled slightly to the right (Brotato-style enemy). Creature faces the viewer (looking towards player) but oriented rightwards, both sides of body visible. NOT side profile, NOT pure front, NOT isometric. Hard pixel edges, NO anti-aliasing. Dark navy outline 2px (#1a1a2e) on all visible shapes. Flat shading, max 3 tones per element, NO gradients. BODY STRUCTURE — creature is a compact rounded body with NO arm or limb shapes that end in hand/claw/paw shapes at the sides: the creature's body silhouette on both sides is a clean rounded edge — any limbs end in blunt rounded stubs OR tuck against the main body mass. ZERO finger shapes, ZERO claw-tip shapes, ZERO paw shapes visible at the body sides. NO weapon, NO ground shadow, NO scene, NO environment, NO floor — enemy creature only, fully isolated subject. Background: FLAT SOLID WHITE #FFFFFF ONLY — perfectly uniform white, no gradients, no vignette (auto-removed by pipeline). WAR MEAT enemy palette: dark red base #7a3a3a / dark red shadow #5a2a2a / orange accent #b85a2a / purple accent #5a3a6a / dark purple #3a2a4a / blue scope #3a5a7a / lens blue #4a9eff / dark yellow accent #8b7a2a / glow yellow #ffcc00 / glow red #cc0000 / white #ffffff / steel #8c8c8c / dark gray #4a4a4a / navy outline #1a1a2e.`
>
> **Grunt** (dołącz Assault.png jako image reference): `Generate in the EXACT SAME pixel art style and outline thickness as the reference image. [PREFIX WROGA] "Grunt" enemy: round bulky body (#7a3a3a base + #5a2a2a shadow on lower-left). 2 visible cracks on shell (thin #1a1a2e lines). Two glowing yellow eyes (#ffcc00 + small white #ffffff highlight). Menacing slouch posture. Square 1:1 canvas, sprite centered.`
>
> **Rusher** (dołącz Grunt.png jako image reference): `Generate in the EXACT SAME pixel art style, palette and outline thickness as the reference image. [PREFIX WROGA] "Rusher" enemy: small fast aggressive creature, angular sharp body (#7a3a3a + #5a2a2a shadow). 4-5 orange spikes on back (#b85a2a triangles). Two glowing orange eyes (#b85a2a + small #ffcc00 highlight). Sharp lean-forward profile.`
>
> **Tank** (dołącz Grunt.png jako image reference): `Generate in the EXACT SAME pixel art style, palette and outline thickness as the reference image. [PREFIX WROGA] "Tank" enemy: large heavily armored creature, massive body (#7a3a3a + #5a2a2a shadow). 3-4 purple armor plates (#5a3a6a base + #3a2a4a highlight) on shoulders and chest. Minimum 6 visible metal rivets (#8c8c8c) on plates. Short stubby legs (#7a3a3a). Heavy stance. Glowing red eyes (#cc0000).`
>
> **Shooter** (dołącz Grunt.png jako image reference): `Generate in the EXACT SAME pixel art style, palette and outline thickness as the reference image. [PREFIX WROGA] "Shooter" enemy: thin lanky body (#7a3a3a + #5a2a2a shadow). Cybernetic scope on head (blue housing #3a5a7a + glowing blue lens #4a9eff + small white reflex #ffffff). Antenna sticking up (#4a4a4a thin line). 4 thin spider-like legs (#1a1a2e).`
>
> **Grenadier** (dołącz Grunt.png jako image reference): `Generate in the EXACT SAME pixel art style, palette and outline thickness as the reference image. [PREFIX WROGA] "Grenadier" enemy: round body (#7a3a3a + #5a2a2a shadow). Bomb strapped to back (yellow-olive #8b7a2a + #6b5a14 shadow). Lit fuse with bright spark (#1a1a2e fuse line + #ffcc00 spark + tiny #ffffff hot core). 2-3 warning yellow stripes on body (#8b7a2a). Glowing yellow eyes (#ffcc00).`

**🤖 Prompty Imagen 3 / Nano Banana Pro — Bossowie (1:1, 1K, dołącz Tank.png jako image reference):**

> **Jungle Boss** (dołącz Tank.png jako image reference): `Generate in the EXACT SAME pixel art style, outline thickness and chibi-but-menacing proportions as the reference image. [PREFIX WROGA — swap palette: jungle boss palette: dark olive #3d4a28 / olive highlight #5a7a3a / glow yellow #ffcc00 / white #ffffff / navy outline #1a1a2e] "Jungle" boss: large organic plant creature, near front-facing 3/4 view angled right (faces player). Main body (#3d4a28 + #5a7a3a highlight on right side). 4-5 vines/tentacles wrapping body symmetrically left and right (thicker outline #1a1a2e 3px). 3 carapace plates on chest (#3d4a28 + #5a7a3a highlight). Two large glowing yellow eyes facing forward (#ffcc00 + #ffffff highlights). Roots/tendrils spreading at base. Imposing.`
>
> **Desert Boss** (dołącz Tank.png jako image reference): `Generate in the EXACT SAME pixel art style, outline thickness and chibi-but-menacing proportions as the reference image. [PREFIX WROGA — swap palette: desert boss palette: tan #d4c89a / sandstone shadow #8b7355 / cloth wrap #a0845c / dark gray gun #4a4a4a / steel #8c8c8c / brown stock #8b6914 / glow red #cc0000 / white #ffffff / navy outline #1a1a2e] "Desert" boss: heavily armored desert sniper creature, near front-facing 3/4 view angled right (faces player). BODY STRUCTURE: compact rounded torso, NO arms, NO hands — the body silhouette on both sides is a clean rounded edge ending in blunt stubs. 4-5 tan armor plates FUSED directly into the torso (#d4c89a + #8b7355 shadow on left side). A long sniper barrel GROWS OUT OF and is FUSED INTO the right shoulder — it is a body part, NOT a held weapon — pointing forward-right (gray tube #4a4a4a + #8c8c8c highlight line on top + brown grip band #8b6914 near base). Single large glowing red cyclops scope eye centered on the face/head, facing forward (#cc0000 iris + #ffffff small highlight dot). 2-3 ragged tan cloth wraps draped over torso shoulders (#a0845c). Short stubby legs (#d4c89a + #8b7355 shadow). No hands, no fingers, no claws anywhere.`
>
> **Bunker Boss** (dołącz Tank.png jako image reference): `Generate in the EXACT SAME pixel art style, outline thickness and chibi-but-menacing proportions as the reference image. [PREFIX WROGA — swap palette: bunker boss palette: mid gray #6b6b6b / dark gray #4a4a4a / steel highlight #8c8c8c / glow red #cc0000 / white #ffffff / navy outline #1a1a2e] "Bunker" boss: large mechanical war mech, near front-facing 3/4 view angled right (faces player). Heavy metal body with both sides visible (#6b6b6b + #4a4a4a shadow on left + #8c8c8c highlight on right). Thick frontal shield plate covering chest (#6b6b6b) with 8 visible rivets (#8c8c8c). 3 exposed pipes on shoulders (thin #1a1a2e lines). Glowing red sensor on chest facing forward (#cc0000 + #ffffff highlight). Heavy mech legs visible at bottom (#4a4a4a, both legs visible).`
>
> **Shield Overlay (PNG, 1024×1024 → resize 128×128):** Generuj w AI Studio (BEZ image reference). Prompt: `2D game sprite, pixel art, ONE single energy shield bubble seen from front — a translucent circular dome that FILLS most of the canvas (~85% of canvas width and height). Outer ring: bright cyan-blue circle outline (#4a9eff, 4px stroke) forming the bubble's boundary. Inner area: semi-transparent light blue fill simulated with 2 flat tones (#4a9eff darker + #ffffff highlight roughly in center). 3-4 hexagonal honeycomb patterns inside the bubble (#4a9eff thin lines). NO secondary outline, NO black frame, NO border, NO badge, NO container around the shield — the cyan ring IS the only outline. Hard pixel edges, NO anti-aliasing, NO real gradients (use 2-tone flat shading). Background MUST be FLAT SOLID WHITE #FFFFFF filling the entire canvas (every non-shield pixel must be pure white #FFFFFF) — NOT transparent, NOT checkered. Square 1:1 canvas.` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `enemies` → resize **128** → opcja `--no-palette` (cyan #4a9eff jest w palecie ale jasne tony mogą się rozjechać; przetestuj z paletą i bez). Alpha kontrolowana w Godocie przez `modulate.a = 0.6`.

### 1.3 Shadow (wspólny)
- 1 asset: czarny owal 12×4 px, alpha 0.3
- Podpinany jako child Sprite2D pod Y=+radius każdej jednostki

**Łączna lista sprite'ów jednostek: ~28 assetów** (6 graczy + 5 wrogów + 3 bossów + 1 shield overlay + 1 hand + 1 shadow + reszta wariantów)

---

## 2. Bronie (statyczne sprite'y)

Obecnie bronie to `draw_line` w soldier.gd. Docelowo: oddzielny Sprite2D w WeaponPivot.

> ⚠ **Zasada Brotato**: każda broń jest generowana **razem z dłonią** — ręka w czarnej rękawicy taktycznej chwyta broń za chwyt. Broń + dłoń = jeden PNG asset. Pivot w kodzie ustawiamy na środek dłoni (nie na środek broni).

| Broń | Klatki | Rozmiar | Format | Opis |
|------|--------|---------|--------|------|
| ✅ Karabin (`rifle.png`) | 1 | **128×64 PNG** | PNG | Klasyczny szturmowy + dłoń przy chwycie pistoletowym |
| ✅ Pistolet (`pistol.png`) | 1 | **80×56 PNG** | PNG | Kompaktowy + dłoń obejmująca rękojeść od dołu |
| ✅ Strzelba (`shotgun.png`) | 1 | **112×72 PNG** | PNG | Pump-action + dłoń przy tylnym chwycie |
| ✅ SMG (`smg.png`) | 1 | **96×56 PNG** | PNG | Kompaktowy + dłoń przy chwycie pistoletowym |
| ✅ Sniper Rifle (`sniper_rifle.png`) | 1 | **160×56 PNG** | PNG | Długa lufa + dłoń przy chwycie (3/4 od wylotu) |
| ✅ Granatnik (`grenade_launcher.png`) | 1 | **128×80 PNG** | PNG | Drum magazine + dłoń przy chwycie drewnianym |
| ✅ Melee/Nóż (`knife.png`) | 1 | **80×48 PNG** | PNG | Bojowy nóż + dłoń obejmująca rękojeść, klinga w prawo |

Po 1 klatce na tier? **Nie.** Zmiana tieru → tint/modulate w kodzie:
- Common: biały (bez tintowania)
- Uncommon: zielony tint
- Rare: niebieski tint
- Epic: fioletowy tint
- Legendary: złoty tint + subtelny glow shader

**🤖 Prompty Imagen 3 / Nano Banana Pro — Bronie (dołącz Karabin.png jako image reference dla pozostałych broni; wszystkie bronie: aspect ratio **4:3** w AI Studio — potrzebujemy miejsca na dłoń poniżej broni):**

> **PREFIX BRONI:** `2D game weapon+hand sprite, pixel art style, side view, barrel pointing RIGHT. Hard pixel edges, NO anti-aliasing. Dark navy 2px outline (#1a1a2e) on all visible parts. Flat shading max 2 tones per element (base + highlight). NO scene, NO environment, NO ground shadow. ONE black-gloved hand in a natural shooting grip (tactical glove: #1a1a2e base + #4a4a4a subtle highlight on knuckle tops) holds the weapon at its grip/handle. NATURAL GRIP RULES: the hand is SMALL — proportional to the grip width, NOT oversized. In side view: thumb rests along the left side of the grip, four fingers curl naturally underneath the grip, trigger finger near the trigger guard. Only the hand from wrist to fingertips is visible (NO forearm). The hand integrates seamlessly with the grip — it looks like the weapon is designed to be held, not like a floating fist attached externally. Hand height = ~15-18% of total canvas height. Weapon body dominates the sprite (~80% of canvas), hand is subordinate. Weapon + hand = ONE combined asset (Brotato-style). Background: FLAT SOLID WHITE #FFFFFF ONLY — perfectly uniform white, no gradients (auto-removed by pipeline tool). WAR MEAT weapon palette: dark gray body #4a4a4a / mid gray #6b6b6b / steel highlight #8c8c8c / brown wood #8b6914 / dark wood #6b5a14 / olive accent #5a6e3a / black glove #1a1a2e / glove highlight #4a4a4a / white reflex #ffffff / gold reflex #ffd700.`
>
> **Karabin** (BEZ ref — wzorzec stylu; AI Studio: **4:3**): `[PREFIX BRONI] Classic assault rifle. Metal receiver (#4a4a4a + #8c8c8c highlight on top). Long barrel (#8c8c8c). Curved banana magazine (#4a4a4a) hanging below receiver. Wooden stock at rear (#8b6914 + #6b5a14 shadow). Front and rear sights (small #4a4a4a rectangles on top). Charging handle (#8c8c8c). The gloved hand grips the pistol grip in a relaxed shooting grip — thumb visible on the near side of the grip, fingers curled naturally under it, trigger finger extended toward trigger guard. Hand size matches grip width. Grip is located at ~60% from barrel tip.` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `weapons` → resize **128x64**.
>
> **Pistolet** (dołącz Karabin.png jako image reference; AI Studio: **4:3**): `Generate in the EXACT SAME pixel art style and outline thickness as the reference image. [PREFIX BRONI] Compact pistol. Frame body (#4a4a4a + #6b6b6b highlight on slide). Slide on top (#8c8c8c). Short barrel (#8c8c8c). Checkered grip panel (#1a1a2e base + subtle #4a4a4a pattern). Visible hammer at rear (#4a4a4a). The gloved hand grips the handle naturally — grip panel and hand form one unified shape, thumb on the left side of the frame, fingers wrapped around the grip. Hand is compact and proportional to the grip, NOT oversized.` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `weapons` → resize **80x56**.
>
> **Strzelba** (dołącz Karabin.png jako image reference; AI Studio: **4:3**): `Generate in the EXACT SAME pixel art style and outline thickness as the reference image. [PREFIX BRONI] Pump-action shotgun. Receiver (#4a4a4a + #8c8c8c highlight). Wide barrel (#8c8c8c). Wooden stock (#8b6914 + #6b5a14 shadow). Wooden pump forend under barrel (#8b6914). Tube magazine under barrel (#4a4a4a). The gloved hand grips the pistol grip in a natural hold — thumb resting along the receiver, fingers curled around the grip underneath, matching the grip's width. Grip positioned at ~65% from muzzle.` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `weapons` → resize **112x72**.
>
> **SMG** (dołącz Karabin.png jako image reference; AI Studio: **4:3**): `Generate in the EXACT SAME pixel art style and outline thickness as the reference image. [PREFIX BRONI] Compact submachine gun. All-metal body (#4a4a4a + #8c8c8c highlight). Long curved magazine under receiver (#4a4a4a). Folding stock (#4a4a4a). Short barrel with flash hider (#8c8c8c + #4a4a4a). The gloved hand grips the slim pistol grip naturally — hand the same width as the grip, thumb on left side, fingers curled under. The compact SMG proportions make the hand feel correctly sized.` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `weapons` → resize **96x56**.
>
> **Sniper Rifle** (dołącz Karabin.png jako image reference; AI Studio: **4:3**): `Generate in the EXACT SAME pixel art style and outline thickness as the reference image. [PREFIX BRONI] Long bolt-action sniper rifle. Very long barrel (#8c8c8c). Scope on top (#4a4a4a housing + #ffffff lens + #ffd700 reflex). Wooden stock (#8b6914 + #6b5a14 shadow). Folded bipod under front barrel (#4a4a4a). Bolt handle on top (#4a4a4a). The gloved hand grips the pistol grip in a relaxed sniper hold — fingers naturally curled around the slim grip, thumb along the stock. Hand proportional to grip, positioned at ~70% from muzzle. The long barrel dominates the sprite.` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `weapons` → resize **160x56**.
>
> **Granatnik** (dołącz Karabin.png jako image reference; AI Studio: **4:3**): `Generate in the EXACT SAME pixel art style and outline thickness as the reference image. [PREFIX BRONI] Heavy grenade launcher. Thick stubby body (#4a4a4a + #6b6b6b highlight). Wide funnel barrel (#8c8c8c). Drum magazine (#4a4a4a circle + 6 small #1a1a2e dots). Olive strap (#5a6e3a). Wooden pistol grip (#8b6914 + #6b5a14 shadow). The gloved hand grips the wooden pistol grip naturally — fingers wrap around the chunky grip, thumb resting along the side, hand and grip form a unified shape. Grip at ~50% from muzzle.` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `weapons` → resize **128x80**.
>
> **Nóż** (dołącz Karabin.png jako image reference; AI Studio: **4:3**): `Generate in the EXACT SAME pixel art style and outline thickness as the reference image. [PREFIX BRONI] Combat knife, blade pointing RIGHT. Polished blade (#8c8c8c base + #ffffff highlight along top edge + #6b6b6b shadow on lower edge). Guard (#4a4a4a crossguard separating blade from handle). Wrapped handle (#4a4a4a base + 5 thin #1a1a2e wrap lines). Pommel (#8b6914). The gloved hand grips the handle in a natural forward grip — thumb resting on top of the handle, fingers wrapped around beneath, hand proportional to handle width. Handle+hand occupies the left ~30% of sprite. Blade extends rightward ~70%.` Po wygenerowaniu: drag na WRZUC_SPRITE GUI → kategoria `weapons` → resize **80x48**.

**Łączna lista sprite'ów broni: 7 assetów**

---

## 3. Pociski

| Typ | Klatki | Rozmiar source | Opis |
|-----|--------|----------------|------|
| Kula (standardowa) | 1 | **32×16 px** PNG | Żółty pocisk z lekkim trail |
| Kula (crit) | 1 | **40×24 px** PNG | Czerwony, większy, świecąca aura |
| Kula wroga | 1 | **32×24 px** PNG | Ciemnoczerwony, kanciasty, inny kształt |
| Rakieta/granat | 1 | **48×32 px** PNG | Z ogonem płomienia, oliwkowy korpus |
| Sniper bullet | 1 | **48×16 px** PNG | Długi biały trail prędkości |

**Skala w Godocie:** wszystkie pociski dostają `scale = Vector2(0.2, 0.2)` tak jak postacie — przy tej skali: kula = ~6×3px, sniper trail = ~10×3px, rakieta = ~10×6px na ekranie. Proporcje OK.

**Pipeline:** białe tło (tak samo jak postaci/bronie) → WRZUC_SPRITE GUI → kategoria `fx` → resize WxH. Aspect ratio: kule/sniper → **16:9**, kula wroga/rakieta → **4:3**.

**🤖 Prompty Nano Banana Pro / AI Studio — Pociski:**

> **Kula standardowa** (AI Studio: **16:9**): `High-res pixel art, single sprite, horizontal projectile flying right. Style: Gungeon-like, flat shading. Bright yellow bullet body (#ffcc00 base, #ff6600 shadow at rear). Short motion trail of 2-3 lighter yellow pixels (#ffcc00 fading to #ffd700) behind the bullet. 1px outline (#1a1a2e) on bullet body only. Background: FLAT SOLID WHITE #FFFFFF ONLY — perfectly uniform white (auto-removed by pipeline).` Po wygenerowaniu: WRZUC_SPRITE GUI → kategoria `fx` → resize **32x16**.
>
> **Kula crit** (AI Studio: **16:9**): `High-res pixel art, single sprite, horizontal projectile flying right. Style: Gungeon-like, flat shading. Critical hit bullet — larger and more intense. Red body (#cc0000 base, #8b0000 shadow). Bright yellow glow ring around body (#ffcc00 outer ring, 1-2px thick). White hot core spot (#ffffff, 2px). 1px outline (#1a1a2e) on bullet body. Background: FLAT SOLID WHITE #FFFFFF ONLY — perfectly uniform white (auto-removed by pipeline).` Po wygenerowaniu: WRZUC_SPRITE GUI → kategoria `fx` → resize **40x24**.
>
> **Kula wroga** (AI Studio: **4:3**): `High-res pixel art, single sprite, horizontal projectile flying right. Style: Gungeon-like, flat shading. Enemy bullet — dark red spiky shape (NOT smooth round). Body (#8b0000 base, #5a2a2a shadow). 2-3 small jagged spike protrusions on top and bottom (#8b0000). 1px outline (#1a1a2e). Background: FLAT SOLID WHITE #FFFFFF ONLY — perfectly uniform white (auto-removed by pipeline).` Po wygenerowaniu: WRZUC_SPRITE GUI → kategoria `fx` → resize **32x24**.
>
> **Rakieta** (AI Studio: **4:3**): `High-res pixel art, single sprite, flying right. Style: Gungeon-like, flat shading. Rocket. Olive cylindrical body (#5a6e3a base, #3d4a28 shadow on lower half), pointed metal tip at right (#4a4a4a). Two small fins at rear left (#4a4a4a). Flame trail at rear: orange (#ff6600) with bright yellow-white core (#ffcc00 + #ffffff), 3-4 flat pixel blocks forming the flame. 1px outline (#1a1a2e) on rocket body only. Background: FLAT SOLID WHITE #FFFFFF ONLY — perfectly uniform white (auto-removed by pipeline).` Po wygenerowaniu: WRZUC_SPRITE GUI → kategoria `fx` → resize **48x32**.
>
> **Sniper bullet** (AI Studio: **16:9**): `High-res pixel art, single sprite, horizontal. Style: Gungeon-like, flat shading. Sniper tracer round. Very elongated horizontal shape (~4:1 width ratio). Bright white core (#ffffff, left 1/4 of length). Yellow-orange fade trail (#ffcc00 mid section, #ff6600 rear section). Hard pixel edges, NO outline. Background: FLAT SOLID WHITE #FFFFFF ONLY — perfectly uniform white (auto-removed by pipeline).` Po wygenerowaniu: WRZUC_SPRITE GUI → kategoria `fx` → resize **48x16**.

**Łączna lista: 5 assetów**

---

## 4. Efekty (FX sprite'y)

| Efekt | Klatki | Rozmiar source | Użycie |
|-------|--------|----------------|--------|
| **Muzzle flash** | 2-3 | **64×64 px** PNG | Koniec lufy, 0.05s na klatkę |
| **Death splat** | 2 warianty | **128×128 px** PNG | Plama po zabitym wrogu — zostaje na ziemi (decal) |
| **Death splat (boss)** | 1 | **256×256 px** PNG | Duża plama po bossie |
| **Hit spark** | 2-3 | **48×48 px** PNG | Przy trafieniu wroga |
| ✅ **Loot coin** (`coin.png`) | 1 | **48×48 px** PNG | Podmieniony na PNG |
| ⬜ **XP gem** | 1 | **40×40 px** PNG | Jeśli dodamy XP pickup |
| ✅ **Crate** (`crate.png`) | 1 | **80×80 px** PNG | Podmieniony na PNG |

**🤖 Prompty Nano Banana Pro / AI Studio — FX (1:1, generuj high-res → WRZUC_SPRITE GUI → kategoria `fx`):**

> **Muzzle flash** (AI Studio: **1:1**): `High-res pixel art, single sprite, single frame. Style: Gungeon-like, flat shading. Starburst muzzle flash explosion. Bright yellow center (#ffcc00) with 6-8 sharp spike rays in orange (#ff6600). White hot core (#ffffff). NO outline. Centered on canvas. Background: FLAT SOLID WHITE #FFFFFF ONLY — perfectly uniform white (auto-removed by pipeline).` WRZUC_SPRITE GUI → kategoria `fx` → resize **64x64**.
>
> **Death splat** (AI Studio: **1:1**): `High-res pixel art, single sprite, top-down view. Style: Gungeon-like, flat shading. Blood splatter pool. Dark red base (#cc0000) with darker pool center (#8b0000). Irregular splat shape with 3-4 droplet trails radiating outward. NO outline. Background: FLAT SOLID WHITE #FFFFFF ONLY — perfectly uniform white (auto-removed by pipeline).` WRZUC_SPRITE GUI → kategoria `fx` → resize **128x128**.
>
> **Death splat boss** (AI Studio: **1:1**): `High-res pixel art, single sprite, top-down view. Large blood splatter for boss death. Same style as regular splat (#cc0000/#8b0000), but ~2.5x larger and more dramatic with more droplet trails. NO outline. Background: FLAT SOLID WHITE #FFFFFF ONLY — perfectly uniform white (auto-removed by pipeline).` WRZUC_SPRITE GUI → kategoria `fx` → resize **256x256**.
>
> **Hit spark** (AI Studio: **1:1**): `High-res pixel art, single sprite, single frame impact spark. Style: Gungeon-like. Yellow center (#ffcc00) with white sparks (#ffffff) shooting outward in 4-6 directions. Small explosion feel. NO outline. Background: FLAT SOLID WHITE #FFFFFF ONLY — perfectly uniform white (auto-removed by pipeline).` WRZUC_SPRITE GUI → kategoria `fx` → resize **48x48**.
>
> **Loot coin** (AI Studio: **1:1**): `2D game sprite, pixel art, front-facing view (coin face-on toward viewer). Single gold coin, centered on canvas, filling ~80% of canvas. Round disc shape seen from the front — NOT top-down. Gold fill (#ffd700 base + #b8860b shadow on lower-right quarter + #8b7200 thin edge shadow on right side). White highlight glint (#ffffff, 2-3px spot on upper-left). 2px dark navy outline (#1a1a2e) around coin edge only. NO ground shadow. Background: FLAT SOLID WHITE #FFFFFF ONLY — perfectly uniform white (auto-removed by pipeline).` WRZUC_SPRITE GUI → kategoria `loot` → resize **48x48**.
>
> **XP gem** (AI Studio: **1:1**): `2D game sprite, pixel art, near front-facing 3/4 view (slightly angled like Brotato loot — NOT top-down). Single gemstone, centered on canvas, filling ~80% of canvas. Tall diamond/gem shape (pointy top and bottom, widest in the middle). Bright cyan-blue body (#4a9eff base + #88ccff highlight on upper-left facet + #1a7acc shadow on lower-right facet). White sparkle glint (#ffffff, 2px spot on upper-left facet). 2px dark navy outline (#1a1a2e) around gem silhouette. NO ground shadow. Background: FLAT SOLID WHITE #FFFFFF ONLY — perfectly uniform white (auto-removed by pipeline).` WRZUC_SPRITE GUI → kategoria `loot` → resize **40x40**.
>
> **Crate** (AI Studio: **1:1**): `2D game sprite, pixel art, near front-facing 3/4 isometric view (like Brotato loot — slightly angled so both front face and top are partially visible — NOT top-down). Single wooden crate, centered on canvas, filling ~80% of canvas. Front face (larger, darker): brown wood base (#8b6914 + #6b5a14 shadow on left side). Top face (smaller strip visible at top, lighter): #a07828. X-pattern wood grain lines on front face (#6b5a14 thin diagonal lines). Metal corner reinforcements at visible corners (#4a4a4a squares). Metal latch centered on front face (#8c8c8c). 2px dark navy outline (#1a1a2e) around crate silhouette. NO ground shadow. Background: FLAT SOLID WHITE #FFFFFF ONLY — perfectly uniform white (auto-removed by pipeline).` WRZUC_SPRITE GUI → kategoria `loot` → resize **80x80**.

**Łączna lista: ~12 assetów**

---

## 5. Tła aren (Tilemapy)

Każda arena potrzebuje:
- **Floor tile** — 16×16 px, 2-3 warianty (trawa/piasek/metal)
- **Wall/debris tile** — 16×16 px, 3-4 warianty (skały/kaktusy/beczki)
- **Dekoracje** — 2-3 na arenę (kości, zardzewiały pojazd, kable)

| Arena | Floor | Walls/Debris | Dekoracje |
|-------|-------|-------------|-----------|
| Dżungla | Ciemna ziemia + mech | Drzewa, liany, skały | Klatki, ruiny |
| Pustynia | Piasek jasny | Kaktusy, głazy, wraki | Szkielety, flagi |
| Bunkier | Metal/beton | Ściany, beczki, skrzynie | Kable, monitory |

**🤖 Prompty Nano Banana Pro / AI Studio — Tilemapy (16:9 dla wall/dekoracji; WRZUC_SPRITE GUI → kategoria `fx`):**

> **Dżungla floor:** `16x16 seamless tile, top-down view. Grass base (#5a7a3a) with darker moss/roots (#3d4a28). Tileable edges. NO outline. Full fill, pixel-perfect.`
>
> **Dżungla walls** (AI Studio: **16:9**): `16x16 pixel art, top-down view. Jungle obstacle: thick tree trunk (#3d4a28 bark, #5a7a3a leaves). 1px outline (#1a1a2e). Background: FLAT SOLID WHITE #FFFFFF ONLY (auto-removed by pipeline).` WRZUC_SPRITE GUI → `fx` → resize **16x16**.
>
> **Pustynia floor:** `16x16 seamless tile, top-down view. Sandy base (#d4c89a) with sparse darker pixels (#8b7355). Tileable edges. NO outline. Full fill, pixel-perfect.`
>
> **Pustynia walls** (AI Studio: **16:9**): `16x16 pixel art, top-down view. Desert obstacle: sandstone boulder (#7a7a7a base, #6b5a3a detail). 1px outline (#1a1a2e). Background: FLAT SOLID WHITE #FFFFFF ONLY (auto-removed by pipeline).` WRZUC_SPRITE GUI → `fx` → resize **16x16**.
>
> **Bunkier floor:** `16x16 seamless tile, top-down view. Concrete base (#7a7a7a) with gap lines (#4a4a4a) every 4-8px. Tileable. NO outline. Full fill, pixel-perfect.`
>
> **Bunkier walls** (AI Studio: **16:9**): `16x16 pixel art, top-down view. Bunker obstacle: metal wall (#6b6b6b/#4a4a4a). 1px outline (#1a1a2e). Background: FLAT SOLID WHITE #FFFFFF ONLY (auto-removed by pipeline).` WRZUC_SPRITE GUI → `fx` → resize **16x16**.
>
> **Dekoracje (wspólne)** (AI Studio: **1:1**): `8x8 to 12x12 pixel art decoration, top-down view. Single prop: [skeleton bones #f2d2a9 / rusty wire #4a4a4a / broken monitor #4a9eff pixel]. 1px outline (#1a1a2e). Background: FLAT SOLID WHITE #FFFFFF ONLY (auto-removed by pipeline).` WRZUC_SPRITE GUI → `fx` → resize **12x12** (lub odpowiednio).

**Łączna lista: ~30 tile assetów** (3 areny × ~10 tile'i × 64×64 px)

---

## 6. UI Skin

| Element | Format | Opis |
|---------|--------|------|
| ✅ **Panel BG** | SVG/PNG 9-patch | `Panel BG.svg` zintegrowane jako StyleBoxTexture |
| **Button style** | PNG 9-patch **384×128** | normal, hover, pressed (3 stany) |
| **Card frame** | PNG **192×256** | 5 wariantów per tier (obramowanie: szary/zielony/niebieski/fioletowy/złoty) |
| **HP bar** | PNG 9-patch | Sprite-based zamiast ProgressBar plugin |
| **XP bar** | PNG 9-patch | Gradient fill sprite |
| **Ikony pasywek** | **SVG 64×64** preferowane | Skalowalne wektory — ostre w każdym rozmiarze (16 sztuk) |
| **Ikony broni (shop)** | PNG 128×128 | Powiększone wersje sprite'ów broni z sekcji 2 |

**🤖 Prompty Nano Banana Pro / AI Studio — UI (WRZUC_SPRITE GUI → kategoria `fx`):**

> **Panel BG (→ 192×192, 9-patch):** `High-res pixel art, 1024x1024 source for downscale to 192x192, single sprite, frontal view. Style: Gungeon-like UI, sci-fi military panel. Dark metal panel base (#1e1e2e), alternate panel sections (#252530). Beveled frame edges (#3a3a4e dark, #555570 highlight). Visible rivets in 4 corners (#8c8c8c, ~6px each in source). 9-patch friendly: symmetric corners (24px each in source for downscale to 3px corners). NO anti-aliasing, hard pixel edges. Transparent center area NOT needed — full opaque.`
>
> **Buttons (3 stany, każdy → 384×128):** (AI Studio: **16:9**) `High-res pixel art, single sprite, frontal view. Style: Gungeon-like military UI button, single state: [normal: body #4a4a4a, top highlight #6b6b6b, frame #555570 / hover: body #6b6b6b, top highlight #8c8c8c, frame #4a9eff glow / pressed: body #3a3a4e, top highlight #4a4a4a, frame #555570, depressed look]. Beveled edges, 4 corner rivets (#8c8c8c). 2px outline (#1a1a2e). Background: FLAT SOLID WHITE #FFFFFF ONLY (auto-removed by pipeline).` WRZUC_SPRITE GUI → `fx` → resize **384x128**.
>
> **Card frames (5 tierów, każdy → 192×256):** (AI Studio: **3:4**) `High-res pixel art, single sprite, frontal view, single tier. Style: Gungeon-like card border. [tier]: gray (#6b6b6b base, #8c8c8c highlight) / green (#5a6e3a base, #88aa55 highlight) / blue (#4a9eff base, #88ccff highlight) / purple (#5a3a6a base, #885566 highlight) / gold (#ffd700 base, #ffffff highlight + slight glow). Transparent center (interior of frame — the BFS pipeline preserves the interior hole since it is not connected to the border). Decorative corners with metal studs (#1a1a2e). 2px outline (#1a1a2e) on inner and outer edges. Background: FLAT SOLID WHITE #FFFFFF ONLY on the outer area around the frame (auto-removed by pipeline).` WRZUC_SPRITE GUI → `fx` → resize **192x256**.
>
> **Ikony pasywek (SVG 64×64, w Inkscape):** Geometric — single icon per item. Use palette: metal grays (#8c8c8c/#6b6b6b/#4a4a4a), olive (#5a6e3a/#3d4a28), FX accents (#ffd700/#cc0000/#4a9eff). 4-6px outline (#1a1a2e). Transparent BG.
>
> **Ikony broni (→ 128×128 PNG):** Re-render or crop sprites from section 2 (Bronie). Centered on transparent BG, with subtle drop shadow.

**Łączna lista: ~30 assetów UI**

---

## 6.5 Arena Background — Layered Architecture (QA-driven, deferred)

> 🚨 **QA flag**: Recenzent: *"arena to zielona pustka, nuda — gracz nie czuje historii"*. Plan poniżej do zrobienia w **art passie** po MVP audio.

### Cel
Zamiast jednolitego procedural floor (`arena.gd:_draw_floor()`), arena ma 4 warstwy z głębi:

| z-index | Warstwa | Typ node'a | Zawartość |
|--------:|---------|------------|-----------|
| **-100** | `Sky` | `ParallaxBackground` + `ParallaxLayer` | Daleki horyzont (góry, dym, helikoptery), motion factor 0.05–0.15 |
| **-50**  | `Floor` | `TileMapLayer` | Bazowa kafelka terenu per arena (jungle/desert/bunker), 16×16 tiles |
| **-40**  | `FloorDetails` | `TileMapLayer` | Pęknięcia, kałuże, ślady gąsienic, wzory \u2014 procedural scatter z autotile |
| **-10**  | `EnvironmentProps` | `Node2D` | Beczki, palety, skrzynie, kawałki pojazdów (statyczne kolizyjne) |
| 0        | gra (squad/wrogowie/loot) | (jak teraz) | aktywna warstwa rozgrywki |
| +50      | `Foreground` | `Node2D` | Liście dżungli / piasek wirujący / dym przesłaniający (alpha 0.3) |

### Tilesety per arena (placeholder paths)
```
assets/sprites/maps/jungle/jungle_tileset.tres
assets/sprites/maps/desert/desert_tileset.tres
assets/sprites/maps/bunker/bunker_tileset.tres
```

### Zmiany w `arena.tscn`
1. Dodać puste node'y w kolejności: `Sky` (ParallaxBackground), `Floor` (TileMapLayer), `FloorDetails` (TileMapLayer), `EnvironmentProps` (Node2D), `Foreground` (Node2D).
2. Skrypt `arena.gd` w `_ready()` ładuje tileset wg `arena_modifier.arena_type` (string: "jungle"/"desert"/"bunker").
3. `_draw_floor()` → usunąć (zastąpione przez TileMapLayer).
4. `EnvironmentProps` populować proceduralnie: 5–10 props losowo w 320×180 area, omijając center (squad spawn).

### Akceptance criteria
- Zmiana z jungle → desert daje **wizualnie inną arenę** w 1 sekundę (ten sam scene tree, inne tilesety).
- ParallaxBackground reaguje na ruch kamery (zoom 2× → motion ×2).
- Brak regresji FPS na Androidzie (>50 FPS przy 50 wrogach).
- Props nie blokują celowania (mają `collision_mask=0` lub są tylko wizualne).

### Status
⬜ **DEFERRED** — implementacja po Faza 2 (audio MP3→OGG fix). Wymaga assetów: 3 tilesety × 16 unikalnych kafelków = 48 sprites + 5 prop sprites per arena.

---

## 7. Procedural Animation Plan (KOD, nie assety)

### 7.1 Ruch (Movement Wobble)
```
# W soldier.gd / enemy.gd _physics_process:
if velocity.length() > 5.0:
    sprite.rotation = sin(Time.get_ticks_msec() * 0.01) * 0.08  # ±4.5° wobble
else:
    sprite.rotation = lerp(sprite.rotation, 0.0, 0.2)
```

### 7.2 Kierunek patrzenia (Facing — flip_h)

**Decyzja: Żołnierze patrzą W STRONĘ WROGA, do którego strzelają** (jak Brotato).

Sprite jest narysowany w **3/4 view facing right** — `flip_h=true` daje 3/4 facing left. Brak luki wizualnej przy zmianie kierunku (oba ramiona i twarz pozostają widoczne z obu stron, w przeciwieństwie do side profile gdzie flip dawałby "znikającą" sylwetkę).

```
# W soldier.gd — kierunek = broń, nie joystick:
if weapon_pivot.target and is_instance_valid(weapon_pivot.target):
    sprite.flip_h = weapon_pivot.target.global_position.x < global_position.x
elif velocity.x != 0:
    sprite.flip_h = velocity.x < 0
```

Wrogowie: flip_h w stronę targetu (gracza):
```
# W enemy.gd:
sprite.flip_h = target.global_position.x < global_position.x
```

### 7.3 Odrzut broni (Weapon Recoil)
```
# W soldier.gd przy strzale:
var recoil_tween = create_tween()
weapon_sprite.position.x -= 3.0  # cofnij
recoil_tween.tween_property(weapon_sprite, "position:x", 0.0, 0.08)
```

### 7.4 Hit Flash (Shader)
Zamiast `modulate` tween → nowy `hit_flash.gdshader`:
```gdshader
shader_type canvas_item;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    COLOR = mix(tex, flash_color * tex.a, flash_amount);
}
```
Trigger w kodzie: `material.set_shader_parameter("flash_amount", 1.0)` → tween do 0.0 w 0.1s.

### 7.5 Death Splat (Decal)
Przy `_die()`: instancjonuj Sprite2D z losowym death splat sprite, ustaw `global_position`, losowa rotacja, **nie ruszaj, nie usuwaj** → zostaje jako decal na ziemi do końca fali.

### 7.6 Loot Pulse
Istniejący sinus bob (✅) + dodaj scale pulse:
```
sprite.scale = Vector2.ONE * (1.0 + sin(_bob_time * 2.0) * 0.1)
```

### 7.7 Boss Shield Overlay
Oddzielny Sprite2D z alpha pulse (sin) zamiast `draw_arc`.

---

## 8. Problem oddziału — czytelność 4 żołnierzy

### 8.1 Problem
Przy formacji Diament (4 żołnierzy blisko siebie) + po 1 broni orbitalnej = 8 sprite'ów w małej przestrzeni.

### 8.2 Rozwiązania

**A) Różnicowanie klas wizualnie:**
- Każda klasa ma unikalną sylwetkę (Ciężki duży, Scout mały, Medyk z krzyżem)
- Kolory body per klasa (już w `SoldierClass.draw_color`)

**B) Bronie jako jedyny wskaźnik „kto jest kto":**
- Broń orbituje w stałej odległości (WeaponPivot) — już działa
- Broń rysuje się PO postaci (higher z-index) — zawsze widoczna

**C) Zmniejszenie clutter:**
- Dłoń jest CZĘŚCIĄ sprite'a broni (Brotato-style) — jeden asset zamiast osobnego `Hand.svg`. Pivot ustawiamy na środku dłoni w kodzie → broń obraca się naturalnie w `WeaponPivot`. Mniej node'ów per żołnierz w oddziale 4.
- Cienie lekko przezroczyste (alpha 0.2) — nie zasłaniają

**D) „Główny żołnierz" (Leader emphasis):**
- Pierwszy żołnierz (klasa startowa) ma subtelny biały outline/glow
- Reszta: normalny render — wzrok naturalnie ciągnie do leadera

---

## 9. Paleta barw — kontrast i czytelność

### Gracze (wspólny mundur + akcenty klas):
- Mundur baza: #5a6e3a (oliwkowa zieleń)
- Mundur cień: #3d4a28 (ciemna zieleń)
- Ekwipunek: #6b6b6b / #4a4a4a / #8c8c8c (szarości)
- Skóra: #f2d2a9 (jasna) / #c4956a (cień)
- Akcenty: #a0845c (beret snajpera), #e07020 (pasek inżyniera), #2a4a7a (pancerz ciężkiego), #ffffff (krzyż medyka)

### Wrogowie (baza + akcenty typów):
- Baza: #7a3a3a (ciemnoczerwony)
- Cień: #5a2a2a
- Rusher akcent: #b85a2a (ciemny pomarańcz)
- Tank akcent: #5a3a6a (ciemny fiolet)
- Shooter akcent: #3a5a7a (ciemny niebieski)
- Grenadier akcent: #8b7a2a (ciemny żółto-oliwkowy)

### Tła aren (pełne wypełnienie):
- Dżungla: #5a7a3a (trawa) + #3d4a28 (detale)
- Pustynia: #d4c89a (piasek) + #8b7355 (detale)
- Bunkier: #7a7a7a (beton) + #4a4a4a (linie)

**Zasada:** Tło CIEMNE, jednostki JASNE → kontrast ≥ 3:1 zawsze.

---

## 10. UI Karty — Shop i Upgrade Panel

> Wszystko spójne z paletą WAR MEAT i stylem Gungeon/Brotato. Karty to militarne "teczki z briefingiem" — nie fantasy slot machine.

### 10.0 Podejście: Pre-generated Card Shell + Code Text Overlay

**Zasada:** Każda karta to **jeden PNG z ramką + ikoną + tłem** wygenerowany przez AI.
Tekst (nazwa, statsy, cena, opis) jest nakładany w Godocie jako przezroczyste Labels — bo jest dynamiczny.

```
[PNG: card shell]     [Godot code overlay]
┌─────────────────┐   ┌─────────────────┐
│ 🎖 [dekoracja]  │ + │ NAZWA ITEMU     │
│  ┌───────────┐  │   │ DMG: 15         │
│  │  [IKONA]  │  │   │ Ogień: 1.5/s   │
│  │  pixel    │  │   │ [$85] [🔒] [✕] │
│  └───────────┘  │   └─────────────────┘
│  [tło tekstury] │
└─────────────────┘
```

**Zalety:**
- Zero runtime compositing — jeden TextureRect zamiast 3 node'ów
- Ikona, styl, tier — wszystko w jednym pliku, ładowane przez `preload`
- Możliwość ręcznych poprawek w Photopea bez dotykania kodu

**Liczba assetów:**
| Typ | Ilość | Ścieżka |
|-----|-------|---------|
| Karty broni (7 broni × 5 tierów) | 35 | `assets/sprites/ui/cards/shop/rifle_rare.png` |
| Karty pasywek/klas (8 typów × 3 tiery) | 24 | `assets/sprites/ui/cards/shop/assault_class_uncommon.png` |
| Karty upgrade'ów (8 kategorii × 3 rzadkości) | 24 | `assets/sprites/ui/cards/upgrade/dmg_rare.png` |
| **Razem** | **~83** | |

**Format:** PNG **192×256** (9-patch margins = 0, bo pełny obraz), tekstura importowana z `Texture Filter: Linear`.

---

### 10.1 Anatomia karty sklepu (ShopCard)

```
┌─────────────────────────────┐  ← card frame PNG 192×256 (9-patch), tier color
│ 🟠 [NAZWA ITEMU]            │  ← pasek tytułu: colored badge + bold label
├─────────────────────────────┤
│  ╔═══════════════════════╗  │
│  ║   [IKONA 64×64 px]    ║  │  ← ikona broni/pasywki z sekcji 2/6 (PNG)
│  ║   wycentrowana        ║  │
│  ╚═══════════════════════╝  │
├─────────────────────────────┤
│  DMG: 15  Ogień: 1.5/s     │  ← 2-3 linie statystyk, font 11px, color #c8c8c8
│  Zasięg: 160  Rozrzut: 0.02 │
├─────────────────────────────┤
│  [$85]  [🔒]  [✕]          │  ← przyciski akcji (cena/lock/banish)
└─────────────────────────────┘
```

**Tier colors** (border + badge background):
| Tier | Kolor bordera | Kolor badge | Hex |
|------|--------------|-------------|-----|
| Common | szary | `#6b6b6b` | card_frame_gray.png |
| Uncommon | zielony | `#5a8a3a` | card_frame_green.png |
| Rare | niebieski | `#2a6aaa` | card_frame_blue.png |
| Epic | fioletowy | `#6a3a8a` | card_frame_purple.png |
| Legendary | złoty + glow | `#c8a020` | card_frame_gold.png |

**Ikona itemu (64×64 PNG):**
- Broń → istniejący sprite broni z sekcji 2 (crop + center na przezroczystym tle)
- Pasywka (klasa żołnierza) → dedykowana ikona 64×64 z sekcji 6 (SVG ikony pasywek)
- Brak assetu → placeholder: sylwetka broni/gwiazdka generowana `_draw()`

**Kod w ShopCard:** ikona ładowana przez `WeaponData.icon_texture` lub `PassiveItem.icon_texture` (property do dodania). Fallback: `null` → nie renderuj Image rect, tylko tekst.

---

### 10.2 Anatomia karty upgrade (UpgradePanel)

```
┌─────────────────────────────┐  ← card frame 9-patch, rarity color border
│  ╔═══════════════════════╗  │
│  ║   [IKONA 48×48 px]    ║  │  ← ikona upgrade (SVG z palety pasywek)
│  ╚═══════════════════════╝  │
│                             │
│  PEŁEN AUTOMAT              │  ← nazwa upgradu, font 14px bold, rarity color
│                             │
│  +12% szybkości ognia       │  ← opis, font 12px, #c8c8c8, autowrap
│                             │
│  ★★★☆☆                     │  ← gwiazdki rzadkości (opcjonalne)
└─────────────────────────────┘
```

**Upgrade'y w grze — 8 kategorii × 3 rzadkości = 24 karty:**

| ID | Nazwa | Kategoria | Rzadkość | Ikona na karcie |
|----|-------|-----------|----------|-----------------|
| dmg_c | Mocniejsze pociski | DAMAGE | COMMON | kula z iskrą, żółty (#ffcc00) |
| dmg_r | Wojenne treningi | DAMAGE | RARE | 2 kule + strzałka w górę, niebieski border |
| dmg_e | Beresker | DAMAGE | EPIC | czaszka z celownikiem, fioletowy border |
| spd_c | Lekkie buty | SPEED | COMMON | wojskowy but, oliwkowy |
| spd_r | Sprinter | SPEED | RARE | but + smugi prędkości, niebieski border |
| hp_c | Konserwy | MAX_HP | COMMON | puszka konserwowa, zielona etykieta |
| hp_r | Pancerz | MAX_HP | RARE | płyta pancerza, niebieski border |
| hp_e | Reinforced | MAX_HP | EPIC | pełna kamizelka z płytami, fioletowy border |
| luck_c | Talizman | LUCK | COMMON | nieśmiertelnik (dog tag) na łańcuszku |
| luck_r | Czterolistna koniczyna | LUCK | RARE | koniczyna pixelowa, zielona, niebieski border |
| rng_c | Lornetka | RANGE | COMMON | lornetka, ciemny metal |
| rng_r | Snajperskie celowniki | RANGE | RARE | luneta z celownikiem krzyżowym, niebieski border |
| fr_c | Wydajny mechanizm | FIRE_RATE | COMMON | zębatka + błyskawica, szary metal |
| fr_r | Pełen automat | FIRE_RATE | RARE | zębatka × 3 + błyskawica, niebieski border |
| arm_c | Kamizelka | ARMOR | COMMON | kamizelka taktyczna, prosta |
| arm_r | Płytowa kamizelka | ARMOR | RARE | kamizelka z płytami pancerza, niebieski border |
| regen_c | Apteczka polowa | HP_REGEN | COMMON | apteczka z czerwonym krzyżem |
| regen_r | Auto-medkit | HP_REGEN | RARE | apteczka z zielonym pulsem, niebieski border |

**Naming convention plików:** `assets/sprites/ui/cards/upgrade/{id}.png`
Np. `dmg_epic.png`, `spd_rare.png`, `hp_common.png`

**Ikony na kartach upgrade** — ikona jest częścią card shell PNG (bake-in), **nie osobnym assetem**.
Ta sama ikona per kategoria — zmienia się border/tło per rzadkość (gray/blue/purple).

---

### 10.3 Prompty do generacji pełnych kart (card shell PNG)

> **Zasada:** Dołącz `Assault.png` jako image reference dla spójnego stylu. AI Studio: **3:4**, 1K.
> Pipeline: WRZUC_SPRITE → kategoria `cards` → resize **192×256**.

#### PREFIX KARTY (wspólny dla wszystkich kart):

```
2D game UI card sprite, pixel art style, frontal view. Style: Enter the Gungeon
tactical briefing card — military aesthetic, serious, NO fantasy. Hard pixel
edges, NO anti-aliasing. Dark navy outline 2px (#1a1a2e) on all shapes.
Flat shading max 3 tones per element, NO gradients.

CARD STRUCTURE (portrait orientation, 3:4 aspect ratio):
- Outer frame: [TIER_FRAME] with corner metal rivets (#8c8c8c dot + #1a1a2e)
- Top strip (~20% height): dark title bar (#1a1a2e background), [TIER_BADGE]
  colored left edge marker (8px wide stripe), title area intentionally EMPTY
  (white placeholder — text rendered by game engine)
- Center area (~50% height): [ICON_AREA] — pixel art illustration of item,
  centered, fills ~70% of center area width. [ICON_DESCRIPTION]
- Bottom strip (~30% height): dark stats area (#0d0d1a background), 3 rows of
  white placeholder lines (#ffffff 1px thin horizontal lines equally spaced)
  — actual stats text rendered by game engine over these lines
- ALL TEXT AREAS left as visual placeholders (lines/blocks), NOT actual text

Background: FLAT SOLID WHITE #FFFFFF only outside the card boundary
(auto-removed by pipeline).
WAR MEAT palette applies throughout.
```

#### Podmień zmienne:

**[TIER_FRAME]:**
- Common: `dark gray beveled frame (#4a4a4a base + #6b6b6b inner bevel highlight)`
- Uncommon: `green military frame (#3a5a2a base + #5a8a3a highlight)`
- Rare: `blue tactical frame (#1a4a7a base + #4a9eff inner glow line 1px)`
- Epic: `purple arcane frame (#4a2a6a base + #7a3a9a highlight)`
- Legendary: `gold ornate frame (#8a6a10 base + #ffd700 outer glow 2px, small star motifs in corners)`

**[TIER_BADGE] left stripe color:**
- Common: `#6b6b6b` | Uncommon: `#5a8a3a` | Rare: `#4a9eff` | Epic: `#7a3a9a` | Legendary: `#ffd700`

**[ICON_AREA] + [ICON_DESCRIPTION] przykłady:**

| Karta | [ICON_DESCRIPTION] |
|-------|-------------------|
| `rifle_rare.png` | `pixel art assault rifle, side view, barrel pointing right, dark gray metal body (#4a4a4a + #8c8c8c highlight), wooden stock (#8b6914), same style as WAR MEAT weapon sprites` |
| `shotgun_common.png` | `pixel art pump-action shotgun, side view, barrel right, wide receiver (#4a4a4a), wooden pump forend and stock (#8b6914)` |
| `pistol_uncommon.png` | `pixel art compact pistol, side view, barrel right, black frame (#4a4a4a + #6b6b6b slide highlight)` |
| `smg_rare.png` | `pixel art submachine gun, side view, barrel right, all-metal body (#4a4a4a), curved magazine, flash hider (#8c8c8c)` |
| `sniper_epic.png` | `pixel art bolt-action sniper rifle, side view, very long barrel right, scope on top (#4a4a4a + #ffffff lens), wooden stock (#8b6914)` |
| `grenade_launcher_epic.png` | `pixel art grenade launcher, side view, barrel right, drum magazine (#4a4a4a circle), wooden pistol grip (#8b6914)` |
| `knife_common.png` | `pixel art combat knife, blade right, polished blade (#8c8c8c + #ffffff edge), dark handle (#4a4a4a wrapped), crossguard` |
| `dmg_common.png` | `pixel art bullet pointing right, yellow body (#ffcc00 + #ff6600 rear shadow), small spark at tip (#ffffff + #ff6600)` |
| `dmg_rare.png` | `same bullet × 2 stacked + small upward arrow above, blue tier border` |
| `dmg_epic.png` | `pixel art skull with crosshair overlay, dark gray skull (#6b6b6b), red crosshair (#cc0000), purple tier border` |
| `spd_common.png` | `pixel art military boot side view right, olive green (#5a6e3a + #3d4a28 shadow), black sole (#1a1a2e)` |
| `spd_rare.png` | `same boot + 3 horizontal speed lines to the right (#4a9eff), blue tier border` |
| `hp_common.png` | `pixel art military ration can, front view, olive body (#5a6e3a), green cross label (#5a8a3a), lid (#6b6b6b)` |
| `hp_rare.png` | `pixel art armor plate, front view, dark metal (#4a4a4a + #6b6b6b bevel), 4 rivets (#8c8c8c), blue tier border` |
| `hp_epic.png` | `pixel art full tactical vest with plates, front view, dark metal + blue plates (#2a4a7a), purple tier border` |
| `luck_common.png` | `pixel art dog tag / nieśmiertelnik on chain, silver (#8c8c8c + #6b6b6b shadow), star motif (#ffd700)` |
| `luck_rare.png` | `pixel art 4-leaf clover, front view, bright green (#5a8a3a + #3a6a2a shadow), blue tier border` |
| `rng_common.png` | `pixel art binoculars, front view, dark body (#4a4a4a + #6b6b6b top highlight), two blue lenses (#4a9eff + #ffffff glint)` |
| `rng_rare.png` | `pixel art sniper scope, side view, dark housing (#4a4a4a), crosshair visible in lens (#ffffff thin lines), blue tier border` |
| `fr_common.png` | `pixel art mechanical gear, single large gear, metal gray (#6b6b6b + #8c8c8c highlight), small lightning bolt center (#e07020)` |
| `fr_rare.png` | `pixel art 3 gears meshing + lightning bolt, blue tier border` |
| `arm_common.png` | `pixel art tactical vest, front view, dark olive (#3d4a28 + #5a6e3a highlight), simple pouches` |
| `arm_rare.png` | `pixel art vest + 2 armor plates (#2a4a7a + #4a6e9e), visible rivets, blue tier border` |
| `regen_common.png` | `pixel art first aid kit, front view, dark green body (#3d4a28), bold red cross (#cc0000 × on #ffffff square)` |
| `regen_rare.png` | `same kit + green pulse line radiating from cross (#5a8a3a wave), blue tier border` |

#### Przykładowy pełny prompt (rifle_rare.png):

```
Generate in the EXACT SAME pixel art style and outline thickness as the
reference image. [PREFIX KARTY — TIER_FRAME: blue tactical frame
(#1a4a7a base + #4a9eff inner glow line 1px), TIER_BADGE: #4a9eff left stripe,
ICON_AREA: pixel art assault rifle, side view, barrel pointing right,
dark gray metal body (#4a4a4a + #8c8c8c highlight), wooden stock (#8b6914),
banana magazine (#4a4a4a), same compact proportions as WAR MEAT weapon sprites]
```

Po wygenerowaniu: WRZUC_SPRITE → kategoria `cards` → resize **192x256**.

---

### 10.4 Kompletna lista promptów — kopiuj-wklej

> **Użycie:** Każdy prompt jest gotowy do wklejenia w AI Studio (Nano Banana Pro, **3:4**, 1K).
> Dołącz `Assault.png` jako image reference. Zapisz plik o podanej nazwie → wrzuć w WRZUC_SPRITE → kategoria `cards`.

**CARD_BASE** (wspólna część — wklejona w każdym prompcie poniżej jako `[BASE]`):
```
Generate in the EXACT SAME pixel art style and outline thickness as the reference image.
2D game UI card sprite, pixel art, frontal view, portrait orientation (3:4 ratio).
Style: Enter the Gungeon military briefing card — serious, no fantasy.
Hard pixel edges, NO anti-aliasing, 2px dark navy outline (#1a1a2e) on all shapes, flat shading max 3 tones, NO gradients.
CARD LAYOUT: outer frame [FRAME], corner metal rivets (#8c8c8c + #1a1a2e).
Top bar (12% height): #1a1a2e solid background, [BADGE] colored 8px left stripe — CLEAN DARK SURFACE, no text, no lines (game engine renders item name on top).
Center/art (40% height): dark #0d0d1a solid panel, [ICON] centered filling ~80% of center area width, positioned close to top bar.
Stats area (28% height): #111122 solid background — CLEAN DARK SURFACE, no lines, no text (game engine renders DMG/fire rate/range on top).
Bottom button bar (20% height): gray steel background (#3a3a4a base + #4a4a5a top highlight + #2a2a3a bottom shadow) — TALLER steel beam.
Background: FLAT SOLID WHITE #FFFFFF outside card boundary only (auto-removed by pipeline).
```

> ⚠️ **WAŻNE**: Brak placeholderów — tekst (nazwa, statystyki) renderuje Godot. Obszary top bar i bottom muszą być **czyste ciemne powierzchnie** bez żadnych linii ani znaków.

#### 🔫 KARTY SHOP — BRONIE

**`rifle_common.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a base + #6b6b6b inner bevel), badge stripe #6b6b6b. Icon: assault rifle side view barrel pointing right, dark gray metal body (#4a4a4a + #8c8c8c top highlight), curved banana magazine (#4a4a4a), wooden stock (#8b6914 + #6b5a14 shadow), sights (#4a4a4a), barrel tip (#8c8c8c).
```

**`rifle_uncommon.png`**
```
[BASE] Frame: green military (#3a5a2a + #5a8a3a highlight), badge stripe #5a8a3a. Icon: assault rifle barrel right, dark gray body (#4a4a4a + #8c8c8c), banana magazine, wooden stock (#8b6914), sights on top.
```

**`rifle_rare.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff inner glow 1px), badge stripe #4a9eff. Icon: assault rifle barrel right, gray body (#4a4a4a + #8c8c8c), banana magazine, wooden stock (#8b6914), sights.
```

**`rifle_epic.png`**
```
[BASE] Frame: purple arcane (#4a2a6a + #7a3a9a highlight), badge stripe #7a3a9a. Icon: assault rifle barrel right, dark body (#4a4a4a + #6b6b6b), banana magazine, wooden stock (#8b6914), sights.
```

**`rifle_legendary.png`**
```
[BASE] Frame: gold ornate (#8a6a10 + #ffd700 glow 2px, star corner motifs), badge stripe #ffd700. Icon: assault rifle barrel right, golden body (#c8a020 + #ffd700 highlight), banana magazine with gold inlay, wooden stock (#8b6914 + gold trim), ornate engravings on receiver.
```

**`shotgun_common.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b bevel), badge stripe #6b6b6b. Icon: pump-action shotgun barrel right, wide receiver (#4a4a4a + #8c8c8c top), wooden pump forend under barrel (#8b6914), wooden stock (#8b6914 + #6b5a14 shadow), tube magazine (#4a4a4a).
```

**`shotgun_uncommon.png`**
```
[BASE] Frame: green military (#3a5a2a + #5a8a3a), badge stripe #5a8a3a. Icon: pump-action shotgun barrel right, wide receiver (#4a4a4a + #8c8c8c), wooden forend and stock (#8b6914), tube magazine.
```

**`shotgun_rare.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow 1px), badge stripe #4a9eff. Icon: pump-action shotgun barrel right, wide receiver (#4a4a4a + #8c8c8c), wooden forend and stock (#8b6914), tube magazine.
```

**`shotgun_epic.png`**
```
[BASE] Frame: purple arcane (#4a2a6a + #7a3a9a), badge stripe #7a3a9a. Icon: pump-action shotgun barrel right, wide receiver (#4a4a4a + #8c8c8c), wooden forend and stock (#8b6914).
```

**`shotgun_legendary.png`**
```
[BASE] Frame: gold ornate (#8a6a10 + #ffd700 glow, star corners), badge stripe #ffd700. Icon: pump-action shotgun barrel right, golden receiver (#c8a020 + #ffd700 highlight), golden-trimmed wooden stock (#8b6914 + #ffd700 trim), ornate receiver engravings.
```

**`pistol_common.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #6b6b6b. Icon: compact pistol barrel right, black frame (#4a4a4a), gray slide (#8c8c8c + #6b6b6b), checkered grip (#1a1a2e + #4a4a4a pattern), hammer (#4a4a4a), short barrel (#8c8c8c).
```

**`pistol_uncommon.png`**
```
[BASE] Frame: green military (#3a5a2a + #5a8a3a), badge stripe #5a8a3a. Icon: compact pistol barrel right, black frame (#4a4a4a), gray slide (#8c8c8c), checkered grip, hammer.
```

**`pistol_rare.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow), badge stripe #4a9eff. Icon: compact pistol barrel right, black frame (#4a4a4a), gray slide (#8c8c8c), checkered grip, small tactical light under barrel (#ffd700 glow dot).
```

**`pistol_epic.png`**
```
[BASE] Frame: purple arcane (#4a2a6a + #7a3a9a), badge stripe #7a3a9a. Icon: compact pistol barrel right, dark frame (#4a4a4a), gray slide, checkered grip, laser sight red dot (#cc0000).
```

**`pistol_legendary.png`**
```
[BASE] Frame: gold ornate (#8a6a10 + #ffd700 glow, star corners), badge stripe #ffd700. Icon: compact pistol barrel right, golden frame (#c8a020 + #ffd700 highlight), golden slide, ornate checkered grip with gold inlay.
```

**`smg_common.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #6b6b6b. Icon: compact SMG barrel right, all-metal body (#4a4a4a + #8c8c8c), curved magazine below receiver, short barrel with flash hider (#8c8c8c), folding stock (#4a4a4a).
```

**`smg_uncommon.png`**
```
[BASE] Frame: green military (#3a5a2a + #5a8a3a), badge stripe #5a8a3a. Icon: compact SMG barrel right, all-metal (#4a4a4a + #8c8c8c), curved magazine, flash hider, folding stock.
```

**`smg_rare.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow), badge stripe #4a9eff. Icon: compact SMG barrel right, all-metal (#4a4a4a + #8c8c8c), curved magazine, flash hider, folding stock, small red dot sight (#cc0000 dot on #4a4a4a mount).
```

**`smg_epic.png`**
```
[BASE] Frame: purple arcane (#4a2a6a + #7a3a9a), badge stripe #7a3a9a. Icon: compact SMG barrel right, dark body (#4a4a4a + #6b6b6b), extended magazine, suppressor at muzzle (#6b6b6b cylinder).
```

**`smg_legendary.png`**
```
[BASE] Frame: gold ornate (#8a6a10 + #ffd700 glow, star corners), badge stripe #ffd700. Icon: compact SMG barrel right, golden body (#c8a020 + #ffd700 highlight), curved magazine with gold inlay, ornate receiver engravings.
```

**`sniper_common.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #6b6b6b. Icon: bolt-action sniper VERY LONG barrel pointing right (barrel dominates ~65% of width), gray barrel (#8c8c8c), scope (#4a4a4a housing + #ffffff lens + #ffd700 reflex dot), wooden stock (#8b6914 + #6b5a14), folded bipod (#4a4a4a), bolt handle knob (#4a4a4a).
```

**`sniper_uncommon.png`**
```
[BASE] Frame: green military (#3a5a2a + #5a8a3a), badge stripe #5a8a3a. Icon: bolt-action sniper very long barrel right (#8c8c8c), scope (#4a4a4a + #ffffff lens), wooden stock (#8b6914), bipod, bolt handle.
```

**`sniper_rare.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow), badge stripe #4a9eff. Icon: bolt-action sniper very long barrel right (#8c8c8c), advanced scope with blue lens (#4a9eff + #ffffff glint), wooden stock (#8b6914), deployed bipod legs, bolt handle.
```

**`sniper_epic.png`**
```
[BASE] Frame: purple arcane (#4a2a6a + #7a3a9a), badge stripe #7a3a9a. Icon: bolt-action sniper very long barrel right (#6b6b6b), large scope (#4a4a4a + #4a9eff lens glow), black synthetic stock (#4a4a4a), suppressor at muzzle (#6b6b6b cylinder).
```

**`sniper_legendary.png`**
```
[BASE] Frame: gold ornate (#8a6a10 + #ffd700 glow, star corners), badge stripe #ffd700. Icon: bolt-action sniper very long barrel right, golden barrel trim (#c8a020 + #8c8c8c), ornate scope gold housing (#c8a020 + #ffd700 lens glint), golden-inlaid wooden stock (#8b6914 + #ffd700), bipod gold tips.
```

**`grenade_common.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #6b6b6b. Icon: grenade launcher barrel right, thick stubby body (#4a4a4a + #6b6b6b), wide funnel barrel (#8c8c8c), round drum magazine (#4a4a4a + 6 small #1a1a2e dots), wooden grip (#8b6914 + #6b5a14), olive strap (#5a6e3a).
```

**`grenade_uncommon.png`**
```
[BASE] Frame: green military (#3a5a2a + #5a8a3a), badge stripe #5a8a3a. Icon: grenade launcher barrel right, thick body (#4a4a4a + #6b6b6b), wide barrel (#8c8c8c), drum magazine, wooden grip (#8b6914).
```

**`grenade_rare.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow), badge stripe #4a9eff. Icon: grenade launcher barrel right, thick body (#4a4a4a + #6b6b6b), wide barrel (#8c8c8c), drum magazine, wooden grip (#8b6914), targeting reticle (#4a9eff) on side.
```

**`grenade_epic.png`**
```
[BASE] Frame: purple arcane (#4a2a6a + #7a3a9a), badge stripe #7a3a9a. Icon: grenade launcher barrel right, heavy dark body (#4a4a4a), extra-wide barrel (#6b6b6b), large drum magazine, rubber grip (#4a4a4a).
```

**`grenade_legendary.png`**
```
[BASE] Frame: gold ornate (#8a6a10 + #ffd700 glow, star corners), badge stripe #ffd700. Icon: grenade launcher barrel right, golden body (#c8a020 + #ffd700 barrel highlight), ornate drum magazine with gold inlay, wooden grip with gold trim (#8b6914 + #ffd700).
```

**`melee_common.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #6b6b6b. Icon: combat knife blade pointing right, polished blade (#8c8c8c + #ffffff top edge + #6b6b6b lower shadow), crossguard (#4a4a4a), wrapped handle (#4a4a4a + 5 thin #1a1a2e wrap lines), pommel (#8b6914).
```

**`melee_uncommon.png`**
```
[BASE] Frame: green military (#3a5a2a + #5a8a3a), badge stripe #5a8a3a. Icon: combat knife blade right, polished blade (#8c8c8c + #ffffff edge), crossguard (#4a4a4a), wrapped handle (#4a4a4a + wrap lines), pommel (#8b6914).
```

**`melee_rare.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow), badge stripe #4a9eff. Icon: combat knife blade right, serrated spine on top (#6b6b6b zigzag), polished blade (#8c8c8c + #ffffff edge), blue-wrapped handle (#2a4a7a + #4a9eff highlight), crossguard (#4a4a4a).
```

**`melee_epic.png`**
```
[BASE] Frame: purple arcane (#4a2a6a + #7a3a9a), badge stripe #7a3a9a. Icon: combat knife blade right, dark blade with fuller groove (#4a4a4a + #6b6b6b edge), thick crossguard (#4a4a4a), purple-wrapped handle (#4a2a6a + #7a3a9a thread).
```

**`melee_legendary.png`**
```
[BASE] Frame: gold ornate (#8a6a10 + #ffd700 glow, star corners), badge stripe #ffd700. Icon: combat knife blade right, golden blade (#c8a020 + #ffd700 edge highlight), ornate golden crossguard with engravings, golden-wrapped handle (#c8a020 + #ffd700 thread accents).
```

---

#### 👤 KARTY SHOP — REKRUCI
> Jeden PNG per klasa. Plik: `assets/sprites/ui/cards/shop/recruit_{class}.png`
> Ikona: **close-up górnej części kiełbasy** — z charakterystycznym nakryciem głowy i kolorem casing.
> ⚠️ **Dwa image reference jednocześnie** (AI Studio pozwala na kilka załączników):
> 1. `rifle_common.png` — struktura karty, styl pixel art ramki
> 2. `Assault.png` — styl kiełbasy, proporcje, outline, paleta
> Frame: niebieski taktyczny, badge stripe: #4a9eff.

**`recruit_assault.png`**
```
Generate in the EXACT SAME pixel art style, palette and outline thickness as the reference image. [BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow 1px), badge stripe #4a9eff. Icon: close-up portrait of FRANKFURTER sausage soldier (upper ~60% of body), 3/4 view facing slightly right. Sausage casing: warm orange-pink (#e8a060 base, #b86a30 shadow left, #f0c090 highlight right). Two small earnest dark eyes — completely deadpan. Round gray combat helmet (#6b6b6b + #4a4a4a shadow + #8c8c8c highlight) directly on sausage top, black chin strap (#1a1a2e). Dark tactical vest top visible (#4a4a4a), shoulder straps, 2 magazine pouches, small gold regiment patch (#ffd700).
```

**`recruit_sniper.png`**
```
Generate in the EXACT SAME pixel art style, palette and outline thickness as the reference image. [BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow 1px), badge stripe #4a9eff. Icon: close-up portrait of CHORIZO sausage soldier (upper ~60%), 3/4 view right. Sausage casing: reddish-brown (#c06030 base, #8a4020 shadow, #d08050 highlight), subtle dark speckle texture. Two small calculating deadpan eyes. Flat soft beret (#a0845c + #6b5a3a shadow) on sausage top, small metal badge (#8c8c8c). Raised goggles on sausage surface (gray #4a4a4a frame + #4a9eff lenses). Slim dark olive tactical vest top (#3d4a28), bandolier strap with brass bullet tips (#ffd700).
```

**`recruit_medic.png`**
```
Generate in the EXACT SAME pixel art style, palette and outline thickness as the reference image. [BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow 1px), badge stripe #4a9eff. Icon: close-up portrait of WEISSWURST sausage soldier (upper ~60%), 3/4 view right. Sausage casing: cream-white (#e8d0a0 base, #c0a870 shadow, #f5ecd0 highlight) — noticeably pale. Two small caring deadpan eyes. Round gray helmet (#6b6b6b + #4a4a4a shadow) with bold WHITE CROSS (#ffffff) on side. Dark tactical vest top (#4a4a4a), large red cross patch on left chest (#cc0000 on #ffffff).
```

**`recruit_engineer.png`**
```
Generate in the EXACT SAME pixel art style, palette and outline thickness as the reference image. [BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow 1px), badge stripe #4a9eff. Icon: close-up portrait of KIELBASA SLASKA sausage soldier (upper ~60%), 3/4 view right. Sausage casing: smoky tan (#d49050 base, #9a6020 shadow, #e0b070 highlight), faint diagonal casing creases. Two small focused deadpan eyes. Gray combat helmet (#6b6b6b) with thick ORANGE stripe (#e07020) across top. Goggles hanging around sausage (gray #4a4a4a frame + #4a9eff lenses). Olive vest top (#5a6e3a).
```

**`recruit_scout.png`**
```
Generate in the EXACT SAME pixel art style, palette and outline thickness as the reference image. [BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow 1px), badge stripe #4a9eff. Icon: close-up portrait of PAROWKA sausage soldier (upper ~60%), 3/4 view right — NOTICEABLY THINNER AND SMALLER than other sausage soldiers. Sausage casing: pale pinkish-tan (#e8a060 lighter, #d09050 shadow, #f0c080 highlight), smooth minimal texture. Two small alert quick-darting deadpan eyes. Tactical headscarf (#3d4a28) tied tightly around slim sausage top. Slim olive vest (#5a6e3a minimal pouches). Small compact binoculars on chest strap (#4a4a4a).
```

**`recruit_heavy.png`**
```
Generate in the EXACT SAME pixel art style, palette and outline thickness as the reference image. [BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow 1px), badge stripe #4a9eff. Icon: close-up portrait of BRATWURST sausage soldier (upper ~60%), 3/4 view right — VISIBLY FATTER AND WIDER (~15% broader) than other sausage soldiers. Sausage casing: thick golden-brown (#d49050 base, #9a5a20 deep shadow, #e8c080 bright highlight), slightly grilled-looking with subtle darker stripe on top. Two small stoic immovable deadpan eyes. Gray combat helmet (#6b6b6b) WIDE to fit fat sausage, extra brow guard plate (#4a4a4a). Thick blue armor plates (#2a4a7a + #4a6e9e highlight) bolted onto sausage body, 4+ metal rivets (#8c8c8c).
```

---

#### 🎒 KARTY SHOP — PASYWKI
> Jeden PNG per pasywka (bez tierów). Plik: `assets/sprites/ui/cards/shop/{id}.png`

**`lucky_charm.png`**
```
[BASE] Frame: gold ornate (#8a6a10 + #ffd700 glow 2px, star corners), badge stripe #ffd700. Icon: military dog tag on chain, rectangular silver tag (#8c8c8c + #6b6b6b shadow), engraved gold star center (#ffd700), chain links above (#6b6b6b).
```

**`speed_amulet.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow 1px), badge stripe #4a9eff. Icon: round amulet pendant front view, dark metal ring (#4a4a4a + #6b6b6b bevel), cyan glowing center gem (#4a9eff + #ffffff core glint), thin chain above (#6b6b6b).
```

**`steel_armor.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b bevel), badge stripe #6b6b6b. Icon: rectangular steel chest plate front view, dark metal (#4a4a4a + #8c8c8c top bevel), horizontal reinforcement groove (#1a1a2e line center), 4 corner rivets (#8c8c8c).
```

**`scope.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #6b6b6b. Icon: rifle scope side view, cylindrical dark housing (#4a4a4a + #6b6b6b top), two adjustment turrets (#4a4a4a + #8c8c8c tops), objective lens right (#cc3333 + #ffffff glint), eyepiece left (smaller circle).
```

**`adrenaline.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #ff6600. Icon: military syringe side view pointing right, glass body (#8c8c8c + #ffffff highlight), orange liquid inside (#ff6600 + #ff9900 highlight), metal plunger (#4a4a4a), needle tip (#8c8c8c).
```

**`combat_knife.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #cc2222. Icon: combat knife blade pointing right, polished blade (#8c8c8c + #ffffff edge + #6b6b6b lower shadow), crossguard (#4a4a4a), wrapped handle (#4a4a4a + wrap lines), pommel (#8b6914).
```

**`kevlar_vest.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #5a6e3a. Icon: tactical vest front view, olive body (#3d4a28 + #5a6e3a center), 2 front pouches (#4a4a4a), shoulder straps (#4a4a4a), zipper center (#8c8c8c), no armor plates.
```

**`energy_drink.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #20cc66. Icon: military energy drink can front view, dark green cylindrical body (#1a3a2a + #3a6a4a highlight), bright green label stripe center (#20cc66), silver lid (#8c8c8c + #ffffff glint), pull tab (#6b6b6b).
```

**`field_medkit.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #cc3344. Icon: military first aid kit front view, rectangular dark green body (#3d4a28 + #5a6e3a left edge), bold red cross (#cc0000 on #ffffff square), gray handle top (#6b6b6b), metal clasp (#8c8c8c).
```

**`kinetic_shield.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow 1px), badge stripe #4ab8ff. Icon: hexagonal energy shield front view, outer ring dark metal (#4a4a4a + #6b6b6b), inner glowing field (#4a9eff + #88ccff center + #ffffff core dot), 3 reinforcement struts (#4a4a4a).
```

**`laser_sight.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #ff2222. Icon: compact laser sight module side view, rectangular dark body (#4a4a4a + #6b6b6b top), red laser beam extending right (#cc0000 line + #ff4444 glow 1px wide), activation button on top (#8c8c8c circle).
```

**`tactical_backpack.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #8a7a4a. Icon: military backpack front view, olive body (#5a6e3a + #3d4a28 shadow sides), front pocket with metal clasp (#4a4a4a + #8c8c8c buckle), shoulder straps (#3d4a28), molle loops on sides (#4a4a4a horizontal lines).
```

**`assault_boots.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #6a5a28. Icon: military combat boot side view pointing right, olive green body (#5a6e3a + #3d4a28 shadow lower half), black rubber sole (#1a1a2e), boot laces (#8c8c8c thin lines), ankle buckle strap (#4a4a4a + #8c8c8c).
```

**`gas_mask.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #3a4a3a. Icon: military gas mask front view, dark rubber body (#3d4a28 + #4a4a4a trim), two circular eye lenses (#1a1a2e ring + #4a9eff tinted glass + #ffffff glint), round filter canister below center (#4a4a4a cylinder + #6b6b6b holes), head strap sides (#3d4a28).
```

**`incendiary_mod.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #ff7010. Icon: incendiary grenade side view, olive cylindrical body (#5a6e3a + #3d4a28 shadow), yellow safety ring (#ffd700), orange flame burst at top (#ff6600 + #ffcc00 center + #ff3300 outer), pin ring (#8c8c8c circle left).
```

**`binoculars.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #4a7a4a. Icon: binoculars front view, two cylinders side by side (#4a4a4a + #6b6b6b top highlight), two circular lenses (#4a9eff fill + #ffffff glint top-left each), center bridge connector (#4a4a4a), rubber grip texture (#1a1a2e thin lines).
```

---

#### ⬆️ KARTY UPGRADE

**`dmg_common.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #6b6b6b. Icon: single bullet pointing right, yellow body (#ffcc00 + #ff6600 rear shadow), bright spark at tip (#ffffff core + #ff6600 rays), 1px outline (#1a1a2e).
```

**`dmg_rare.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow), badge stripe #4a9eff. Icon: two bullets stacked pointing right (#ffcc00 + #ff6600), small upward arrow above bullets (#4a9eff, 3px wide), spark at upper bullet tip (#ffffff + #ff6600).
```

**`dmg_epic.png`**
```
[BASE] Frame: purple arcane (#4a2a6a + #7a3a9a), badge stripe #7a3a9a. Icon: pixel art skull facing forward, gray skull (#6b6b6b + #8c8c8c highlight + #4a4a4a shadow), red crosshair overlay (#cc0000 cross lines 1px), white glint in eye sockets (#ffffff 2px dots).
```

**`spd_common.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #6b6b6b. Icon: military boot side view pointing right, olive green body (#5a6e3a + #3d4a28 lower shadow), black sole (#1a1a2e), boot laces (#8c8c8c thin lines).
```

**`spd_rare.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow), badge stripe #4a9eff. Icon: military boot side view right (#5a6e3a + #3d4a28), black sole (#1a1a2e), 3 horizontal speed lines extending right from heel (#4a9eff, long/medium/short decreasing).
```

**`hp_common.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #6b6b6b. Icon: military ration can front view, cylindrical olive body (#5a6e3a + #3d4a28 shadow right side), green label with white cross (#5a8a3a label + #ffffff cross), gray metal lid (#6b6b6b + #8c8c8c highlight), bottom rim (#4a4a4a).
```

**`hp_rare.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow), badge stripe #4a9eff. Icon: rectangular armor plate front view, dark metal (#4a4a4a + #6b6b6b bevel on top-left edges), 4 metal rivets at corners (#8c8c8c + #1a1a2e ring), horizontal groove lines (#1a1a2e 1px).
```

**`hp_epic.png`**
```
[BASE] Frame: purple arcane (#4a2a6a + #7a3a9a), badge stripe #7a3a9a. Icon: full tactical vest front view, dark body (#3d4a28 + #4a4a4a trim), two large blue chest plates (#2a4a7a + #4a6e9e highlight), 6 rivets on plates (#8c8c8c), side pouches (#4a4a4a), shoulder straps.
```

**`luck_common.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #6b6b6b. Icon: military dog tag (nieśmiertelnik) on chain, rectangular metal tag (#8c8c8c + #6b6b6b shadow right), engraved gold star center (#ffd700), chain links above (#6b6b6b), rounded corners, punch hole top.
```

**`luck_rare.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow), badge stripe #4a9eff. Icon: four-leaf clover front view, 4 round lobes (#5a8a3a + #3a6a2a lower shadow + #88aa55 upper highlight), thin stem (#3a6a2a), small gold center dot (#ffd700), 2px outline (#1a1a2e) per leaf.
```

**`rng_common.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #6b6b6b. Icon: binoculars front view, two cylinders side by side (#4a4a4a + #6b6b6b top highlight), two circular lenses (#4a9eff fill + #ffffff glint top-left), center bridge (#4a4a4a), rubber grip texture (#1a1a2e thin lines).
```

**`rng_rare.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow), badge stripe #4a9eff. Icon: sniper scope side view, cylindrical dark housing (#4a4a4a + #6b6b6b top), adjustment turrets (#4a4a4a knobs + #8c8c8c top), objective lens right (#4a9eff + #ffffff glint), eyepiece left (smaller circle), crosshair in lens (#ffffff thin cross).
```

**`fr_common.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #6b6b6b. Icon: single mechanical gear centered, metal gray (#6b6b6b + #8c8c8c upper teeth + #4a4a4a lower shadow), 8 teeth, circular center hole (#1a1a2e), orange lightning bolt inside hole (#e07020 + #ffcc00 highlight edge).
```

**`fr_rare.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow), badge stripe #4a9eff. Icon: three gears meshing (large left, medium right, small bottom-right), all gray metal (#6b6b6b + #8c8c8c), blue lightning bolt (#4a9eff + #ffffff core) through central gap between gears.
```

**`arm_common.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #6b6b6b. Icon: tactical vest front view, olive body (#3d4a28 + #5a6e3a center panel), 2 front pouches (#4a4a4a + #3d4a28 shadow), shoulder straps (#4a4a4a), zipper line center (#8c8c8c), no armor plates.
```

**`arm_rare.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow), badge stripe #4a9eff. Icon: tactical vest front view with plates, olive body (#3d4a28 + #5a6e3a), two blue chest plates (#2a4a7a + #4a6e9e highlight), 4 rivets per plate (#8c8c8c), side pouches (#4a4a4a), shoulder straps.
```

**`regen_common.png`**
```
[BASE] Frame: dark gray beveled (#4a4a4a + #6b6b6b), badge stripe #6b6b6b. Icon: military first aid kit front view, rectangular dark green body (#3d4a28 + #5a6e3a left edge), bold red cross (#cc0000 on #ffffff square, cross fills most of white area), gray handle top (#6b6b6b), metal clasp bottom center (#8c8c8c).
```

**`regen_rare.png`**
```
[BASE] Frame: blue tactical (#1a4a7a + #4a9eff glow), badge stripe #4a9eff. Icon: military first aid kit front view (#3d4a28 + #5a6e3a), red cross (#cc0000 on #ffffff), gray handle (#6b6b6b), 3 concentric heartbeat wave arcs radiating from cross (#5a8a3a, 1px each, decreasing size outward).
```
---

### 10.5 Update toolchain — WRZUC_SPRITE dla kart

Obecny tool (`tools/WRZUC_SPRITE.exe` / `tools/wrzuc_web.py`) usuwa białe tło i snapuje paletę.
Karty wymagają **dodatkowego trybu** — bo mają ciemne tło (nie białe) i wymagają innych rozmiarów.

#### Nowa kategoria `cards` w WRZUC_SPRITE:

```
Drag & drop PNG → wybierz kategoria: cards
→ Usuwa zewnętrzne białe tło (#FFFFFF outside card boundary)
→ NIE usuwa ciemnego wnętrza karty (próg: tylko piksele DOKŁADNIE #FFFFFF na zewnątrz)
→ NIE snapuje palety (karta ma swój własny styl, nie musi pasować do sprite palety postaci)
→ Resize: 192×256 (portrait, 3:4)
→ Zapisuje do: assets/sprites/ui/cards/{subfolder}/{filename}.png
```

#### Subfoldery:
```
assets/sprites/ui/cards/
  shop/      ← karty broni i pasywek (rifle_rare.png, shotgun_common.png ...)
  upgrade/   ← karty upgrade'ów (dmg_epic.png, spd_rare.png ...)
```

#### Implementacja update do `tools/wrzuc_web.py`:

```python
# Dodaj do kategorii w CATEGORY_CONFIG:
"cards": {
    "output_dir": "assets/sprites/ui/cards",
    "resize": (192, 256),
    "remove_bg": True,
    "bg_threshold": 5,      # tylko DOKŁADNIE białe piksele na zewnątrz
    "apply_palette": False,  # NIE snapuj palety WAR MEAT
    "filter": Image.LANCZOS,  # LANCZOS dla UI (nie Nearest jak dla sprite'ów)
    "subfolder_prompt": True,  # zapytaj: shop/ czy upgrade/?
}
```

#### Różnica od trybu sprite'ów:
| | Sprite (postacie/wrogowie) | Cards (UI) |
|--|---------------------------|------------|
| Resize filter | **Nearest Neighbor** (zachowuje piksele) | **Lanczos** (płynne skalowanie UI) |
| Paleta | ✅ Snapuje WAR MEAT palette | ❌ Nie snapuje |
| BG removal | Agresywne (próg 30) | Ostrożne (próg 5) |
| Rozmiar | Per asset (tabela 0.4) | Zawsze 192×256 |

---

### 10.6 Implementacja w kodzie (plan)

**ShopCard** — do dodania:
```gdscript
# W ShopCard._build_ui():
var icon_rect := TextureRect.new()
icon_rect.texture = item.icon_texture  # WeaponData lub PassiveItem
icon_rect.custom_minimum_size = Vector2(64, 64)
icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
```

**UpgradeCard** — do dodania w `upgrade_panel.gd:_make_card()`:
```gdscript
# Ikona upgrade (jeśli UpgradeData ma icon_texture)
if upgrade.icon_texture:
    var icon := TextureRect.new()
    icon.texture = upgrade.icon_texture
    icon.custom_minimum_size = Vector2(48, 48)
    icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    card.add_child(icon)
```

**Card Frame 9-patch** — zamiast StyleBoxFlat w kodzie:
```gdscript
# Po wygenerowaniu card_frame_*.png:
var sb := StyleBoxTexture.new()
sb.texture = preload("res://assets/sprites/ui/card_frame_rare.png")
sb.set_margin_all(20)   # 9-patch margins
card.add_theme_stylebox_override("panel", sb)
```

---

### 10.5 Status kart — tracker

#### 👤 Rekruci (6 kart)

| Karta | Status |
|-------|--------|
| recruit_assault | ✅ |
| recruit_sniper | ⬜ |
| recruit_medic | ✅ |
| recruit_engineer | ⬜ |
| recruit_scout | ⬜ |
| recruit_heavy | ⬜ |

#### 🔫 Bronie (7 × 5 tierów = 35 kart)

| Karta | common | uncommon | rare | epic | legendary |
|-------|--------|----------|------|------|-----------|
| rifle | ✅ | ✅ | ✅ | ✅ | ✅ |
| shotgun | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| pistol | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| smg | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| sniper | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| grenade | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| melee | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

#### 🎒 Pasywki (16 kart)

| Karta | Status |
|-------|--------|
| lucky_charm | ✅ |
| speed_amulet | ✅ |
| steel_armor | ✅ |
| scope | ✅ |
| adrenaline | ✅ |
| combat_knife | ✅ |
| kevlar_vest | ✅ |
| energy_drink | ✅ |
| field_medkit | ✅ |
| kinetic_shield | ✅ |
| laser_sight | ⬜ |
| tactical_backpack | ⬜ |
| assault_boots | ⬜ |
| gas_mask | ⬜ |
| incendiary_mod | ⬜ |
| binoculars | ⬜ |

#### ⬆️ Upgrade'y (8 × 3 rzadkości = 24 karty)

| Karta | common | rare | epic |
|-------|--------|------|------|
| dmg | ⬜ | ⬜ | ⬜ |
| spd | ⬜ | ⬜ | — |
| hp | ⬜ | ⬜ | ⬜ |
| luck | ⬜ | ⬜ | — |
| rng | ⬜ | ⬜ | — |
| fr | ⬜ | ⬜ | — |
| arm | ⬜ | ⬜ | — |
| regen | ⬜ | ⬜ | — |

---

## 11. Pipeline produkcji assetów

### Narzędzia
- **Gemini (Nano Banana / Imagen)** — generowanie sprite'ów high-res (≥1024 px) z promptów (patrz prompty w sekcjach 1-6)
- **Aseprite** lub **Pixelorama** (darmowe) — post-processing: **downscale (Nearest Neighbor)**, czyszczenie, color quantize do palety, usuwanie tła
- **Inkscape** — dla SVG (Hand, Shadow, ikony pasywek, loot)
- **Rozdzielczości docelowe** (po downscale): 128 px postacie, 64 px tile'e, 32-256 px reszta (patrz tabela 0.4)
- **Export**: PNG z przezroczystym tłem, podkatalogi `assets/sprites/`

### Workflow generowania (Imagen 3 / Nano Banana Pro + image conditioning)
1. **Generuj sprite wzorcowy** (Assault) z Nano Banana Pro w AI Studio (1:1, 1K, prompt z sekcji 1.1, BEZ obrazu referencyjnego). Prompt zawiera "transparent background" + fallback magenta `#FF00FF`.
2. **Palette enforce**: `python tools/palette_enforcer.py raw.png clean.png` — snapuje kolory do palety WAR MEAT (eliminuje dryfowanie hex).
3. **Usuń tło (jeśli model dorysował)**: `python tools/remove_bg_magenta.py clean.png final.png` — magenta `#FF00FF` → alpha=0. Dla białego tła: `--color FFFFFF`.
4. **Downscale w Aseprite/Pixelorama** (jeśli output > docelowego rozmiaru): Image → Resize → **Nearest Neighbor** → [docelowy rozmiar z tabeli 0.4].
5. **Każdy kolejny sprite**: dołącz pierwszy sprite (Assault.png) jako image reference w AI Studio + prompt z frazą `"Generate in the EXACT SAME pixel art style as the reference image"`. To zapewnia spójność stylu między postaciami.
6. **Sprawdź kierunek** (sprite musi patrzeć W PRAWO — flip_h w kodzie obraca na lewo).
7. **Export** PNG do `assets/sprites/[kategoria]/`.
8. **Godot import**: Texture Filter = **Linear**, Mipmaps = Off, Compress = Lossless, Fix Alpha Border = On.

### Wspólny prefix promptu (dodaj do każdego)
> **Prefix (postacie/wrogowie/bossowie):** `2D game sprite, pixel art style, single static sprite, near front-facing 3/4 view angled slightly to the right (Brotato-style — character faces viewer but oriented rightwards, both shoulders and face visible). NOT side profile, NOT pure front, NOT isometric. FLAT SOLID WHITE background #FFFFFF (no gradients, no vignette — auto-removed by WRZUC_SPRITE tool), NO scene, NO environment, NO ground shadow, isolated subject only. Hard pixel edges, NO anti-aliasing, NO gradients, flat fill only with max 3 shades per element. Style: Brotato meets Enter the Gungeon. Game asset for War Meat military roguelite.`
>
> **Prefix (bronie):** identyczny ALE `side view, weapon laid flat horizontally, barrel pointing right` zamiast 3/4 view (bronie orbitują w `WeaponPivot` niezależnie od body — 3/4 weapon byłoby dziwne).
>
> **UWAGA:** Spójność między sprite'ami osiągamy przez **image conditioning** — do każdego promptu (poza pierwszym wzorcowym Assaultem/Karabinem/Gruntem) dołącz odpowiedni sprite-wzorzec jako obraz referencyjny w AI Studio. Po generacji uruchom `palette_enforcer.py` — wymusza dokładną paletę WAR MEAT.

### Kolejność prac (priorytet) — NEW STYLE

| Prio | Kategoria | Ilość | Status | Opis |
|------|-----------|-------|--------|------|
| **P0** | System setup | 0 assetów | 🟡 częściowo | ✅ outline shader, ⬜ flip_h, ⬜ wobble, ⬜ recoil, ⬜ hit_flash, ⬜ death splat, ⬜ **Texture Filter Linear w Godot project settings** |
| **P1** | Żołnierze (128 px PNG) | 6+1+1 | 🔴 0/8 | Wszyscy do regeneracji w Imagen 3 / Nano Banana Pro (stare SVG to placeholdery). Assault = wzorzec stylu. |
| **P2** | Wrogowie (64-112 px PNG) | 5 | 🔴 0/5 | Wszyscy do regeneracji. Grunt = wzorzec stylu wrogów. |
| **P3** | Bronie (80-160 px PNG) | 7 | 🔴 0/7 | Wszystkie do regeneracji. Karabin = wzorzec stylu broni. 🔸 Gun Collection ref dla SMG/Sniper/Granatnik/Nóż |
| **P4** | Pociski + FX (32-256 px) | 5+7 | 🔴 0/12 | Wszystkie `_draw()` do zastąpienia |
| **P5** | Loot + UI | 2+30 | 🟡 2/32 | ✅ Coin SVG, ✅ Crate SVG (mogą zostać). ⬜ Panel/buttons/card frames/ikony do generacji |
| **P6** | Bossowie (192-224 px PNG) | 3+1 | 🔴 0/4 | Wszyscy do regeneracji + 1 shield overlay (SVG, ręcznie) |
| **P7** | Tilemapy (64×64 PNG) | ~30 | 🔴 0/30 | Foldery istnieją (puste). 🔸 Kenney ma ~500 tile'i (16×16 — do upscale lub jako placeholder) |


### Struktura plików (NEW STYLE — głównie PNG)

```
assets/
  sprites/
    soldiers/
      assault.png          🔴 do generacji 128×128 (zastąpi Assault.svg)
      sniper.png           🔴 do generacji 128×128
      medic.png            🔴 do generacji 128×128
      engineer.png         🔴 do generacji 128×128
      scout.png            🔴 do generacji 128×128
      heavy.png            🔴 do generacji 128×128
      Hand.svg             ✅ zostaje (geometryczne SVG)
      Shadow.svg           ✅ zostaje (geometryczne SVG)
    enemies/
      grunt.png            🔴 do generacji 80×80
      rusher.png           🔴 do generacji 64×64
      tank.png             🔴 do generacji 112×112
      shooter.png          🔴 do generacji 80×80
      grenadier.png        🔴 do generacji 96×96
      boss_jungle.png      🔴 do generacji 192×192
      boss_desert.png      🔴 do generacji 192×192
      boss_bunker.png      🔴 do generacji 224×224
      shield_overlay.png   🔴 do generacji 128×128
    weapons/
      karabin.png          🔴 do generacji 128×64 (broń+dłoń, Brotato-style)
      pistolet.png         🔴 do generacji 80×56  (broń+dłoń, Brotato-style)
      strzelba.png         🔴 do generacji 112×72 (broń+dłoń, Brotato-style)
      smg.png              🔴 do generacji 96×56  (broń+dłoń, 🔸 Gun Collection ref)
      sniper.png           🔴 do generacji 160×56 (broń+dłoń, 🔸 Gun Collection ref)
      granatnik.png        🔴 do generacji 128×80 (broń+dłoń, 🔸 Gun Collection ref)
      noz.png              🔴 do generacji 80×48  (broń+dłoń, 🔸 Gun Collection ref)
    projectiles/
      bullet.png           🔴 32×16
      bullet_crit.png      🔴 40×24
      bullet_enemy.png     🔴 32×24
      rocket.png           🔴 48×32
      sniper_trail.png     🔴 48×16
    fx/
      muzzle_flash_01.png  🔴 64×64
      muzzle_flash_02.png  🔴 64×64
      hit_spark_01.png     🔴 48×48
      hit_spark_02.png     🔴 48×48
      death_splat_01.png   🔴 128×128
      death_splat_02.png   🔴 128×128
      death_splat_boss.png 🔴 256×256
    loot/
      coin.svg             ✅ zostaje (SVG OK)
      crate.svg            ✅ zostaje (SVG OK)
      xp_gem.svg           ⬜ opcjonalne, 40×40
    tiles/
      jungle/              🔴 ~10 PNG × 64×64
      desert/              🔴 ~10 PNG × 64×64
      bunker/              🔴 ~10 PNG × 64×64
    ui/
      panel_bg.png         🔴 192×192 9-patch
      button_normal.png    🔴 384×128
      button_hover.png     🔴 384×128
      button_pressed.png   🔴 384×128
      card_frame_common.png    🔴 192×256
      card_frame_uncommon.png  🔴 192×256
      card_frame_rare.png      🔴 192×256
      card_frame_epic.png      🔴 192×256
      card_frame_legendary.png 🔴 192×256
      passive_icons/       🔴 ~16 SVG × 64×64 (skalowalne)
  shaders/
    outline.gdshader     ✅ istnieje (8-sample outline, podłączony do soldiers)
    hit_flash.gdshader   ⬜
    glow_outline.gdshader ⬜
```

> Stare SVG (`Assault.svg`, `Grunt.svg`, etc.) zostają w repo do podmienienia gdy nowe PNG będą gotowe — nie usuwać dopóki nowy nie jest podłączony!

---

## 11. Podsumowanie ilościowe (NEW STYLE)

| Kategoria | Ilość assetów | Format dominujący |
|-----------|---------------|-------------------|
| Żołnierze (body) | 6 | PNG 128×128 |
| Shadow | 1 | SVG (geometryczne) — Hand deprecated (baked into weapons) |
| Wrogowie | 5 | PNG 64-112 px |
| Bossowie + shield | 4 | PNG 128-224 px |
| Bronie | 7 | PNG 80-160 px |
| Pociski | 5 | PNG 32-48 px |
| FX (muzzle, spark, splat) | 7 | PNG 48-256 px |
| Loot | 2-3 | SVG 40-80 px |
| Shaders | 2 | .gdshader |
| Tile'e aren (3 areny) | ~30 | PNG 64×64 |
| UI (panele, buttony, ramki) | ~14 | PNG 9-patch |
| UI ikony pasywek | ~16 | SVG 64×64 |
| **RAZEM** | **~100 assetów** | hybryda PNG + SVG |

Większość to PNG 80-128 px sprite'y — do zrobienia w 2-3 sesje per kategoria z Gemem.

---

## 12. Decyzja projektowa: Facing Direction

**Rekomendacja: Żołnierze patrzą w stronę wroga (weapon target), nie joysticka.**

Argumenty:
- Brotato standard — gracze są przyzwyczajeni
- Auto-aim już działa → naturalne połączenie z flip_h
- "Moonwalk" (uciekanie tyłem do wroga) dodaje dynamikę i humor
- Wrogowie: zawsze flip_h w stronę gracza — bo biegną do niego

Implementacja: 3 linie kodu w `soldier.gd` + 1 linia w `enemy.gd`. Zero dodatkowych sprite'ów.
