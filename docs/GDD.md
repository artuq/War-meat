# 📋 WAR MEAT — Game Design Document (GDD)

> Wersja: 0.1 (Draft)

---

## 1. Przegląd

| Pole | Wartość |
|------|---------|
| **Tytuł** | WAR MEAT |
| **Gatunek** | Roguelite arena-survivor / Auto-battler (inspiracja: Brotato, Vampire Survivors) |
| **Platforma** | Mobile (Android) — landscape 640×360 |
| **Widok** | Top-down 2D |
| **Styl graficzny** | High-res Pixel Art (à la Enter the Gungeon / Dead Cells) — sprite source 128 px, render w grze ~25 px, Linear texture filter |
| **Tryb gry** | Singleplayer |
| **Sterowanie** | Wirtualny joystick (mobile) / Klik-to-move (PC) |

---

## 2. Mechaniki gry

### 2.1 Oddział gracza

Gracz kontroluje oddział składający się z **1–4 żołnierzy**. Żołnierze poruszają się w formacji i automatycznie strzelają do najbliższych wrogów (auto-battler). Gracz decyduje o kierunku ruchu i pozycjonowaniu oddziału.

#### Formacje
- **Linia** — żołnierze ustawieni obok siebie (szeroki ostrzał)
- **Kolumna** — żołnierze ustawieni jeden za drugim (wąskie przejścia)
- **Diament** — formacja obronna z medykiem w środku

### 2.2 Klasy żołnierzy

| Klasa | Rola | Broń domyślna | Specjalna zdolność |
|-------|------|----------------|-------------------|
| **Szturmowiec** | DPS z bliska | Karabin szturmowy | Granat odłamkowy |
| **Snajper** | DPS z dystansu | Karabin snajperski | Strzał krytyczny (gwarantowany) |
| **Medyk** | Wsparcie / leczenie | Pistolet | Leczenie oddziału |
| **Inżynier** | Wsparcie / wieżyczki | Strzelba | Postawienie wieżyczki |
| **Zwiadowca** | Szybkość / rekonesans | SMG | Zwiększona szybkość oddziału |
| **Ciężki** | Tank / absorpcja obrażeń | Karabin maszynowy | Tarcza oddziału |

### 2.3 System atrybutów

Każdy żołnierz posiada następujące atrybuty:

| Atrybut | Opis |
|---------|------|
| **HP** | Punkty życia |
| **Atak** | Bazowe obrażenia |
| **Szybkość ataku** | Tempo strzelania |
| **Szybkość ruchu** | Prędkość poruszania się |
| **Zasięg** | Dystans wykrywania i atakowania wrogów |
| **Pancerz** | Redukcja obrażeń otrzymywanych |
| **Szczęście** | Wpływa na: szansę na krytyk, jakość lootu, rzadkie eventy |

#### Statystyka „Szczęścia"

Szczęście to unikalna statystyka wpływająca na wiele aspektów gry:
- **Krytyczne trafienia** — wyższe szczęście = wyższa szansa na crit
- **Jakość lootu** — wyższe szczęście = częstsze rzadkie przedmioty
- **Rzadkie eventy** — szansa na specjalne wydarzenia (np. ukryty sklep, bonus)
- **Uniki** — minimalna szansa na unik ataku wroga

### 2.4 System broni

Bronie różnią się następującymi parametrami:

| Parametr | Opis |
|----------|------|
| **Obrażenia** | Bazowe obrażenia na trafienie |
| **Szybkość ognia** | Strzały na sekundę |
| **Zasięg** | Maksymalny dystans strzału |
| **Rozrzut** | Dokładność (mniejszy = lepszy) |
| **Magazynek** | Ilość strzałów przed przeładowaniem |
| **Czas przeładowania** | Czas przeładowania w sekundach |

#### Rzadkość broni
- ⬜ **Pospolita** — bazowe statystyki
- 🟩 **Niepospolita** — +20% statystyk
- 🟦 **Rzadka** — +40% statystyk, 1 bonus
- 🟪 **Epicka** — +60% statystyk, 2 bonusy
- 🟧 **Legendarna** — +100% statystyk, 3 bonusy, unikalna zdolność

---

## 3. Struktura rozgrywki

### 3.1 Pętla jednej misji

```
Start misji
  │
  ├─▶ Fala 1 — walka z wrogami
  │     └─▶ Zbieranie lootu
  │           └─▶ Sklep (kupno / sprzedaż / ulepszenia)
  │
  ├─▶ Fala 2 — trudniejsi wrogowie
  │     └─▶ Zbieranie lootu
  │           └─▶ Sklep
  │
  ├─▶ ... (kolejne fale, rosnąca trudność)
  │
  └─▶ Fala końcowa / Boss
        └─▶ Nagrody za misję
              └─▶ Powrót do bazy
```

### 3.2 Areny tematyczne

Rozgrywka opiera się wyłącznie na zamkniętych arenach — brak misji liniowych (A→B).
Każda arena ma unikalny temat wizualny, pulę wrogów i modyfikatory środowiskowe.

| Arena | Trudność | Modyfikatory | Boss |
|-------|----------|-------------|------|
| **Dżungla** | ⭐ Łatwa | +20% spawn rate, dominacja Rusherów, gęste debris | Szybki boss z dash + summon |
| **Pustynia** | ⭐⭐ Średnia | Wrogowie +15% range, piasek -10% speed, otwarta przestrzeń | Snajperski boss + faza ukrycia |
| **Bunkier** | ⭐⭐⭐ Trudna | Wybuchające beczki, ciasne korytarze, więcej ciężkich wrogów | Tank boss z tarczą + berserk |

Każda arena: 5 fal + boss na fali 5. Progresja liniowa — odblokuj kolejną po ukończeniu.

### 3.3 Meta-progresja (między misjami)

```
Hub Screen (uproszczony)
  ├── Wybór areny — odblokowane areny z podglądem trudności
  ├── Ekwipunek — siatka 4 broni + 8 pasywek z synergiami
  └── Ulepszenia — permanentne bonusy za surowce (+HP, +DMG, nowe klasy)
```

---

## 4. Wrogowie

### 4.1 Typy wrogów

| Typ | Zachowanie | Trudność |
|-----|-----------|----------|
| **Piechota** | Idzie w stronę gracza, strzela z bliska | ⭐ |
| **Biegacz** | Szybki, atakuje wręcz | ⭐ |
| **Strzelec** | Stoi w miejscu, strzela z dystansu | ⭐⭐ |
| **Ciężki** | Wolny, dużo HP, duże obrażenia | ⭐⭐ |
| **Snajper** | Daleki zasięg, wysoki atak, niskie HP | ⭐⭐⭐ |
| **Granatnik** | Rzuca granaty w obszar (AoE) | ⭐⭐⭐ |
| **Pojazd lekki** | Szybki, średnie HP, jezdny | ⭐⭐⭐⭐ |
| **Pojazd ciężki** | Bardzo wolny, ogromne HP | ⭐⭐⭐⭐⭐ |

### 4.2 Bossowie

Bossowie pojawiają się na końcu kluczowych misji. Każdy boss ma:
- Unikalny wzorzec ataku
- Kilka faz walki
- Gwarantowany drop legendarnego przedmiotu

---

## 5. Ekonomia

### 5.1 Waluty

| Waluta | Źródło | Użycie |
|--------|--------|--------|
| **Złoto** | Drop z wrogów (w misji) | Zakupy w sklepie między falami |
| **Surowce** | Nagrody za misje | Ulepszenia w bazie, rekrutacja, badania |

### 5.2 Sklep między falami

Sklep jest dostępny między falami w trakcie misji. Oferuje:
- Bronie (max 4 sloty — wymiana po zapełnieniu)
- Pasywne przedmioty (max 8 slotów — synergie za 3+ tego samego typu)
- Apteczki (leczenie oddziału)
- Tymczasowe ulepszenia statystyk (na czas misji)

### 5.3 System ekwipunku (sloty)

```
┌─────────────────────────────────────┐
│          ⚔️ EKWIPUNEK              │
│                                     │
│  BRONIE (4 sloty):                  │
│  [Karabin] [Strzelba] [  ] [  ]    │
│                                     │
│  PASYWKI (8 slotów):                │
│  [Luck+] [SPD+] [Armor] [  ]       │
│  [  ]    [  ]   [  ]    [  ]       │
│                                     │
│  SYNERGIE: 🔵 Prędkość ×2          │
└─────────────────────────────────────┘
```

---

## 6. Interfejs użytkownika

### 6.1 HUD w trakcie walki

```
┌──────────────────────────────────────────┐
│ [HP Bar 1] [HP Bar 2] [HP Bar 3] [HP 4] │  ← HP żołnierzy
│                                          │
│                                          │
│              POLE WALKI                  │
│                                          │
│                                          │
│ Fala: 3/10        $: 1250    ⭐: 12     │  ← Informacje
└──────────────────────────────────────────┘
```

### 6.2 Ekran sklepu

```
┌──────────────────────────────────────────┐
│           🏪 SKLEP — Fala 3              │
│                                          │
│  [Karabin M4]     $500   [KUP]          │
│  [Strzelba]       $350   [KUP]          │
│  [Apteczka]       $200   [KUP]          │
│  [Granat]         $150   [KUP]          │
│                                          │
│  Złoto: $1250          [DALEJ ▶]        │
└──────────────────────────────────────────┘
```

---

## 7. Referencje wizualne

| Gra | Co bierzemy |
|-----|-------------|
| **Brotato** | Core loop arena-survivor, auto-strzelanie, sklep między falami, siatka ekwipunku, juicy SFX |
| **Vampire Survivors** | Czasowe przetrwanie fal, rosnąca potęga, setki wrogów na ekranie |
| **Cannon Fodder** | Dowodzenie oddziałem, klimat wojskowy, pixel art, krótkie krzyki śmierci |
| **Battlefield** | System klas, różnorodność broni, klimat wojskowy |

---

## 8. Audio

> Szczegółowy plan: [AUDIO_PLAN.md](AUDIO_PLAN.md)

### 8.1 Filozofia audio

Brotato-style juiciness + Cannon Fodder militarny klimat. Każda akcja gracza musi mieć natychmiastowy, satysfakcjonujący dźwiękowy feedback. Generacja w SUNO AI, obróbka w Audacity/ffmpeg, pitch-randomization w Godocie.

### 8.2 Kluczowe systemy

| System | Opis |
|--------|------|
| **Pitch Randomization** | Każdy strzał/trafienie z ±10% pitch shift + losowy wariant (1 z 3). Zapobiega monotonii |
| **Voice Limiting** | Max 4 strzały + 8 trafień jednocześnie. Priorytetyzacja (UI > Voice > Weapon > Impact) |
| **Dynamic Music** | 2 warstwy per arena (base + intense). Crossfade na bazie intensity (wrogowie × fala × boss) |
| **Low HP Effect** | Poniżej 20% HP: low-pass filter, heartbeat loop, music duck -6dB |
| **Haptic Feedback** | Wibracje Android powiązane z eksplozjami, bossami, level upem |
| **Loot Pitch Ramp** | Kolejne monety zbierane pod rząd mają rosnący pitch (+0.05 do max 1.5×) |

### 8.3 Podsumowanie assetów audio

| Kategoria | Ilość | Priorytet |
|-----------|-------|-----------|
| SFX Walki | ~45 | P0 |
| SFX UI/Feedback | ~20 | P1 |
| Muzyka | ~12 tracków | P2 |
| SFX Polish | ~8 | P3 |
| **RAZEM** | **~85** | |

---

## 9. Zakres MVP (Minimalny Grywalny Produkt)

Aby zweryfikować koncept gry, MVP powinien zawierać:

1. ✅ Jedną grywalnę arenę
2. ✅ 1 postać sterowaną przez gracza (Szturmowiec)
3. ✅ System „tap-to-move"
4. ✅ Auto-strzelanie w najbliższego wroga
5. ✅ 2–3 typy wrogów
6. ✅ System fal (5 fal)
7. ✅ Drop lootu (złoto)
8. ✅ Prosty sklep między falami (1–2 przedmioty)
9. ✅ Ekran wygranej / przegranej
