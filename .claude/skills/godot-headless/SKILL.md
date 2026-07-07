# godot-headless/SKILL.md
# Load when: uruchamiasz Godot z terminala, konfigurujesz CI, debugujesz headless run
# Skip when: pracujesz w edytorze Godot, piszesz kod gry

## Podstawowe komendy

```bash
# Headless — bez okna, bez renderowania (dla CI)
godot --headless --path /path/to/project

# Z oknem (dla visual QA)
godot --path /path/to/project -- --qa-mode

# Uruchom konkretny skrypt
godot --headless -s res://ścieżka/do/skryptu.gd

# gdUnit4 headless runner
godot --headless -s res://addons/gdunit4/GdUnitCmdTool.gd \
  --add res://tests/ \
  --report-directory tests/reports
```

## Argumenty wiersza poleceń

```bash
# Własne argumenty gry (po --)
godot --path . -- --qa-mode --qa-duration=60

# Sprawdzenie w GDScript
var args = OS.get_cmdline_args()
if "--qa-mode" in args:
    QAMode.active = true
```

## Gdzie szukać Godot binary

```bash
# macOS (Godot.app)
/Applications/Godot.app/Contents/MacOS/Godot

# macOS (symlink przez PATH)
which godot

# Linux
/usr/local/bin/godot

# Sprawdź wersję
godot --version   # powinno zwrócić 4.6.2
```

## Typowe błędy headless

| Błąd | Przyczyna | Fix |
|------|-----------|-----|
| `DisplayServer not found` | Brak `--headless` lub brak headless support w buildzie | Sprawdź build templates |
| `ERROR: res://... not found` | Zły --path | Ustaw --path na katalog z project.godot |
| `Class not found: HealthComponent` | Nowe pliki nie zaimportowane | Otwórz projekt w edytorze raz |
| Timeout po 5min | Test nieskończony (await bez końca) | Sprawdź czy sygnał jest emitowany |
| Exit code 1 | Faile testów | Normalny — sprawdź XML raport |

## Screenshoty w headless (SubViewport)

```gdscript
# W trybie headless brak renderowania, ale SubViewport działa
func capture_headless_frame(label: String) -> void:
    var svp := SubViewport.new()
    svp.size = Vector2i(1280, 720)
    svp.render_target_update_mode = SubViewport.UPDATE_ONCE
    add_child(svp)
    await RenderingServer.frame_post_draw
    var img := svp.get_texture().get_image()
    img.save_png("tests/screenshots/%s.png" % label)
    svp.queue_free()
```

## Visual QA (z oknem, nie headless)

```bash
# Uruchom z oknem, gra gra się automatycznie
godot --path . -- --qa-mode --qa-duration=60

# Python odpala to jako subprocess
import subprocess
subprocess.run(["godot", "--path", ".", "--", "--qa-mode", "--qa-duration=60"],
               timeout=90)
```

## CI GitHub Actions

```yaml
- name: Setup Godot
  uses: chickensoft-games/setup-godot@v1
  with:
    version: 4.6.2
    use-dotnet: false
    export-templates: false

- name: Run Tests  
  uses: MikeSchulze/gdUnit4-action@v1.1.9
  with:
    godot-version: 4.6.2
    paths: res://tests/unit/
```

## Exit codes

| Code | Znaczenie |
|------|-----------|
| 0 | Wszystkie testy zielone |
| 1 | Są faile (sprawdź XML) |
| 255 | Błąd startu Godota |
