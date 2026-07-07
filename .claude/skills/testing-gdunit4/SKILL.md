# testing-gdunit4/SKILL.md
# Load when: piszesz testy GDScript, analizujesz wyniki, tworzysz scenariusze
# Skip when: piszesz kod gry, edytujesz UI, pracujesz z C#

## Instalacja

```bash
bash tools/install_gdunit4.sh
# następnie w Godot: Project → Plugins → gdUnit4 → Enable
```

## Struktura testu

```gdscript
extends GdUnitTestSuite
class_name TestNazwaSystemu

func before_all() -> void:   # raz przed wszystkimi testami
func before_each() -> void:  # przed każdym testem (setup)
func after_each() -> void:   # po każdym teście (teardown)
func after_all() -> void:    # raz po wszystkich

func test_cokolwiek() -> void:   # prefiks test_ = automatycznie uruchamiany
```

## Assertions — pełna lista

```gdscript
# Integers
assert_int(value).is_equal(42)
assert_int(value).is_greater(0)
assert_int(value).is_less(100)
assert_int(value).is_greater_equal(0)
assert_int(value).is_less_equal(100)
assert_int(value).is_not_equal(0)

# Floats
assert_float(value).is_equal_approx(1.0, 0.001)
assert_float(value).is_greater(0.0)
assert_float(value).is_less(1.0)

# Bools
assert_bool(value).is_true()
assert_bool(value).is_false()

# Strings
assert_str(value).is_equal("expected")
assert_str(value).contains("substring")
assert_str(value).is_not_empty()

# Objects
assert_object(obj).is_not_null()
assert_object(obj).is_null()

# Arrays
assert_array(arr).is_not_empty()
assert_array(arr).contains(element)
assert_array(arr).not_contains(element)
assert_array(arr).is_equal([1, 2, 3])

# Vectors
assert_vector2(v).is_equal(Vector2(1, 0))
assert_vector2(v).is_not_equal(Vector2.ZERO)

# Custom message (zawsze dodawaj dla czytelności)
assert_int(val).is_equal(5).override_failure_message("HP powinno być 5 po 1 strzale")
```

## Sygnały (kluczowe dla War-meat)

```gdscript
# Monitoruj sygnały na node
var monitor := monitor_signals(my_node)
# ... wywołaj akcję ...
assert_signal_emitted(monitor, my_node, "on_unit_died")
assert_signal_not_emitted(monitor, my_node, "on_unit_died")
assert_signal_emitted_with_parameters(monitor, node, "health_changed", [50, 100])

# EventBus sygnały
var eb_monitor := monitor_signals(EventBus)
soldier.take_damage(10)
assert_signal_emitted(eb_monitor, EventBus, "soldier_damaged")
```

## Async / Timing

```gdscript
await wait_frames(5)        # odczekaj 5 klatek fizyki
await wait_millis(500)      # odczekaj 500ms (przydatne dla i-frames = 500ms)
```

## Auto cleanup

```gdscript
# auto_free() = queue_free() po teście, bezpieczne dla Node
var soldier := auto_free(Soldier.new())
var hc := auto_free(HealthComponent.new())

# Instancja sceny
var scene := load("res://src/entities/squad/soldier.tscn") as PackedScene
var soldier: Soldier = auto_free(scene.instantiate())
add_child(soldier)
await wait_frames(2)  # WAŻNE: czekaj na _ready()
```

## Uruchamianie headless

```bash
# Wszystkie testy
godot --headless -s res://addons/gdunit4/GdUnitCmdTool.gd \
  --add res://tests/unit/ \
  --add res://tests/integration/ \
  --report-directory tests/reports

# Jeden plik
godot --headless -s res://addons/gdunit4/GdUnitCmdTool.gd \
  --add res://tests/unit/test_health_component.gd

# Via Python orchestrator (rekomendowane)
python3 tests/run_qa.py --unit-only
```

## Zasady pisania testów War-meat

1. **Jeden assert na jeden powód faila** — `test_grenadier_spawns()` nie `test_all_enemies()`
2. **override_failure_message zawsze** — czytelny komunikat zamiast "Expected 0, got 1"
3. **Sformalizuj każdy bug** — każdy bug z historii = test regresji
4. **await po add_child** — `await wait_frames(2)` zanim cokolwiek testujesz na node
5. **configure() PO add_child** — reguła kontraktu z tej sesji
6. **Sprawdź EventBus** — kluczowe działania emitują sygnały które inne systemy słuchają

## Output

```
tests/reports/junit_YYYYMMDD_HHMMSS.xml   ← JUnit XML
tests/reports/report.html                  ← HTML (czytelny)
tests/reports/latest.json                  ← dla Claude agenta
```
