# 🗺️ WAR MEAT — Roadmapa Projektu

> Poniżej znajduje się plan rozwoju gry podzielony na fazy.
> Szczegółowe zadania są śledzone jako [GitHub Issues](../../issues).
> Aby wygenerować issues z tego planu, uruchom workflow **Create Issues from Roadmap** w zakładce Actions.

---

## Faza 0 — Fundament projektu

> Cel: Przygotowanie środowiska, dokumentacji i podstawowej struktury projektu.

👉 [Zadania Fazy 0](../../issues?q=is%3Aissue+label%3Aphase-0)

- **Wybór silnika gry** — Porównanie i decyzja (np. Godot, Unity 2D, Phaser, Love2D)
- **Konfiguracja repozytorium** — Struktura katalogów, `.gitignore`, CI/CD
- **Utworzenie Game Design Document (GDD)** — Szczegółowy dokument opisujący mechaniki
- **Określenie docelowej platformy** — Mobile / PC / Web
- **Wybór stylu graficznego** — Pixel art, rozdzielczość, paleta kolorów

---

## Faza 1 — Prototyp (MVP)

> Cel: Grywalny prototyp z jedną postacią, jedną mapą i podstawową mechaniką walki.

👉 [Zadania Fazy 1](../../issues?q=is%3Aissue+label%3Aphase-1)

### 1.1 Ruch i sterowanie
- **System ruchu postaci** — Implementacja „tap-to-move" / kliknięcie na mapę
- **Kamera** — Śledzenie oddziału gracza z widokiem z góry
- **Kolizje** — Podstawowy system kolizji ze środowiskiem

### 1.2 Walka
- **System strzelania** — Automatyczne strzelanie w kierunku najbliższego wroga (auto-battler)
- **Typy broni (podstawowe)** — Karabin, strzelba, pistolet
- **System obrażeń** — HP, zadawanie obrażeń, śmierć postaci
- **Wrogowie (podstawowi)** — 2–3 typy wrogów z prostym AI (dążenie do gracza)

### 1.3 Mapa i fale
- **Generowanie areny** — Prosta zamknięta arena do testów
- **System fal** — Spawnowanie wrogów w falach o rosnącej trudności
- **Warunek zwycięstwa/przegranej** — Przetrwanie X fal lub śmierć oddziału

---

## Faza 2 — Systemy bazowe

> Cel: Dodanie kluczowych systemów: loot, sklep, klasy żołnierzy.

👉 [Zadania Fazy 2](../../issues?q=is%3Aissue+label%3Aphase-2)

### 2.1 System lootu
- **Drop z wrogów** — Wrogowie upuszczają walutę i surowce po śmierci
- **Zbieranie przedmiotów** — Automatyczne lub manualne zbieranie lootu
- **Inwentarz** — Prosty system przechowywania zebranych przedmiotów

### 2.2 Sklep między falami
- **Interfejs sklepu** — UI sklepu dostępnego między falami
- **Asortyment** — Bronie, ulepszenia, apteczki
- **Ekonomia** — Balansowanie cen i wartości dropów

### 2.3 Klasy żołnierzy
- **System klas** — Definicja klas (np. Szturmowiec, Snajper, Medyk, Inżynier)
- **Atrybuty klas** — Unikalne statystyki i umiejętności dla każdej klasy
- **Rekrutacja** — Mechanika dodawania nowych żołnierzy do oddziału (max 3–4)

### 2.4 System atrybutów
- **Statystyki postaci** — HP, atak, szybkość, zasięg, pancerz
- **Statystyka „szczęścia"** — Wpływ na krytyczne trafienia, jakość lootu, rzadkie eventy
- **Poziomowanie** — System zdobywania doświadczenia i podnoszenia statystyk

---

## Faza 3 — Misje i progresja

> Cel: Rozbudowa rozgrywki o strukturę misji i meta-progresję.

👉 [Zadania Fazy 3](../../issues?q=is%3Aissue+label%3Aphase-3)

### 3.1 System misji
- **Mapa misji** — Ekran wyboru misji z różnymi lokacjami
- **Misje liniowe (A→B)** — Przechodzenie przez mapę z walką po drodze
- **Misje arenowe** — Przetrwanie fal na zamkniętej arenie
- **System trudności** — Skalowanie wrogów zależnie od poziomu gracza

### 3.2 Meta-progresja
- **Baza gracza** — Ekran główny z dostępem do ulepszeń i rekrutacji
- **Ulepszenia stałe** — Permanentne bonusy między misjami (za surowce)
- **Odblokowywanie klas** — Nowe klasy żołnierzy za osiągnięcia lub surowce
- **Drzewko ulepszeń** — Ścieżki rozwoju dla każdej klasy

### 3.3 Różnorodność wrogów
- **Typy wrogów** — Piechota, ciężka piechota, snajperzy, pojazdy
- **Boss fights** — Unikalni bossowie na końcu kluczowych misji
- **AI wrogów** — Różne wzorce zachowań (flankowanie, szarża, obrona)

---

## Faza 4 — Polish i balans

> Cel: Dopracowanie gry, balans, dźwięk, efekty wizualne.

👉 [Zadania Fazy 4](../../issues?q=is%3Aissue+label%3Aphase-4)

### 4.1 Grafika i animacje
- **Sprite'y postaci** — Finalne sprity żołnierzy i klas
- **Sprite'y wrogów** — Finalne sprity wszystkich typów wrogów
- **Efekty wizualne** — Wybuchy, muzzle flash, ślady pocisków
- **Tilemapy** — Finalne zestawy kafelków dla różnych lokacji

### 4.2 Dźwięk
- **Efekty dźwiękowe** — Strzały, eksplozje, zbieranie lootu
- **Muzyka** — Ścieżka dźwiękowa do walki i menu
- **Dźwięki UI** — Kliknięcia, zakup w sklepie, level-up

### 4.3 Balans
- **Balans broni** — Wyrównanie DPS i użyteczności broni
- **Balans klas** — Każda klasa powinna być użyteczna
- **Balans ekonomii** — Tempo zdobywania zasobów vs. ceny w sklepie
- **Krzywa trudności** — Progresywny wzrost wyzwania

### 4.4 UI/UX
- **HUD w grze** — HP, amunicja, minimap, info o fali
- **Menu główne** — Start, ustawienia, wyjście
- **Ekran wyników** — Podsumowanie misji (zabici, loot, czas)
- **Tutorial** — Wprowadzenie do mechanik dla nowych graczy

---

## Faza 5 — Testowanie i wydanie

> Cel: Stabilizacja, testy, przygotowanie do wydania.

👉 [Zadania Fazy 5](../../issues?q=is%3Aissue+label%3Aphase-5)

- **Testy wewnętrzne (QA)** — Przejście całej gry, szukanie bugów
- **Testy wydajności** — Optymalizacja na docelowych platformach
- **Beta-testy** — Udostępnienie wybranym graczom i zbieranie opinii
- **Naprawa bugów** — Iteracja na podstawie feedbacku
- **Przygotowanie materiałów marketingowych** — Screenshoty, trailer, opis
- **Wydanie v1.0** — Publikacja na docelowej platformie
