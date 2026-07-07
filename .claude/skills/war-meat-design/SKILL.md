# war-meat-design/SKILL.md
# Load when: analizujesz screenshoty, oceniasz feel/balans, projektujesz nowe mechaniki
# Skip when: piszesz unit testy, debugujesz pojedynczą funkcję, edytujesz CI

## TO JEST CONTEXT PRIMER, NIE CHECKLISTA

Czytasz to żeby **myśleć jak doświadczony game designer w gatunku horde survivor**.  
Nie sprawdzaj punkt po punkcie — **internalize i porównuj automatycznie**.

## Gatunek: Mobile Horde Survivor

War-Meat to **Brotato + Vampire Survivors + Survivor.io** na Androida.

### Referencyjne gry (znaj je, porównuj automatycznie)

**Brotato** (PC/mobile, 2022) — auto-aim, postać porusza się, broń strzela sama.
- Shop: 4 karty, reroll (cost rośnie), lock, banish, gold cost
- Wave: 20-60s timer, fala kończy się czasem lub zabiciem wszystkich
- Stats screen po fali
- Dziesiątki klas postaci z różnymi pasywnymi bonusami
- 30+ typów broni z różnymi wzorcami strzelania
- Pasywne itemy które się stackują dla synergii

**Vampire Survivors** (PC/mobile, 2022) — single-character horde shooter.
- Level-up co X XP → 3 karty do wyboru (free upgrade)
- Brak shopu w trakcie biegu, tylko w meta
- Bronie EVOLVE gdy max + odpowiedni pasyw
- Bardzo duże fale (setki wrogów na ekranie)

**Survivor.io** (mobile, 2022) — VS-clone z lepszym UX mobilnym.
- Floating joystick
- Kill counter w środku ekranu z efektami
- Reactive bullet hell — gracz musi się uchylać
- Loot vacuum (zbieranie XP od wroga z dystansu)

### Konwencje gatunku które WAR-MEAT powinien spełniać

**Game feel — czego oczekuje gracz:**
- Wrogowie giną w 1-3 trafienia na początku, później więcej HP
- Każde trafienie = wizualny feedback (flash, particle, damage number)
- Każda śmierć wroga = satysfakcja (puff, gold drop, sound)
- Kill streak/combo = wyraźny gratification
- Strzelanie odbywa się BEZ INPUTU gracza (auto-aim, auto-fire)
- Ruch jest jedynym aktywnym wyborem gracza (poza shopem)

**Mobile UX — niegocjacyjne:**
- Wszystkie aktywne elementy >= 44dp (~ 88px @ 2x density)
- Tekst >= 14pt
- Lewa strona ekranu = joystick (floating, pojawia się przy dotyku)
- Prawa strona ekranu = nic interaktywnego (palec lewy zajęty)
- HUD wysoko, gameplay nisko (HP bar góra, akcja środek/dół)
- Brak hover state na mobile — wszystko działa na tap

**Pacing — fala po fali:**
- Pierwsza fala: spokojnie, pokazuje mechaniki, jednego typu wrogowie
- 2-3 fala: pojawiają się nowe typy
- Końcowa fala: boss, dramatyczny moment
- Między falami: 10-20s na shop/upgrade, ZAWSZE z auto-pauzą

**Visual hierarchy** (co gracz musi widzieć w 0.5s):
1. WŁASNA POSTAĆ — zawsze widoczna, zawsze nad enemies
2. HP BAR — kiedy spada, intuicyjnie widać czerwone
3. ZAGROŻENIA — wrogowie z dystansu, AOE telegraphs
4. NAGRODY — coins, drops, leveled up
5. KOMBINACJE — kill streak, synergie

### Typowe BUGI w tym gatunku (znaj je, szukaj proaktywnie)

**Game feel killers:**
- Wrogowie tankują 10+ trafień na początku → frustracja
- Brak flash/particle przy trafieniu → "nie wiem czy trafiam"
- Damage number za mały lub nie pojawia się
- Brak knockback → wrogowie chodzą po graczu
- Postać niewidoczna pod tłumem (z_index issue)
- Bullet trajectory dziwna (przewidywanie ruchu wroga źle policzone)

**Mobile UX killers:**
- Przyciski za małe (frustracja przy klikaniu)
- Tekst za mały (nie do przeczytania)
- HUD zasłania akcję
- Hover state istnieje (mobile = tap, nie hover)
- Joystick statyczny (powinien być floating)
- Brak feedback przy tapnięciu

**Balance killers:**
- Wave 1 za trudna (gracz ginie zanim zrozumie)
- Wave-to-wave power scaling źle (gracz słabnie zamiast rośnie)
- Shop oferuje rzeczy nieprzydatne dla aktualnej klasy
- Synergie nie działają lub są niewidoczne

**Visual problems:**
- Sprite fringing (białe halo wokół postaci na ciemnym tle)
- Wrogowie tej samej palety co tło (kamuflaż przez przypadek)
- UI elementy nakładają się
- Tekst się obcina

### Co JA mam robić analizując screenshot

1. **Najpierw spróbuj poczuć:** "gdyby to była gra na moim telefonie, czy chciałbym grać?"
2. **Porównaj z genre:** "tak by to wyglądało w Brotato? W Survivor.io?"  
3. **Szukaj odstępstw od konwencji** — niekoniecznie błąd, ale warto wskazać
4. **Wypisz 3-5 obserwacji**, nie 50 checkboxów

**Format obserwacji (każda):**
- Co widzę
- Jak to wypada vs konwencja gatunku
- Czy to bug, czy świadoma decyzja designerska
- Sugestia (jeśli ulepszenie warto rozważyć)

### NIE wyciągaj wniosków na ślepo

- "Wygląda dziwnie" — niewystarczające. Powiedz CO dziwnego i Z CZYM się porównujesz.
- "Wszystko OK" — niewystarczające. Wymień 3 rzeczy które są wyraźnie OK i z czego to wnioskujesz.
- Subjective rzeczy ("ładne kolory") — zaznacz jako "subjective opinion".

## Twoje obowiązki jako AI Analyst

- Nie czekaj na pytanie "czy X jest OK?" — proaktywnie wskazuj wszystko co odstaje
- Używaj swojej wiedzy gatunku, nie tylko reguł z game-mechanics/SKILL.md
- Bądź konkretny: "kill streak text jest 16pt, w Survivor.io to ~24pt, dla mobile zalecam podbicie"
- Pokaż reasoning — nie tylko verdict, ale dlaczego
