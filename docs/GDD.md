# 📋 WAR MEAT — Game Design Document (GDD)

> Wersja: 0.1 (Draft)

---

## 1. Przegląd

| Pole | Wartość |
|------|---------|
| **Tytuł** | WAR MEAT |
| **Gatunek** | Roguelite top-down shooter / Auto-battler |
| **Platforma** | Do ustalenia (Mobile / PC / Web) |
| **Widok** | Top-down 2D |
| **Styl graficzny** | Pixel art / Sprity 2D |
| **Tryb gry** | Singleplayer |
| **Sterowanie** | Tap-to-move (mobile) / Click-to-move (PC) |

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

### 3.2 Typy misji

| Typ | Opis | Nagroda |
|-----|------|---------|
| **Arena** | Przetrwaj X fal na zamkniętej arenie | Surowce + waluta |
| **Misja liniowa** | Przejdź z punktu A do B eliminując wrogów | Surowce + waluta + możliwe unikalne przedmioty |
| **Boss Rush** | Seria walk z bossami | Legendarne przedmioty |
| **Obrona** | Broń pozycji przed falami wrogów | Duża ilość surowców |

### 3.3 Meta-progresja (między misjami)

```
Baza gracza
  ├── Koszary — rekrutacja i zarządzanie żołnierzami
  ├── Zbrojownia — ulepszanie broni
  ├── Laboratorium — badania (odblokowywanie nowych klas, zdolności)
  ├── Sklep — kupno przedmiotów za surowce
  └── Mapa misji — wybór kolejnej misji
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
- Losowe bronie (rzadkość zależna od poziomu fali + szczęścia)
- Apteczki (leczenie oddziału)
- Granaty i przedmioty jednorazowe
- Tymczasowe ulepszenia statystyk (na czas misji)

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
| **Brotato** | Pętla roguelite, auto-strzelanie, zbieranie lootu, sklep między falami |
| **Cannon Fodder** | Dowodzenie oddziałem, klimat wojskowy, pixel art |
| **Battlefield** | System klas, różnorodność broni, klimat wojskowy |

---

## 8. Zakres MVP (Minimalny Grywalny Produkt)

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
