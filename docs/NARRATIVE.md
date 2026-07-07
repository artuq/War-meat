# WAR MEAT — Narrative Bible & Story Plan

> **Styl narracji:** Brotato-style — krótkie cutscenki między falami, czarny ekran + tekst + opcjonalny obraz.
> Ton: **serio-absurdalny** — kiełbasy traktują wojnę ze śmiertelną powagą, ale gracz wie że to kiełbasy.
> Cutscenki: dialog_box.tscn (istniejący system) + opcjonalne obrazy generowane w Gemini.

---

## 1. Świat: Planeta Kiełbasiana

**Planeta Kiełbasiana** (oficjalnie: KBZ-7 w galaktycznym katalogu) — błękitna planeta zamieszkana od niepamiętnych czasów przez rasę inteligentnych kiełbas.

Cywilizacja Kiełbasian zorganizowana jest militarnie — każdy obywatel przechodzi szkolenie bojowe. Trzy główne strefy zamieszkane:

| Strefa | Arena w grze | Charakterystyka |
|--------|-------------|-----------------|
| **Puszcza Wędzarnicza** | Dżungla | Gęste lasy, szybcy zwiadowcy, Chorizo zamieszkują |
| **Pustynia Solna** | Pustynia | Otwarte przestrzenie, Snajperzy z dalekim zasięgiem |
| **Forteca Bunkierkowa** | Bunkier | Podziemne fortyfikacje, Ciężcy i Inżynierowie |

---

## 2. Antagoniści: Pożeracze

**Pożeracze** (*Carnivora Antiqua*) — pradawne mięsożerne istoty, które przez miliony lat drzemały głęboko pod powierzchnią Kiełbasiany.

### Kasty Pożeraczy (= typy wrogów w grze)

| Kasta | Wróg w grze | Opis |
|-------|-------------|------|
| **Łazik** | Grunt | Podstawowa kasta robotnicza, pierwsze wyłaniające się spod ziemi |
| **Szturmak** | Rusher | Szybka kasta myśliwska, atakuje falami |
| **Pancerniak** | Tank | Starożytna kasta strażnicza, pokryta skamieniałym pancerzem |
| **Strzelec** | Shooter | Kasta dalekiego zasięgu, cyborgizowana przez miliony lat ewolucji |
| **Bombardier** | Grenadier | Kasta minera, wysadza tunele, tworzy nowe przejścia |
| **Strażnik Puszczy** | Boss Dżungla | Prastarożytny Pożeracz, spał pod korzeniami Puszczy Wędzarniczej |
| **Bóg Pustyni** | Boss Pustynia | Kapłan-Pożeracz, strzegł Wielkiej Pieczęci przez miliony lat |
| **Królowa** | Boss Bunkier | Matka wszystkich Pożeraczy, serce kolonii, ostatnia obudzona |

---

## 3. Prehistoria: Wielka Pożoga

**65 milionów lat temu** — Pożeracze po raz pierwszy wyszli na powierzchnię i napotkali ówczesnych mieszkańców planety: **Kiełbazaury** (*Frankfurterus Rex*, *Chorizosaurus*, *Bratwurstodon*).

Wojna Kiełbazaurów z Pożeraczami trwała **10 000 lat**. Kiełbazaury — mimo prymitywnego uzbrojenia (kamienie, kłody) — wygrały dzięki liczebności i niespożytej energii wędzenia. Pożeraczy wgnano z powrotem pod ziemię i **zapieczętowano Wielką Pieczęcią** — siecią prastarych monolitów zakopanych w strategicznych punktach planety.

Pieczęć przetrwała miliony lat. Kiełbazaury wymarły (z niejasnych przyczyn — prawdopodobnie zbyt dużo soli). Ewoluowały nowe gatunki kiełbas. Historia Wielkiej Pożogi stała się mitem.

**Dziś** — podczas rutynowych prac inżynierskich w Bunkierze Wschodnim, Inżynier Kiełbasa Śląska przypadkowo wierci w jeden z monolitów Pieczęci. Ziemia drży. Coś budzi się po milionach lat snu.

---

## 4. Struktura Aktów

### AKT I: PIERWSZE UDERZENIE (Fale 1–4)
*"Coś wychodzi spod ziemi."*

### AKT II: ESKALACJA (Fale 5–8)
*"To nie jest przypadkowy atak."*

### AKT III: PRADAWNA PRAWDA (Fale 9–12)
*"To już kiedyś było."*

### AKT IV: FINAŁ (Fale 13–15+)
*"Skończymy to raz na zawsze."*

---

## 5. Cutscenki — Skrypty i Prompty

> **Format każdej cutscenki — trzy oddzielne warstwy:**
> - 📺 **DIALOG** — tylko to widzi gracz (czyste linie tekstu, bez żadnych tagów technicznych)
> - 🔧 **DEV NOTES** — dźwięki, pauzy, przejścia (dla programisty/sound designera, NIE do Gemini)
> - 🎨 **PROMPT GEMINI** — wyłącznie opis wizualny obrazu (NIE zawiera dialogu ani dźwięków)
>
> **Ustawienia Nano Banana Pro dla cutscen:**
>
> | Ustawienie | Wartość |
> |-----------|---------|
> | Model | Nano Banana Pro |
> | Aspect Ratio | **16:9** (szerokie tło cutscenki) |
> | Resolution | **1K** |
> | Image Reference | brak (cutscenki mają własny styl) |
> | Liczba obrazów | generuj **4**, wybierz najlepszy |
> | Output | JPG z białym tłem → WRZUC_SPRITE → kategoria `fx` |
>
> **Gemini prompt style:** pixel art, Enter the Gungeon aesthetic, sausage soldiers, WAR MEAT palette.
>
> ⚠️ **SPÓJNOŚĆ POSTACI (CRITICAL):**
> Każda postać musi wyglądać IDENTYCZNIE we wszystkich cutscenkach.
> **Sposób:** dołącz poprzednią cutscenkę z tą postacią jako image reference i dodaj:
> `"MATCH EXACTLY the character's appearance, eye style, color and proportions from the reference image."`
>
> | Postać | Pierwsze pojawienie | Użyj jako ref dla |
> |--------|--------------------|--------------------|
> | Kiełbasa Śląska | cutscene_0_intro | — |
> | Gen. Frankfurter | cutscene_1_report | cutscene_5, cutscene_6 |
> | Dr. Weisswurst | cutscene_1_report | cutscene_3 |
> | Chorizo-6 | cutscene_2_petroglyphs | cutscene_6 |
> | Bratwurst | cutscene_4_tunnel_map | cutscene_6 |
>
> **Prefix [CUTSCENA] dla wszystkich obrazów cutscen — wklejaj na początku każdego promptu:**
> ```
> Pixel art scene, wide cinematic format (16:9). Style: Enter the Gungeon meets Brotato —
> chibi sausage soldiers, military aesthetic, flat shading, 2px dark navy outline (#1a1a2e),
> max 3 tones per element, NO gradients, NO anti-aliasing. WAR MEAT palette.
> SAUSAGE ANATOMY (CRITICAL): sausage characters have NO separate arms or legs —
> limbs are tiny rounded stubs directly integrated into the sausage body, Brotato-style.
> Body is a single elongated sausage shape. Hands are tiny round nubs. NO human proportions.
> CHARACTER CONSISTENCY (CRITICAL): MATCH EXACTLY the character appearance, eye style,
> color and proportions from the reference image — same eye shape, same casing color,
> same helmet/hat details, same expression style.
> SUBTITLE BAR (CRITICAL): bottom 15% of image must be a solid dark bar (#0d0d1a, 90% opacity)
> — kept completely EMPTY, no characters or objects overlap this area. Game renders subtitles here.
> Background outside scene: FLAT SOLID WHITE #FFFFFF (auto-removed by pipeline).
> ```

---

### CUTSCENA 0: INTRO (przed Falą 1)
> 📁 `cutscene_0_intro.jpg`

📺 **DIALOG** *(wyświetlane graczowi)*
```
PLANETA KIEŁBASIANA. ROK 3042 PO UWĘDZENIU.

Inżynier Kiełbasa Śląska prowadzi rutynowe wiercenia
w sektorze wschodnim Fortecy Bunkierkowej.

KIEŁBASA ŚLĄSKA: "Hm. To nie powinno tu być."

Ziemia drży. Alarm ogólny.

KOMUNIKAT: "UWAGA. NIEZNANE OBIEKTY BIOLOGICZNE
PENETRUJĄ POWIERZCHNIĘ W SEKTORACH 3, 7, 12 I 44."
```

🔧 **DEV NOTES** *(nie wyświetlane graczowi)*
```
- SFX: wiertło + głuchy odgłos pękającego kamienia (po linii 2)
- SFX: syreny alarmowe (po KOMUNIKAT)
- Przejście: fade in z czerni → dialog → fade out
```

🎨 **PROMPT GEMINI:**
```
[CUTSCENA] Left side: underground bunker corridor, sausage engineer
(KIELBASA SLASKA — smoky tan sausage body, orange-striped helmet, goggles, tool belt,
tiny stub limbs) standing next to a massive crack in a stone wall, shocked expression.
Ancient monolith glowing red (#cc0000) visible through doorway behind.
Right side: surface at night, multiple dark cracks opening in the ground,
Carnivore creatures (rounded bulky dark shapes, glowing yellow eyes #ffcc00)
crawling out. Split-panel composition, dark dividing line center.
Dark industrial bunker colors (#1a1a2e walls, #3a3a4a floor). Mood: ominous.
```

---

### CUTSCENA 1: PO FALI 2
> 📁 `cutscene_1_report.jpg`
> 🖼️ **Image ref:** brak (Frankfurter i Weisswurst — pierwsze pojawienie, staną się wzorcem)

📺 **DIALOG** *(wyświetlane graczowi)*
```
RAPORT TERENOWY — GENERAŁ FRANKFURTER

"Pierwsze kontakty z wrogiem potwierdzone.
Istoty wyłaniają się w całej Puszczy Wędzarniczej.
Klasyfikacja: ŁAZIKI i SZTURMAKI.
Zachowanie: agresywne. Cel: nas."

DR. WEISSWURST (przez radio):
"Generale... próbki tkanek wrogów są... stare.
Bardzo stare. Nie chodzi o lata. Chodzi o miliony lat."

GENERAŁ FRANKFURTER:
"Co pan mówi, doktorze?"
```

🔧 **DEV NOTES** *(nie wyświetlane graczowi)*
```
- SFX: radio static przed linią Weisswursta
- Ostatnia linia Frankfurtera + 2s ciszy przed fade out
```

🎨 **PROMPT GEMINI:**
```
[CUTSCENA] Military briefing room. Center: Frankfurter general
(warm orange-pink sausage body, tiny stub limbs, gray combat helmet, serious deadpan expression)
at a holographic table (#4a9eff glow) showing planet map with red breach markers.
Background: various sausage soldiers reacting with alarm. Right wall screen:
Weisswurst medic (cream-white sausage, red cross helmet) holding specimen jar
with dark creature fragment. Tense military atmosphere, dramatic lighting.
```

---

### CUTSCENA 2: PO BOSSIE DŻUNGLA (Boss Fala 5)
> 📁 `cutscene_2_petroglyphs.jpg`
> 🖼️ **Image ref:** brak (Chorizo-6 — pierwsze pojawienie)

📺 **DIALOG** *(wyświetlane graczowi)*
```
Strażnik Puszczy pokonany.

Na jego ciele — symbole wyryte miliony lat temu.
Te same symbole, co na podziemnym monolicie.

CHORIZO-6 (Snajper):
"Generale. Znalazłem coś w dżungli."
"Pod korzeniami starego drzewa."
"Petroglify. Bardzo stare petroglify."

Na ścianie jaskini — wyryty w kamieniu obraz:
wielkie kiełbasy walczą z tymi samymi istotami.
Ale tamte kiełbasy są... OGROMNE.

CHORIZO-6: "...To były dinozaury."
```

🔧 **DEV NOTES** *(nie wyświetlane graczowi)*
```
- SFX: szelest liści + odległe ryki po "Petroglify"
- Muzyka: tajemnicza, powolna (ambient cave)
- Pauza 1.5s przed ostatnią linią Chorizo
```

🎨 **PROMPT GEMINI:**
```
[CUTSCENA] Ancient cave interior, stone walls covered in primitive petroglyphs.
Carvings show: giant sausage dinosaurs (MASSIVE elongated sausage shapes, upright,
5x taller than enemy creatures) battling swarms of dark rounded Carnivore creatures.
Bottom: Chorizo sniper (reddish-brown sausage body, stub limbs, beret, goggles)
shining flashlight (#ffd700 beam) on the wall carvings, looking up in awe.
Earthy cave palette (#3d2a1a stone, #5a4a2a highlights). Ancient mysterious feeling.
```

---

### CUTSCENA 3: PO FALI 8
> 📁 `cutscene_3_ancient_truth.jpg`
> 🖼️ **Image ref:** `cutscene_1_report.jpg` (Weisswurst musi wyglądać identycznie)

📺 **DIALOG** *(wyświetlane graczowi)*
```
DR. WEISSWURST (laboratoryjna transmisja):

"Przebadałem próbki z monolitu.
Pieczęć miała 64.7 miliona lat.

Ktoś — albo coś — CELOWO ją osłabił.
Wiercenia Inżyniera to tylko spust.

W pradawnych zapisach znaleźliśmy nazwę:
WIELKA POŻOGA. Pierwsza wojna.

Kiełbazaury wygrały. Zamknęły Pożeraczy pod ziemią.
Ale Pożeracze... czekały. I uczyły się."

KOMUNIKAT: "NARUSZENIE SEKTORA BUNKIER WSCHODNI.
POZIOM ZAGROŻENIA: KRYTYCZNY."
```

🔧 **DEV NOTES** *(nie wyświetlane graczowi)*
```
- SFX: głuchy grzmot pod stopami (przed KOMUNIKAT)
- Muzyka: narasta napięcie przy "Ale Pożeracze..."
- Efekt: trzęsienie ekranu (shake) przy KOMUNIKAT
```

🎨 **PROMPT GEMINI:**
```
[CUTSCENA] Military research laboratory. Center: Weisswurst medic
(cream-white pale sausage body, stub limbs, red cross helmet, lab goggles)
stands at a research table holding up a glowing specimen jar containing
a dark creature fragment (#cc0000 glow). Behind: large screen showing
ancient timeline — 64.7 million years ago marker highlighted in red.
Wall covered in scientific notes, photos of monolith cracks, diagrams
of underground tunnel networks. Dramatic single overhead light (#ffd700).
Atmosphere: late night, tense discovery, clinical but ominous.
```

---

### CUTSCENA 4: PO BOSSIE PUSTYNIA (Boss Fala 10)
> 📁 `cutscene_4_tunnel_map.jpg`
> 🖼️ **Image ref:** `cutscene_1_report.jpg` (Frankfurter musi wyglądać identycznie)

📺 **DIALOG** *(wyświetlane graczowi)*
```
"Bóg Pustyni" — obalony.

Na jego ciele rytualny wzór: mapa podziemnych tuneli.
Prowadzi do centrum planety. Prowadzi do... CZEGOŚ DUŻEGO.

BRATWURST: "Generale. Czuję wibracje pod stopami.
Niskie. Regularne. Jak... oddech."

GENERAŁ FRANKFURTER: "Ile Pożeraczy wyszło na powierzchnię?"

KOMPUTER TAKTYCZNY: "Szacunkowo: 12% kolonii."

GENERAŁ FRANKFURTER (cicho):
"To znaczy że 88% nadal jest pod ziemią."
```

🔧 **DEV NOTES** *(nie wyświetlane graczowi)*
```
- Pauza 2s po "Szacunkowo: 12% kolonii"
- SFX: cisza, potem niski dudniący pomruk
- Muzyka: staje
```

🎨 **PROMPT GEMINI:**
```
[CUTSCENA] Massive underground cavern. Foreground edge: four tiny sausage soldiers
(stub limbs, various helmets, viewed from behind) look down into the abyss.
Below them: vast darkness filled with thousands of glowing yellow eyes (#ffcc00) —
Carnivore swarm like a living ocean. Deepest center: enormous organic pulsing structure,
faint red glow (#cc0000), like a sleeping heart the size of a building.
Scale: soldiers are tiny ants compared to the cavern. Dread and awe atmosphere.
Dark cave, bioluminescent blue accents on cave walls.
```

---

### CUTSCENA 5: PRZED FINAŁEM (Boss Fala 14)
> 📁 `cutscene_5_final_broadcast.jpg`
> 🖼️ **Image ref:** `cutscene_1_report.jpg` (Frankfurter) + poprzednie cutsceny jako wizualny wzorzec

📺 **DIALOG** *(wyświetlane graczowi)*
```
TRANSMISJA OGÓLNOPLANETARNA — GENERAŁ FRANKFURTER:

"Obywatele Kiełbasiany.

64 miliony lat temu nasze przodkinie —
Kiełbazaury — stoczyły tę samą wojnę. Wygrały.

Zamknęły wroga. Zbudowały Pieczęć.
I liczyły na to, że wystarczy na zawsze.

Nie wystarczyło.

Ale dzisiaj wiemy czego nie wiedziały Kiełbazaury:
nie wystarczy zamknąć. Trzeba skończyć."

Całe siły Kiełbasiany schodzą do podziemi.
Raz ostatni.
```

🔧 **DEV NOTES** *(nie wyświetlane graczowi)*
```
- SFX: marsz wojskowy po "Trzeba skończyć."
- Muzyka: epicka, narasta do finałowego bossfightu
- Przejście bezpośrednio do areny Bunkier
```

🎨 **PROMPT GEMINI:**
```
[CUTSCENA] Military command center, night. Frankfurter general (warm orange-pink sausage
body, stub limbs, gray combat helmet) stands at the center on a raised platform,
speaking into a microphone. Around him: dozens of sausage soldiers of all classes
standing at attention — Frankfurters, Chorizos, Weisswursts, Kielbasa, Parowkas,
Bratwursts. Behind: massive screen showing underground map with ONE blinking red target.
Dramatic spotlight on the general. Atmosphere: solemn, determined, epic.
```

---

### CUTSCENA FINAŁOWA: KRÓLOWA POKONANA
> 📁 `cutscene_6_victory.jpg`
> 🖼️ **Image ref:** `cutscene_1_report.jpg` (Frankfurter, Weisswurst) + `cutscene_2_petroglyphs.jpg` (Chorizo) + `cutscene_4_tunnel_map.jpg` (Bratwurst)

📺 **DIALOG** *(wyświetlane graczowi)*
```
Królowa Pożeraczy — martwa.

Kolonia bez matki dezorientuje się.
Wycofuje. Chowa się.

Po raz pierwszy od miesięcy — cisza.

DR. WEISSWURST: "To koniec?"

GENERAŁ FRANKFURTER:
"Kiełbazaury też myślały, że to koniec."

CHORIZO-6: "Więc co robimy?"

GENERAŁ FRANKFURTER:
"Budujemy lepszą Pieczęć."
"I tym razem — nie zapominamy."
```

🔧 **DEV NOTES** *(nie wyświetlane graczowi)*
```
- Pauza 2s po "Kiełbazaury też myślały..."
- Napis końcowy: "PLANETA KIEŁBASIANA OCALONA. PO RAZ DRUGI."
- Napis mały pod spodem: "— KONIEC — ...na razie."
- Muzyka: spokojna, melancholijna
- Fade to credits
```

🎨 **PROMPT GEMINI:**
```
[CUTSCENA] Planet surface at dawn. Six sausage soldiers stand on a hilltop, viewed
from behind, looking at the sunrise horizon. All sausage bodies with stub limbs:
Frankfurter general (center, gray helmet), Chorizo sniper (left, beret + goggles),
Weisswurst medic (right, red cross helmet), Kielbasa engineer (far left, orange helmet),
Parowka scout (smallest, front center), Bratwurst heavy (far right, visibly WIDEST sausage).
Horizon: sun rising (#ffd700 + #ff9900 sky gradient). Behind them: massive smoking crater.
Distant hills: tiny enemy silhouettes retreating underground. Bittersweet victory mood.
```

🎨 **PROMPT GEMINI:**
```
[CUTSCENA] Planet surface at dawn. Six sausage soldiers stand on a hilltop, viewed
from behind, looking at the sunrise horizon. All sausage bodies with stub limbs:
Frankfurter general (center, gray helmet), Chorizo sniper (left, beret + goggles),
Weisswurst medic (right, red cross helmet), Kielbasa engineer (far left, orange helmet),
Parowka scout (smallest, front center), Bratwurst heavy (far right, visibly WIDEST sausage).
Horizon: sun rising (#ffd700 + #ff9900 sky gradient). Behind them: massive smoking crater.
Distant hills: tiny enemy silhouettes retreating underground. Bittersweet victory mood.
```

---

## 5.1 Status cutscen

| Plik | Trigger | Obraz | Kod |
|------|---------|-------|-----|
| `cutscene_0_intro.jpg` | Start Dżungla | ✅ | ✅ |
| `cutscene_1_report.jpg` | Fala 3 | ✅ | ✅ |
| `cutscene_2_petroglyphs.jpg` | Boss Dżungla | ✅ | ✅ |
| `cutscene_3_ancient_truth.jpg` | Fala 9 | ✅ | ✅ |
| `cutscene_4_tunnel_map.jpg` | Boss Pustynia | ✅ | ✅ |
| `cutscene_5_final_broadcast.jpg` | Ostatnia fala Bunkier | ✅ | ✅ |
| `cutscene_6_victory.jpg` | Boss Bunkier | ✅ | ✅ |

---

## 6. Dialogi Między Falami (krótkie)

> Losowe teksty wyświetlane między falami — budują nastrój bez przerywania gry.

### Seria: Odkrycia historyczne
```
CHORIZO-6: "W ruinach znalazłem kość."
CHORIZO-6: "Mierzy 3 metry. To była kiełbasa."
GENERAŁ FRANKFURTER: "Byliśmy wielcy."
```

```
DR. WEISSWURST: "Wiecie że Kiełbazaury nie miały broni?"
DR. WEISSWURST: "Walczyły zębami i pazurami."
BRATWURST: "Respekt."
```

```
KOMPUTER: "ANALIZA DNA: wrogowie zawierają fragmenty DNA Kiełbazaurów."
KOMPUTER: "Pożeracze... jadły Kiełbazaury."
DR. WEISSWURST: "To wyjaśnia nazwę."
```

### Seria: Humor absurdalny
```
KIEŁBASA ŚLĄSKA: "Przepraszam za to wiercenie."
KIEŁBASA ŚLĄSKA: "Myślałem że to zwykła skała."
GENERAŁ FRANKFURTER: "Następnym razem najpierw zapytaj."
```

```
ŁAZIK (przez tłumacz): "MY GŁODNE."
GENERAŁ FRANKFURTER: "My też."
```

```
BRATWURST: "Pytanie — jeśli oni jedzą mięso..."
BRATWURST: "...a my jesteśmy mięsem..."
CHORIZO-6: "Nie kończ tego zdania."
```

### Seria: Napięcie taktyczne
```
KOMPUTER: "CZAS DO KOLEJNEJ FALI: 30 SEKUND."
PARÓWKA (Scout): "To za mało. Za mało. Za mało."
GENERAŁ FRANKFURTER: "Trzymać pozycję."
```

```
DR. WEISSWURST: "Liczyłem wrogów."
DR. WEISSWURST: "Przestałem liczyć przy 10 000."
BRATWURST: "Dobrze że przestałeś."
```

---

## 7. Charakterystyki Postaci

| Postać | Kiełbasa | Osobowość | Catchphrase |
|--------|---------|-----------|-------------|
| **Gen. Frankfurter** | Frankfurter | Spokojny, zdecydowany, nosi ciężar dowodzenia | *"Trzymać pozycję."* |
| **Dr. Weißwurst** | Weißwurst | Naukowy entuzjazm nawet w apokalipsie | *"Fascynujące. I przerażające."* |
| **Chorizo-6** | Chorizo | Cyniczny zwiadowca, widział za dużo | *"Miałem złe przeczucie."* |
| **Inż. Kiełbasa Śląska** | Kiełbasa Śląska | Praktyczny, winny, naprawia błędy | *"Naprawię to."* |
| **Parówka** | Parówka | Młoda, szybka, rozmawia za dużo ze strachu | *"Idę idę idę idę—"* |
| **Bratwurst** | Bratwurst | Weteran milczek, zna cenę wojny | *"..."* |

---

## 8. Implementacja w Grze

### Istniejące systemy
- `src/ui/dialog_box.tscn` + `dialog_box.gd` — cutscenki tekstowe
- `src/autoloads/event_bus.gd` — sygnały `upgrade_panel_completed`, `shop_closed` jako miejsca na cutscenki
- `src/data/narrative_data.gd` — (jeśli istnieje) dane narracyjne

### Kiedy pokazywać cutscenki
| Moment | Cutscena |
|--------|----------|
| Start gry | Cutscena 0: INTRO |
| Po fali 2 | Cutscena 1: Raport |
| Po Boss Dżungla | Cutscena 2: Petroglify |
| Po fali 8 | Cutscena 3: Wielka Pożoga |
| Po Boss Pustynia | Cutscena 4: Mapa tuneli |
| Przed Boss Bunkier | Cutscena 5: Transmisja |
| Po Boss Bunkier | Cutscena Finałowa |
| Losowo między falami | Dialogi z sekcji 6 |

### Format pliku cutsceny (GDScript)
```gdscript
# W narrative_data.gd lub osobnym zasobie
const CUTSCENE_AFTER_WAVE: Dictionary = {
    2:  "cutscene_report",
    8:  "cutscene_ancient_truth",
}
const CUTSCENE_AFTER_BOSS: Dictionary = {
    "jungle": "cutscene_petroglyphs",
    "desert": "cutscene_tunnel_map",
    "bunker": "cutscene_finale",
}
```
