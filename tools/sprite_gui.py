"""
WRZUC SPRITE GUI — War Meat Sprite Processor
=============================================
Graphical front-end for process_sprite.py.
Works on macOS (Aqua/ttk) and Windows (dark tk theme).

Build to EXE (Windows):
  pyinstaller --onefile --windowed --name "WRZUC_SPRITE_GUI" tools/sprite_gui.py
"""
from __future__ import annotations

import io
import queue
import sys
import threading
from pathlib import Path

# ── Resolve repo root ────────────────────────────────────────────────────────
TOOLS_DIR = Path(__file__).resolve().parent
REPO_ROOT = TOOLS_DIR.parent
sys.path.insert(0, str(TOOLS_DIR))

try:
    import process_sprite as ps
except ImportError as e:
    import tkinter as tk
    from tkinter import messagebox
    _r = tk.Tk(); _r.withdraw()
    messagebox.showerror("Import error", f"Cannot import process_sprite:\n{e}")
    sys.exit(1)

import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext, ttk

_MAC = sys.platform == "darwin"

# On macOS TkinterDnD causes rendering issues — disable drag & drop there.
_HAS_DND = False
if not _MAC:
    try:
        from tkinterdnd2 import DND_FILES, TkinterDnD
        _HAS_DND = True
    except ImportError:
        pass

# ── Platform fonts ────────────────────────────────────────────────────────────
if _MAC:
    FONT      = ("Helvetica Neue", 12)
    FONT_BOLD = ("Helvetica Neue", 12, "bold")
    FONT_MONO = ("Menlo", 11)
    FONT_SM   = ("Helvetica Neue", 10)
else:
    FONT      = ("Segoe UI", 10)
    FONT_BOLD = ("Segoe UI", 10, "bold")
    FONT_MONO = ("Consolas", 9)
    FONT_SM   = ("Segoe UI", 9)

# ── Colors (only used on Windows dark theme; macOS uses ttk system colors) ────
if _MAC:
    ACCENT    = "#007aff"
    BTN_FG    = "#ffffff"
    SUCCESS   = "#248a3d"
    WARN      = "#c85000"
    ERR       = "#c00000"
    HDR       = "#8b4a00"
    LOG_BG    = "#ffffff"
    LOG_FG    = "#1c1c1e"
else:
    ACCENT    = "#4a9eff"
    BTN_FG    = "#000000"
    BG        = "#1e1e2e"
    PANEL     = "#2a2a3e"
    TEXT      = "#e0e0e0"
    TEXT_DIM  = "#888899"
    SUCCESS   = "#5a9e5a"
    WARN      = "#e07020"
    ERR       = "#cc4444"
    HDR       = "#ffd700"
    LOG_BG    = "#0d0d1a"
    LOG_FG    = "#e0e0e0"
    DROP_IDLE = "#3a3a5e"
    DROP_HOV  = "#4a4a7e"

CATEGORIES = ["(auto-detect)", "soldiers", "enemies", "weapons", "loot", "fx"]


# ── stdout → queue ────────────────────────────────────────────────────────────
class QueueStream(io.RawIOBase):
    def __init__(self, q: queue.Queue) -> None:
        self.q = q

    def write(self, s: str) -> int:
        if s:
            self.q.put(s)
        return len(s)

    def readable(self) -> bool:
        return False


# ── App ───────────────────────────────────────────────────────────────────────
class App:
    def __init__(self) -> None:
        if _HAS_DND:
            self.root = TkinterDnD.Tk()  # type: ignore[name-defined]
        else:
            self.root = tk.Tk()

        self.root.title("WRZUC SPRITE — War Meat Pipeline")
        self.root.geometry("680x620")
        self.root.minsize(580, 500)
        self.root.resizable(True, True)

        self._files: list[Path] = []
        self._log_queue: queue.Queue = queue.Queue()
        self._processing = False

        if _MAC:
            self._build_ui_mac()
        else:
            self._build_ui_win()

        self._poll_log()

    # ══════════════════════════════════════════════════════════════════════════
    # macOS layout — flat, no nested frames, grid-based
    # ══════════════════════════════════════════════════════════════════════════

    def _build_ui_mac(self) -> None:
        P = 10  # standard padding

        # ── Title (plain tk.Label — guaranteed visible) ───────────────────────
        tk.Label(self.root, text="WRZUC SPRITE", font=FONT_BOLD).pack(pady=(P, 0))
        tk.Label(self.root, text="AI Studio JPG/PNG → game-ready PNG",
                 font=FONT_SM).pack()

        tk.Frame(self.root, height=1, bg="#cccccc").pack(fill="x", padx=P, pady=(P, 0))

        # ── Files ─────────────────────────────────────────────────────────────
        tk.Label(self.root, text="Pliki do przetworzenia:", font=FONT_BOLD,
                 anchor="w").pack(fill="x", padx=P, pady=(P, 2))

        self._file_listbox = tk.Listbox(self.root, height=4, font=FONT_MONO,
                                        relief="sunken", bd=1, selectmode="extended")
        self._file_listbox.pack(fill="x", padx=P)

        file_btns = tk.Frame(self.root)
        file_btns.pack(fill="x", padx=P, pady=(4, 0))
        tk.Button(file_btns, text="+ Dodaj pliki", font=FONT,
                  command=self._browse_files).pack(side="left")
        tk.Button(file_btns, text="Wyczyść listę", font=FONT,
                  command=self._clear_files).pack(side="left", padx=(6, 0))

        tk.Frame(self.root, height=1, bg="#cccccc").pack(fill="x", padx=P, pady=(P, 0))

        # ── Options ───────────────────────────────────────────────────────────
        tk.Label(self.root, text="Opcje:", font=FONT_BOLD,
                 anchor="w").pack(fill="x", padx=P, pady=(P, 2))

        opt_row1 = tk.Frame(self.root)
        opt_row1.pack(fill="x", padx=P)

        tk.Label(opt_row1, text="Kategoria:", font=FONT).pack(side="left")
        self._cat_var = tk.StringVar(value="(auto-detect)")
        ttk.Combobox(opt_row1, textvariable=self._cat_var, values=CATEGORIES,
                     state="readonly", width=14).pack(side="left", padx=(6, 20))

        tk.Label(opt_row1, text="Resize:", font=FONT).pack(side="left")
        self._resize_var = tk.StringVar(value="auto")
        tk.Entry(opt_row1, textvariable=self._resize_var,
                 width=8, font=FONT, relief="sunken", bd=1).pack(side="left", padx=(6, 4))
        tk.Label(opt_row1, text="px  (auto / 128 / 96x32)", font=FONT_SM).pack(side="left")

        opt_row2 = tk.Frame(self.root)
        opt_row2.pack(fill="x", padx=P, pady=(6, 0))

        self._outline_var    = tk.BooleanVar(value=False)
        self._no_palette_var = tk.BooleanVar(value=False)
        self._no_bg_var      = tk.BooleanVar(value=False)

        tk.Checkbutton(opt_row2, text="Dodaj outline",     variable=self._outline_var,    font=FONT).pack(side="left", padx=(0, 14))
        tk.Checkbutton(opt_row2, text="Pomiń paletę",      variable=self._no_palette_var, font=FONT).pack(side="left", padx=(0, 14))
        tk.Checkbutton(opt_row2, text="Pomiń usuwanie tła",variable=self._no_bg_var,      font=FONT).pack(side="left")

        tk.Frame(self.root, height=1, bg="#cccccc").pack(fill="x", padx=P, pady=(P, 0))

        # ── Process button ────────────────────────────────────────────────────
        self._process_btn = tk.Button(
            self.root, text="▶  PRZETWÓRZ",
            bg=ACCENT, fg=BTN_FG, relief="flat",
            font=FONT_BOLD, padx=20, pady=8,
            cursor="hand2", command=self._start_processing,
        )
        self._process_btn.pack(pady=8)

        # ── Log ───────────────────────────────────────────────────────────────
        log_hdr = tk.Frame(self.root)
        log_hdr.pack(fill="x", padx=P)
        tk.Label(log_hdr, text="Log:", font=FONT_BOLD).pack(side="left")
        tk.Button(log_hdr, text="Wyczyść log", font=FONT_SM,
                  command=lambda: self._log.delete("1.0", "end")).pack(side="right")

        self._log = scrolledtext.ScrolledText(
            self.root, bg=LOG_BG, fg=LOG_FG,
            font=FONT_MONO, wrap="word", state="disabled", height=8,
        )
        self._log.pack(fill="both", expand=True, padx=P, pady=(2, P))
        self._log.tag_config("ok",   foreground=SUCCESS)
        self._log.tag_config("warn", foreground=WARN)
        self._log.tag_config("err",  foreground=ERR)
        self._log.tag_config("hdr",  foreground=HDR)

    # ══════════════════════════════════════════════════════════════════════════
    # Windows layout (dark tk theme)
    # ══════════════════════════════════════════════════════════════════════════

    def _build_ui_win(self) -> None:
        self.root.configure(bg=BG)

        tk.Label(self.root, text="WRZUC SPRITE — War Meat Pipeline",
                 bg=BG, fg=HDR, font=FONT_BOLD).pack(pady=(12, 2))
        tk.Label(self.root, text="AI Studio → game-ready PNG",
                 bg=BG, fg=TEXT_DIM, font=FONT_SM).pack()

        # Drop zone
        dz = tk.Frame(self.root, bg=DROP_IDLE,
                      highlightbackground=ACCENT, highlightthickness=2)
        dz.pack(fill="x", padx=16, pady=(10, 4))
        dz_label = tk.Label(dz,
            text="Przeciagnij tu pliki JPG/PNG  lub  kliknij Dodaj pliki",
            bg=DROP_IDLE, fg=TEXT_DIM, font=FONT, pady=14)
        dz_label.pack(fill="x")
        if _HAS_DND:
            for w in (dz, dz_label):
                w.drop_target_register(DND_FILES)  # type: ignore[attr-defined]
                w.dnd_bind("<<DropEnter>>",  # type: ignore[attr-defined]
                           lambda e, f=dz, l=dz_label: (f.config(bg=DROP_HOV), l.config(bg=DROP_HOV)))
                w.dnd_bind("<<DropLeave>>",  # type: ignore[attr-defined]
                           lambda e, f=dz, l=dz_label: (f.config(bg=DROP_IDLE), l.config(bg=DROP_IDLE)))
                w.dnd_bind("<<Drop>>", self._on_drop)  # type: ignore[attr-defined]

        # File list
        fl = tk.Frame(self.root, bg=BG)
        fl.pack(fill="x", padx=16, pady=(2, 0))
        hdr = tk.Frame(fl, bg=BG); hdr.pack(fill="x")
        tk.Label(hdr, text="Pliki:", bg=BG, fg=TEXT, font=FONT_BOLD).pack(side="left")
        tk.Button(hdr, text="Wyczysc", bg=PANEL, fg=TEXT_DIM,
                  relief="flat", font=FONT_SM, command=self._clear_files).pack(side="right")
        lf = tk.Frame(fl, bg=PANEL); lf.pack(fill="x", pady=(2, 0))
        self._file_listbox = tk.Listbox(lf, height=4, bg=PANEL, fg=TEXT,
                                        selectbackground=ACCENT, relief="flat",
                                        font=FONT_MONO, activestyle="none")
        self._file_listbox.pack(fill="x", padx=4, pady=4)

        # Options
        opt = tk.LabelFrame(self.root, text=" Opcje ",
                            bg=PANEL, fg=ACCENT, font=FONT_BOLD,
                            bd=1, relief="groove")
        opt.pack(fill="x", padx=16, pady=(8, 0))
        r1 = tk.Frame(opt, bg=PANEL); r1.pack(fill="x", padx=10, pady=(6, 2))
        tk.Label(r1, text="Kategoria:", bg=PANEL, fg=TEXT, font=FONT).pack(side="left")
        self._cat_var = tk.StringVar(value="(auto-detect)")
        ttk.Combobox(r1, textvariable=self._cat_var, values=CATEGORIES,
                     state="readonly", width=14).pack(side="left", padx=(6, 20))
        tk.Label(r1, text="Resize:", bg=PANEL, fg=TEXT, font=FONT).pack(side="left")
        self._resize_var = tk.StringVar(value="auto")
        tk.Entry(r1, textvariable=self._resize_var, width=7,
                 bg=BG, fg=TEXT, insertbackground=TEXT, relief="flat",
                 font=FONT).pack(side="left", padx=(6, 4))
        tk.Label(r1, text="px (auto/128/96x32)", bg=PANEL, fg=TEXT_DIM,
                 font=FONT_SM).pack(side="left")
        r2 = tk.Frame(opt, bg=PANEL); r2.pack(fill="x", padx=10, pady=(0, 8))
        self._outline_var    = tk.BooleanVar(value=False)
        self._no_palette_var = tk.BooleanVar(value=False)
        self._no_bg_var      = tk.BooleanVar(value=False)
        for var, label in [(self._outline_var, "Dodaj outline"),
                           (self._no_palette_var, "Pomin palete"),
                           (self._no_bg_var, "Pomin usuwanie tla")]:
            tk.Checkbutton(r2, text=label, variable=var,
                           bg=PANEL, fg=TEXT, selectcolor=BG,
                           activebackground=PANEL, font=FONT).pack(side="left", padx=(0, 14))

        # Buttons
        bf = tk.Frame(self.root, bg=BG); bf.pack(pady=8)
        tk.Button(bf, text="Dodaj pliki", bg=PANEL, fg=TEXT,
                  relief="flat", font=FONT_BOLD, padx=12, pady=6,
                  cursor="hand2", command=self._browse_files).pack(side="left", padx=6)
        self._process_btn = tk.Button(bf, text="PRZETWORZ",
                                      bg=ACCENT, fg=BTN_FG, relief="flat",
                                      font=FONT_BOLD, padx=20, pady=6,
                                      cursor="hand2", command=self._start_processing)
        self._process_btn.pack(side="left", padx=6)

        # Log
        lf2 = tk.Frame(self.root, bg=BG)
        lf2.pack(fill="both", expand=True, padx=16, pady=(0, 10))
        lh = tk.Frame(lf2, bg=BG); lh.pack(fill="x")
        tk.Label(lh, text="Log:", bg=BG, fg=TEXT, font=FONT_BOLD).pack(side="left")
        tk.Button(lh, text="Wyczysc log", bg=PANEL, fg=TEXT_DIM, relief="flat",
                  font=FONT_SM, command=lambda: self._log.delete("1.0", "end")).pack(side="right")
        self._log = scrolledtext.ScrolledText(
            lf2, bg=LOG_BG, fg=LOG_FG, insertbackground=LOG_FG,
            relief="flat", font=FONT_MONO, wrap="word", state="disabled")
        self._log.pack(fill="both", expand=True, pady=(4, 0))
        self._log.tag_config("ok",   foreground=SUCCESS)
        self._log.tag_config("warn", foreground=WARN)
        self._log.tag_config("err",  foreground=ERR)
        self._log.tag_config("hdr",  foreground=HDR)

    # ══════════════════════════════════════════════════════════════════════════
    # Shared logic
    # ══════════════════════════════════════════════════════════════════════════

    def _on_drop(self, event: "tk.Event") -> None:  # type: ignore[type-arg]
        paths: list[str] = self.root.tk.splitlist(event.data)  # type: ignore[attr-defined]
        added = 0
        for p in paths:
            path = Path(p)
            if path.suffix.lower() in (".jpg", ".jpeg", ".png") and path not in self._files:
                self._files.append(path)
                added += 1
        self._refresh_file_list()
        if added:
            self._log_write(f"  + Dodano {added} plik(ow) przez drag & drop\n", "ok")

    def _browse_files(self) -> None:
        paths = filedialog.askopenfilenames(
            title="Wybierz sprite'y",
            filetypes=[("Obrazy", "*.jpg *.jpeg *.png"), ("Wszystkie", "*.*")],
        )
        added = 0
        for p in paths:
            path = Path(p)
            if path not in self._files:
                self._files.append(path)
                added += 1
        self._refresh_file_list()
        if added:
            self._log_write(f"  + Dodano {added} plik(ow)\n", "ok")

    def _clear_files(self) -> None:
        self._files.clear()
        self._refresh_file_list()

    def _refresh_file_list(self) -> None:
        self._file_listbox.delete(0, "end")
        for p in self._files:
            self._file_listbox.insert("end", p.name)

    def _start_processing(self) -> None:
        if self._processing:
            return
        if not self._files:
            messagebox.showwarning("Brak plikow", "Dodaj najpierw pliki.")
            return
        self._processing = True
        self._process_btn.config(state="disabled", text="Przetwarzam...")
        threading.Thread(target=self._process_all, daemon=True).start()

    def _process_all(self) -> None:
        cat_choice = self._cat_var.get()
        category   = "" if cat_choice == "(auto-detect)" else cat_choice
        resize_raw = self._resize_var.get().strip()
        resize: tuple[int, int] = (0, 0)
        if resize_raw.lower() != "auto":
            try:
                resize = ps.parse_resize_arg(resize_raw)
            except (ValueError, IndexError):
                self._log_write(f"  Nieprawidlowy resize '{resize_raw}', uzywam auto.\n", "warn")

        ok = fail = 0
        self._log_write("\n" + "=" * 52 + "\n", "hdr")
        self._log_write(f"  Przetwarzam {len(self._files)} plik(ow)...\n", "hdr")
        self._log_write("=" * 52 + "\n", "hdr")

        old_stdout = sys.stdout
        sys.stdout = QueueStream(self._log_queue)  # type: ignore[assignment]
        try:
            for fp in self._files:
                self._log_write(f"\n> {fp.name}\n", "hdr")
                argv: list[str] = [str(fp)]
                if category:
                    argv += ["--category", category]
                if resize[0]:
                    argv += ["--resize", f"{resize[0]}x{resize[1]}"]
                if self._outline_var.get():
                    argv.append("--outline")
                if self._no_palette_var.get():
                    argv.append("--no-palette")
                if self._no_bg_var.get():
                    argv.append("--no-bg")
                try:
                    code = ps.main(argv)
                    if code == 0:
                        ok += 1
                        self._log_write("  OK\n", "ok")
                    else:
                        fail += 1
                        self._log_write(f"  BLAD (exit {code})\n", "err")
                except Exception as exc:
                    fail += 1
                    self._log_write(f"  WYJATEK: {exc}\n", "err")
        finally:
            sys.stdout = old_stdout

        self._log_write("\n" + "=" * 52 + "\n", "hdr")
        self._log_write(f"  Gotowe: {ok} OK  |  {fail} bledow\n",
                        "ok" if fail == 0 else "warn")
        self._log_write("=" * 52 + "\n", "hdr")
        self.root.after(0, self._done_processing)

    def _done_processing(self) -> None:
        self._processing = False
        btn_text = "▶  PRZETWÓRZ" if _MAC else "PRZETWORZ"
        self._process_btn.config(state="normal", text=btn_text)

    def _log_write(self, text: str, tag: str = "") -> None:
        self._log_queue.put(("__TAG__", tag, text))

    def _poll_log(self) -> None:
        while not self._log_queue.empty():
            item = self._log_queue.get_nowait()
            self._log.config(state="normal")
            if isinstance(item, tuple) and item[0] == "__TAG__":
                _, tag, text = item
                self._log.insert("end", text, tag if tag else ())
            else:
                self._log.insert("end", str(item))
            self._log.config(state="disabled")
            self._log.see("end")
        self.root.after(50, self._poll_log)

    def run(self) -> None:
        self._log_write("  WAR MEAT Sprite Processor gotowy.\n", "ok")
        if not _HAS_DND and not _MAC:
            self._log_write("  Drag & drop niedostepny: pip install tkinterdnd2\n", "warn")
        self.root.mainloop()


if __name__ == "__main__":
    App().run()
