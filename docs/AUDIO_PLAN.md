# WAR MEAT — Audio Plan

## Narzędzia

| Typ | Narzędzie | Uwagi |
|-----|-----------|-------|
| **SFX + Muzyka** | **ElevenLabs** (elevenlabs.io/sound-effects) | Wszystkie dźwięki i muzyka |
| Format | `.mp3` / `.wav` | Godot obsługuje oba |

> **ElevenLabs workflow (SFX i muzyka):**
> 1. Wklej prompt (opisuje brzmienie)
> 2. **Duration** — ustaw w suwaku (sekundy)
> 3. **Loop / One Shot** — wybierz w UI
> 4. Generuj kilka wariantów, wybierz najlepszy → pobierz
>
> ⚠️ Nie wpisuj długości ani "loop/one-shot" w tekście promptu — to kontrolki w UI ElevenLabs.

---

## 1. SFX — Cutsceny

> Folder: `assets/audio/sfx/cutscene/`

| Plik | ✅ | Type | Duration | Prompt ElevenLabs |
|------|----|------|----------|-------------------|
| `cutscene_alarm.wav` | ⬜ | One Shot | 2s | `industrial facility alarm klaxon, urgent blaring siren burst, metallic resonance, danger warning` |
| `cutscene_drill.wav` | ⬜ | One Shot | 2s | `heavy drill grinding into concrete and stone, mechanical vibration, industrial impact texture, harsh and abrasive` |
| `cutscene_rumble.wav` | ⬜ | One Shot | 3s | `deep underground earth tremor, low frequency bass rumble, ground shaking, ominous subsonic vibration with debris settling` |
| `cutscene_radio_static.wav` | ⬜ | One Shot | 0.5s | `military radio crackle burst, short static noise hit, electronic interference, sharp and instant` |
| `cutscene_leaves.wav` | ⬜ | Loop | 8s | `jungle environment ambience, leaves rustling in wind, distant animal growl echo, cave drips, dark forest atmosphere` |
| `cutscene_heartbeat.wav` | ⬜ | Loop | 4s | `slow ominous heartbeat pulse, deep bass thump, dark organic rhythm, tension building drone underneath, cave atmosphere` |
| `cutscene_march_drums.wav` | ⬜ | One Shot | 3s | `military snare drum cadence, crisp drumstick impacts, march rhythm accelerating to full pace, heroic texture` |

---

## 2. SFX — Broń

> Folder: `assets/audio/sfx/weapons/`
> Mamy już: `rifle_01/02/03.wav`

| Plik | ✅ | Type | Duration | Prompt ElevenLabs |
|------|----|------|----------|-------------------|
| `shotgun_01.wav` | ⬜ | One Shot | 1s | `pump action shotgun blast, wide spread boom, heavy low-end impact, outdoor environment` |
| `shotgun_02.wav` | ⬜ | One Shot | 1s | `shotgun discharge, indoor concrete echo, deep chest-hitting boom, debris rattle tail` |
| `pistol_01.wav` | ⬜ | One Shot | 0.5s | `compact pistol gunshot, sharp high crack, fast attack fast decay, clean single fire, minimal echo` |
| `pistol_02.wav` | ⬜ | One Shot | 0.5s | `small caliber handgun pop, quick dry crack, immediate, no reverb tail` |
| `smg_01.wav` | ⬜ | One Shot | 0.5s | `submachine gun short burst, 3 rapid mechanical shots, fast cycling metal clatter, tight and aggressive` |
| `smg_02.wav` | ⬜ | One Shot | 0.5s | `automatic SMG fire burst, rapid mechanical rattle, 4 shots, high tempo, metallic texture` |
| `sniper_01.wav` | ⬜ | One Shot | 2s | `high caliber sniper rifle shot, massive sharp crack, supersonic snap, long reverb tail, distant echo` |
| `melee_01.wav` | ⬜ | One Shot | 0.3s | `combat knife slash whoosh, sharp air displacement, fast movement impact, blade texture` |
| `melee_02.wav` | ⬜ | One Shot | 0.3s | `knife blade impact hit, hard thud with sharp edge texture, brutal close contact` |
| `grenade_01.wav` | ⬜ | One Shot | 2s | `grenade explosion, large concussive blast, debris and shrapnel rattle, dust and smoke tail` |
| `grenade_02.wav` | ⬜ | One Shot | 2s | `explosive impact detonation, heavy bass boom, close range pressure wave, ringing tail` |

---

## 3. SFX — UI

> Folder: `assets/audio/sfx/ui/`

| Plik | ✅ | Type | Duration | Prompt ElevenLabs |
|------|----|------|----------|-------------------|
| `shop_buy.wav` | ⬜ | One Shot | 0.5s | `retro 8-bit coin collect chime, satisfying bright ding, positive transaction confirmation, game UI sound` |
| `shop_reroll.wav` | ⬜ | One Shot | 0.5s | `playing cards shuffle and flip, quick paper whoosh, mechanical deal texture, crisp and fast` |
| `level_up.wav` | ⬜ | One Shot | 1s | `ascending chime sequence, bright triumphant tones rising, game level up jingle, positive energy` |
| `upgrade_pick.wav` | ⬜ | One Shot | 0.5s | `power up collect shimmer, magical sparkle burst, bright positive confirmation, game pickup texture` |
| `wave_start.wav` | ⬜ | One Shot | 1s | `military brass horn blast, sharp battle signal stab, combat alert, single hit` |
| `wave_complete.wav` | ⬜ | One Shot | 1.5s | `short brass fanfare stinger, triumphant 3-note victory hit, game round complete, punchy and bright` |

---

## 4. SFX — Wrogowie

> Folder: `assets/audio/sfx/enemies/`

| Plik | ✅ | Type | Duration | Prompt ElevenLabs |
|------|----|------|----------|-------------------|
| `enemy_death.wav` | ⬜ | One Shot | 0.4s | `small creature death squeal, alien organic texture, quick dying yelp, short wet pop` |
| `enemy_hit.wav` | ⬜ | One Shot | 0.3s | `flesh impact hit, wet thud texture, creature pain grunt, soft body impact` |
| `boss_roar.wav` | ⬜ | One Shot | 2s | `massive creature roar, deep guttural bellow with reverb, intimidating low frequency rumble, ancient monster texture` |
| `boss_death.wav` | ⬜ | One Shot | 3s | `giant monster death, massive body collapse thud, dying groan fading, earth shaking impact, dramatic decay` |
| `boss_appear.wav` | ⬜ | One Shot | 2s | `creature emerging from underground, earth cracking and splitting, rising tension impact, dramatic reveal boom` |

---

## 5. Muzyka — Areny

> Folder: `assets/audio/music/`
> Narzędzie: **ElevenLabs** — ustaw Duration i Loop w UI, nie w prompcie.

### Arena Dżungla (regeneruj w nowym chiptune stylu)

**`arena_jungle/jungle_base.mp3`** ⬜ *(zastąp obecny)* | Loop | 45s
```
chiptune 8-bit military video game jungle level theme, mid tempo 100 BPM, tropical percussion with snare hits, square wave melody with exotic undertones, dense and groovy, tense jungle patrol atmosphere, Enter the Gungeon style, triangle bass pulse
```

**`arena_jungle/jungle_intense.mp3`** ⬜ *(zastąp obecny)* | Loop | 30s
```
chiptune 8-bit jungle boss battle music, fast combat 140 BPM, aggressive square wave lead riff, hard snare drum, fast hi-hat, brass stabs, high energy tropical action, Enter the Gungeon boss fight style
```

---

**`arena_desert/desert_base.mp3`** ⬜ | Loop | 45s
```
chiptune 8-bit military video game desert level theme, mid tempo 110 BPM, synth brass fanfare motif, punchy snare drum, sandy dusty atmosphere, tense but steady, Broforce style, square wave leads, triangle bass
```

**`arena_desert/desert_intense.mp3`** ⬜ | Loop | 30s
```
chiptune 8-bit military video game desert boss battle, fast 150 BPM, driving kick drum, aggressive square wave synth lead, brass stabs, rapid arpeggio bass line, high energy adrenaline, Enter the Gungeon boss music style
```

**`arena_bunker/bunker_base.mp3`** ⬜ | Loop | 60s
```
chiptune 8-bit industrial military underground bunker level music, dark and mechanical, 120 BPM, heavy synth bass pulse, industrial percussion with metal clangs, minor key, tense ominous atmosphere, Hotline Miami meets Enter the Gungeon
```

**`arena_bunker/bunker_intense.mp3`** ⬜ | Loop | 30s
```
chiptune 8-bit metal underground boss battle, intense industrial military combat, 160 BPM, aggressive distorted square wave guitar riff, blast beat drums, synth brass hits, dark minor key, maximum intensity final boss energy, Enter the Gungeon final boss style
```

---

## 6. Muzyka — Cutsceny

> Folder: `assets/audio/music/cutscenes/`
> Narzędzie: **ElevenLabs** — ustaw Duration i Loop w UI.

**`cutscene_cave_ambient.mp3`** ⬜ | Loop | 40s
```
chiptune 8-bit dark cave atmosphere, ancient underground mystery, slow 70 BPM, minor key arpeggio pattern on triangle wave, deep square wave bass drone, sparse percussion with echo, eerie and ominous, Enter the Gungeon cave level style
```

**`cutscene_tense.mp3`** ⬜ | Loop | 50s
```
chiptune 8-bit military tension theme, slow building suspense, 85 BPM, minor key, pulsing square wave bass ostinato, sparse hi-hat rhythm, dissonant triangle wave lead slowly rising, ominous and dark, Enter the Gungeon boss approach music
```

**`cutscene_march.mp3`** ⬜ | One Shot | 45s
```
chiptune 8-bit heroic military march, 120 BPM, square wave brass fanfare melody, snare drum cadence, triumphant and determined, soldiers going to battle, Enter the Gungeon meets Broforce style, driving percussion
```

**`cutscene_victory_end.mp3`** ⬜ | One Shot | 90s
```
chiptune 8-bit bittersweet ending theme, slow 75 BPM, major key with minor chord resolution, gentle triangle wave melody, simple square wave accompaniment, sparse drum pattern fading out, hopeful but melancholic, Undertale 8-bit style emotional ending
```

---

## 7. Workflow

**SFX i Muzyka** (elevenlabs.io/sound-effects):
1. Wklej prompt
2. Ustaw **Duration** (sekundy z tabeli)
3. Ustaw **Loop** lub **One Shot**
4. Generuj → pobierz
4. Wrzuć do odpowiedniego folderu (`sfx/cutscene/`, `sfx/weapons/` etc.)

**Muzyka** (suno.com → zakładka **Simple** lub **Advanced**):
1. Kliknij **Instrumental** (wyłącz vocals)
2. Wklej prompt z bloku kodu pod nazwą pliku
3. Wygeneruj → pobierz `.mp3`
4. Wrzuć do odpowiedniego folderu (`music/cutscenes/`, `music/arena_desert/` etc.)

**Po wrzuceniu:** odśwież projekt w Godocie → pliki zaimportują się automatycznie → zaktualizuj ✅ w tabeli.

---

## 8. Status

| Kategoria | Gotowe | Razem |
|-----------|--------|-------|
| SFX cutscen | 0 | 7 |
| SFX broń | 3 (rifle) | 14 |
| SFX UI | 0 | 6 |
| SFX wrogowie | 0 | 5 |
| Muzyka areny | 2 (jungle) | 6 |
| Muzyka cutscen | 0 | 4 |
