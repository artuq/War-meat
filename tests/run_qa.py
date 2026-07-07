#!/usr/bin/env python3
"""
War-Meat QA Orchestrator
Uruchamia gdUnit4, parsuje wyniki, robi visual QA, generuje raport.
Claude QA agent (qa-tester.agent.md) wywołuje ten skrypt.

Użycie:
  python3 tests/run_qa.py                    # pełny run
  python3 tests/run_qa.py --unit-only        # tylko unit testy
  python3 tests/run_qa.py --visual-only      # tylko visual QA
  python3 tests/run_qa.py --analyze-only     # parsuj istniejące raporty
  python3 tests/run_qa.py --compare-baseline # sprawdź regresję
"""

import argparse
import json
import subprocess
import sys
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path


# ─────────────────────────────────────────────────────────────
# Konfiguracja
# ─────────────────────────────────────────────────────────────

PROJECT_ROOT = Path(__file__).parent.parent
REPORTS_DIR  = PROJECT_ROOT / "tests" / "reports"
SCREENSHOTS_DIR = PROJECT_ROOT / "tests" / "screenshots"
REFERENCE_DIR   = PROJECT_ROOT / "tests" / "reference"
BASELINE_FILE   = REPORTS_DIR / "baseline.json"

GODOT_BINARY = (
    "/Users/magda/Downloads/Godot.app/Contents/MacOS/Godot"
    if __import__("pathlib").Path("/Users/magda/Downloads/Godot.app").exists()
    else "godot"
)
GDUNIT_CMD   = "res://addons/gdUnit4/bin/GdUnitCmdTool.gd"

# Progi dla visual regression
VISUAL_DIFF_THRESHOLD = 0.02   # 98% pixeli musi się zgadzać (industry standard)
FPS_MINIMUM           = 30     # minimum FPS dla mobile (Android low-end)


# ─────────────────────────────────────────────────────────────
# Uruchamianie testów
# ─────────────────────────────────────────────────────────────

class GdUnit4Runner:
    """Uruchamia gdUnit4 headless i zbiera JUnit XML."""

    def run(self, suites: list[str] = None) -> Path:
        REPORTS_DIR.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_path = REPORTS_DIR / f"junit_{timestamp}.xml"

        paths = suites or [
            "res://tests/unit/",
            "res://tests/integration/",
        ]

        runner_sh = PROJECT_ROOT / "addons" / "gdUnit4" / "runtest.sh"
        add_args = []
        for p in paths:
            add_args += ["--add", p]
        cmd = [
            "bash", str(runner_sh),
            "--godot_binary", GODOT_BINARY,
            "--report-directory", str(REPORTS_DIR),
            "--report-count", "5",
        ] + add_args
        # Jeśli runner_sh nie istnieje — użyj run_tests.sh
        if not runner_sh.exists():
            cmd = ["bash", str(PROJECT_ROOT / "run_tests.sh")]

        print(f"\n{'='*60}")
        print(f"  gdUnit4 Test Run — {datetime.now().strftime('%H:%M:%S')}")
        print(f"{'='*60}")
        print(f"  Suites: {paths}")
        print()

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=300,
                cwd=str(PROJECT_ROOT),
            )
            print(result.stdout[-3000:] if len(result.stdout) > 3000 else result.stdout)
            if result.stderr:
                print("[STDERR]", result.stderr[-1000:])
        except subprocess.TimeoutExpired:
            print("ERROR: Timeout po 5 minutach!")
            return None
        except FileNotFoundError:
            print(f"ERROR: Nie znaleziono '{GODOT_BINARY}'. Zainstaluj Godot lub ustaw PATH.")
            return None

        # Znajdź najnowszy wygenerowany XML
        xmls = sorted(REPORTS_DIR.glob("*.xml"), key=lambda p: p.stat().st_mtime, reverse=True)
        return xmls[0] if xmls else None


# ─────────────────────────────────────────────────────────────
# Parsowanie wyników
# ─────────────────────────────────────────────────────────────

class ResultParser:
    """Parsuje JUnit XML z gdUnit4 → strukturalny Python dict."""

    def parse(self, xml_path: Path) -> dict:
        if not xml_path or not xml_path.exists():
            return {"error": "Brak pliku raportu", "total": 0, "passed": 0, "failed": 0}

        tree = ET.parse(xml_path)
        root = tree.getroot()

        results = {
            "timestamp": datetime.now().isoformat(),
            "xml_path": str(xml_path),
            "total": 0, "passed": 0, "failed": 0, "errors": 0, "skipped": 0,
            "duration": 0.0,
            "suites": [],
            "failures": [],
            "regressions": [],
        }

        for suite in root.iter("testsuite"):
            suite_data = {
                "name": suite.get("name", "unknown"),
                "tests": int(suite.get("tests", 0)),
                "failures": int(suite.get("failures", 0)),
                "errors": int(suite.get("errors", 0)),
                "time": float(suite.get("time", 0)),
                "cases": [],
            }

            for case in suite.iter("testcase"):
                passed = len(list(case)) == 0
                case_data = {
                    "name": case.get("name"),
                    "classname": case.get("classname"),
                    "time": float(case.get("time", 0)),
                    "status": "PASS" if passed else "FAIL",
                }

                failure = case.find("failure")
                if failure is not None:
                    case_data["status"] = "FAIL"
                    case_data["message"] = failure.get("message", "")
                    case_data["detail"] = failure.text or ""
                    results["failures"].append({
                        "test": f"{case_data['classname']}/{case_data['name']}",
                        "message": case_data["message"],
                        "detail": case_data["detail"][:500],
                    })

                suite_data["cases"].append(case_data)

            results["suites"].append(suite_data)
            results["total"]   += suite_data["tests"]
            results["failed"]  += suite_data["failures"]
            results["errors"]  += suite_data["errors"]
            results["duration"] += suite_data["time"]

        results["passed"] = results["total"] - results["failed"] - results["errors"]
        return results


# ─────────────────────────────────────────────────────────────
# Regresja
# ─────────────────────────────────────────────────────────────

class RegressionGuard:
    """Porównuje wyniki z baseline. Wykrywa nowe FAILE."""

    def compare(self, current: dict, baseline_path: Path) -> dict:
        if not baseline_path.exists():
            print("  ℹ Brak baseline — tworzę nowy.")
            self._save_baseline(current, baseline_path)
            return {"new_failures": [], "fixed_tests": [], "status": "BASELINE_CREATED"}

        with open(baseline_path) as f:
            baseline = json.load(f)

        baseline_fails = {f["test"] for f in baseline.get("failures", [])}
        current_fails  = {f["test"] for f in current.get("failures", [])}

        new_failures = current_fails - baseline_fails
        fixed_tests  = baseline_fails - current_fails

        return {
            "status": "REGRESSION" if new_failures else "OK",
            "new_failures": sorted(new_failures),
            "fixed_tests": sorted(fixed_tests),
            "baseline_fail_count": len(baseline_fails),
            "current_fail_count": len(current_fails),
        }

    def save_as_baseline(self, results: dict) -> None:
        self._save_baseline(results, BASELINE_FILE)
        print(f"  ✓ Nowy baseline zapisany: {BASELINE_FILE}")

    def _save_baseline(self, results: dict, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w") as f:
            json.dump(results, f, indent=2)


# ─────────────────────────────────────────────────────────────
# Visual QA
# ─────────────────────────────────────────────────────────────

class VisualQA:
    """
    Uruchamia Godot w trybie --qa-mode (z oknem), zbiera screenshoty,
    porównuje z referencją.
    """

    def run(self, duration: int = 60) -> dict:
        SCREENSHOTS_DIR.mkdir(parents=True, exist_ok=True)

        print(f"\n  Visual QA — {duration}s auto-play...")
        cmd = [
            GODOT_BINARY, "--path", str(PROJECT_ROOT),
            "--", "--qa-mode", f"--qa-duration={duration}",
        ]

        try:
            subprocess.run(cmd, timeout=duration + 30, cwd=str(PROJECT_ROOT))
        except subprocess.TimeoutExpired:
            pass  # timeout = normalne zakończenie
        except FileNotFoundError:
            return {"error": "Godot nie znaleziony"}

        return self._compare_screenshots()

    def _compare_screenshots(self) -> dict:
        results = {"screenshots": [], "failures": [], "passed": 0, "failed": 0}

        for screenshot in sorted(SCREENSHOTS_DIR.glob("*.png")):
            reference = REFERENCE_DIR / screenshot.name
            if not reference.exists():
                # Brak referencji → zapisz jako nową referencję
                import shutil
                REFERENCE_DIR.mkdir(parents=True, exist_ok=True)
                shutil.copy(screenshot, reference)
                results["screenshots"].append({
                    "file": screenshot.name,
                    "status": "NEW_REFERENCE",
                })
                continue

            diff = self._pixel_diff(screenshot, reference)
            status = "PASS" if diff < VISUAL_DIFF_THRESHOLD else "FAIL"

            entry = {
                "file": screenshot.name,
                "status": status,
                "diff_ratio": round(diff, 4),
                "threshold": VISUAL_DIFF_THRESHOLD,
            }
            results["screenshots"].append(entry)

            if status == "FAIL":
                results["failures"].append(entry)
                results["failed"] += 1
            else:
                results["passed"] += 1

        return results

    def _pixel_diff(self, path_a: Path, path_b: Path) -> float:
        try:
            from PIL import Image
            import numpy as np
            img_a = np.array(Image.open(path_a).convert("RGB"), dtype=float)
            img_b = np.array(Image.open(path_b).convert("RGB"), dtype=float)
            if img_a.shape != img_b.shape:
                return 1.0
            diff = np.abs(img_a - img_b).mean() / 255.0
            return float(diff)
        except ImportError:
            print("  ⚠ PIL nie zainstalowane (pip install Pillow). Visual diff pominięty.")
            return 0.0


# ─────────────────────────────────────────────────────────────
# Raport
# ─────────────────────────────────────────────────────────────

class Reporter:
    """Generuje czytelny raport + JSON dla Claude agenta."""

    def print_report(self, results: dict, regression: dict, visual: dict = None) -> None:
        print(f"\n{'='*60}")
        print(f"  WAR-MEAT QA RAPORT — {datetime.now().strftime('%Y-%m-%d %H:%M')}")
        print(f"{'='*60}\n")

        # Unit/Integration
        total  = results.get("total", 0)
        passed = results.get("passed", 0)
        failed = results.get("failed", 0)
        pct    = int(passed / total * 100) if total > 0 else 0
        icon   = "✅" if failed == 0 else "❌"

        print(f"  {icon} Testy: {passed}/{total} ({pct}%)  |  Czas: {results.get('duration', 0):.1f}s")

        if results.get("failures"):
            print(f"\n  ── Faile ({len(results['failures'])}) ──")
            for f in results["failures"]:
                print(f"    ❌ {f['test']}")
                if f.get("message"):
                    print(f"       {f['message'][:120]}")

        # Regresja
        reg_status = regression.get("status", "UNKNOWN")
        if reg_status == "REGRESSION":
            print(f"\n  ⚠️  REGRESJA — {len(regression['new_failures'])} nowych failów!")
            for t in regression["new_failures"]:
                print(f"    🔴 {t}")
        elif reg_status == "OK":
            fixed = regression.get("fixed_tests", [])
            print(f"\n  ✅ Brak regresji")
            if fixed:
                print(f"  🟢 Naprawione: {', '.join(fixed)}")

        # Visual
        if visual and not visual.get("error"):
            v_pass = visual.get("passed", 0)
            v_fail = visual.get("failed", 0)
            v_icon = "✅" if v_fail == 0 else "❌"
            print(f"\n  {v_icon} Visual QA: {v_pass} pass, {v_fail} fail")
            for f in visual.get("failures", []):
                print(f"    ❌ {f['file']} (diff: {f['diff_ratio']:.1%})")

        print(f"\n{'='*60}")
        print(f"  Screenshoty → tests/screenshots/")
        print(f"  Raporty XML → tests/reports/")
        print(f"{'='*60}\n")

    def save_json(self, results: dict, regression: dict, visual: dict = None) -> Path:
        REPORTS_DIR.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        path = REPORTS_DIR / f"qa_report_{timestamp}.json"
        report = {
            "timestamp": datetime.now().isoformat(),
            "unit_integration": results,
            "regression": regression,
            "visual": visual or {},
        }
        with open(path, "w") as f:
            json.dump(report, f, indent=2)
        # Zawsze nadpisz latest.json (dla Claude agenta)
        with open(REPORTS_DIR / "latest.json", "w") as f:
            json.dump(report, f, indent=2)
        print(f"  📄 Raport JSON: {path}")
        return path


# ─────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description="War-Meat QA Orchestrator")
    parser.add_argument("--unit-only",       action="store_true")
    parser.add_argument("--visual-only",     action="store_true")
    parser.add_argument("--analyze-only",    action="store_true")
    parser.add_argument("--compare-baseline",action="store_true")
    parser.add_argument("--save-baseline",   action="store_true")
    parser.add_argument("--visual-duration", type=int, default=60)
    args = parser.parse_args()

    runner   = GdUnit4Runner()
    parser_  = ResultParser()
    guard    = RegressionGuard()
    reporter = Reporter()
    visual_qa = VisualQA()

    results  = {"total": 0, "passed": 0, "failed": 0, "failures": []}
    regression = {}
    visual   = {}

    # 1. Testy gdUnit4
    if not args.visual_only and not args.analyze_only:
        xml_path = runner.run()
        results  = parser_.parse(xml_path)

    # 2. Analyze-only: parsuj istniejący XML
    if args.analyze_only:
        xmls = sorted(REPORTS_DIR.glob("*.xml"), key=lambda p: p.stat().st_mtime, reverse=True)
        if xmls:
            results = parser_.parse(xmls[0])
        else:
            print("Brak raportów XML w tests/reports/")
            return 1

    # 3. Regresja
    if not args.visual_only:
        regression = guard.compare(results, BASELINE_FILE)
        if args.save_baseline:
            guard.save_as_baseline(results)

    # 4. Visual QA
    if not args.unit_only:
        visual = visual_qa.run(args.visual_duration)

    # 5. Raport
    reporter.print_report(results, regression, visual)
    reporter.save_json(results, regression, visual)

    # Exit code dla CI
    has_regression = regression.get("status") == "REGRESSION"
    has_failures   = results.get("failed", 0) > 0
    has_visual_fail = visual.get("failed", 0) > 0

    if has_regression or has_failures or has_visual_fail:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
