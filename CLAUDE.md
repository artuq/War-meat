# CLAUDE.md — War-Meat Discovery Index
# Wzorowane na: lurek_2d/.github/copilot-instructions.md
# Ten plik jest ZAWSZE wczytywany. Zawiera routing do agents/skills/prompts.

## Projekt

**War-Meat** — mobile horde survivor (Android), Godot 4.6.2 / GDScript.
Brotato/Vampire Survivors style. Squad 1-4 żołnierzy ("War Meat" — kiełbasy).

## Tech Stack

| Warstwa | Technologia |
|---------|-------------|
| Engine | Godot 4.6.2 |
| Język | GDScript (no C#) |
| Testowanie | gdUnit4 (addons/gdunit4/) |
| QA orchestration | Python 3 (tests/run_qa.py) |
| CI/CD | GitHub Actions (.github/workflows/qa.yml) |

## Struktura katalogów

```
src/                 # kod gry (GDScript)
  autoloads/         # GameManager, EventBus, SoundManager, SettingsManager
  components/        # HealthComponent, HitboxComponent, HurtboxComponent
  data/              # WeaponData, WaveData, UpgradeData, PassiveItem
  entities/          # enemies/, squad/, projectiles/
  maps/              # arena.gd, debris_layer.gd, arena_narrative.gd
  systems/           # wave_manager.gd, kill_streak.gd, particle_factory.gd
  ui/                # shop_ui.gd, upgrade_panel.gd, hud.gd, stats_column.gd
  effects/           # flash.gdshader, spawn_telegraph.gd

tests/               # QA (gdUnit4 + Python)
  unit/              # logika bez scen
  integration/       # systemy razem
  visual/            # screenshoty + pixel diff
  reports/           # XML/JSON/HTML output
  run_qa.py          # Python orchestrator

.claude/             # CAG system (jak lurek_2d/.github/)
  agents/            # qa-manager, qa-tester, qa-analyzer, qa-scenario-writer
  skills/            # game-mechanics, testing-gdunit4, godot-headless

tools/               # process_sprite.py, wrzuc_web.py, install_gdunit4.sh
```

## CAG Routing

Ładuj skills ON DEMAND gdy task pasuje:

| Zadanie | Załaduj |
|---------|---------|
| QA, testowanie | .claude/agents/qa-manager.agent.md |
| **AI analiza screenshotów po run_qa.py** | **.claude/skills/qa-analyze/SKILL.md** |
| Pisanie testów | .claude/skills/testing-gdunit4/SKILL.md |
| Weryfikacja zachowania gry | .claude/skills/game-mechanics/SKILL.md |
| Uruchamianie Godot headless | .claude/skills/godot-headless/SKILL.md |
| Naprawianie buga | .claude/skills/game-mechanics/SKILL.md |

## Kluczowe konwencje kodu

- **configure() PO add_child** — HealthComponent jest @onready
- **hp/max_hp** — properties delegujące do HealthComponent (nie raw fields)
- **EventBus** — wszystkie sygnały inter-systemowe przez autoload EventBus
- **TEXTURE_FILTER_NEAREST** — dla wszystkich pixel art sprite'ów

## Komendy QA

```bash
# Pełny run
python3 tests/run_qa.py

# Tylko unit
python3 tests/run_qa.py --unit-only

# Sprawdź regresję
python3 tests/run_qa.py --compare-baseline

# Zainstaluj gdUnit4
bash tools/install_gdunit4.sh
```

## Znane reguły (zawsze check game-mechanics/SKILL.md)

- Grenadier weight MUSI być > 0 (był bug weight=0)
- configure() MUSI być wywołane PO add_child
- I-frames = 0.5s (IFRAME_DURATION)
- Soldier z_index = 2 (nad wrogami)
- upgrade_panel_requested PRZED shop_opened
