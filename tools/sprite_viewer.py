#!/usr/bin/env python3
"""
WAR MEAT Sprite Viewer — preview & animate sprite sheets.

Usage:
    python sprite_viewer.py [sprite_sheet.png] [--size 32]

Features:
    - Loads sprite sheets and splits into grid of frames
    - Plays animation with adjustable FPS (1-30)
    - Direction switching (N/E/S/W) for 4-row character sheets
    - Animation type switching (IDLE/WALK/SHOOT/DEATH/HIT)
    - Frame comparison strip with click-to-jump
    - 8× zoom with checkerboard transparency background
    - Keyboard shortcuts: Space, Left/Right, 1-4, Q/W/E/R/T
"""

import argparse
import sys
import tkinter as tk
from pathlib import Path
from tkinter import filedialog

from PIL import Image, ImageTk

# ─── Constants ───────────────────────────────────────────────────────────────

DEFAULT_CELL = 32
ZOOM_MAIN = 8          # 32 → 256
ZOOM_STRIP = 3         # 32 → 96
DEFAULT_FPS = 8
CHECKER_SIZE = 8       # pixels in checkerboard tile (at zoom scale)
CHECKER_LIGHT = "#3c3c3c"
CHECKER_DARK = "#2c2c2c"

# Standard WAR MEAT animation layout (4 direction rows)
DIRECTIONS = ["NORTH", "EAST", "SOUTH", "WEST"]
ANIM_DEFS = {
    # name: (start_col, frame_count)
    "IDLE":  (0, 4),
    "WALK":  (4, 4),
    "SHOOT": (8, 3),
    "DEATH": (11, 5),
    "HIT":   (16, 2),
}
ANIM_ORDER = ["IDLE", "WALK", "SHOOT", "DEATH", "HIT"]


# ─── Sheet Parser ────────────────────────────────────────────────────────────

class SheetParser:
    """Parse a sprite sheet PNG into a grid of PIL Image frames."""

    def __init__(self, path: str, cell_size: int = DEFAULT_CELL):
        self.path = Path(path)
        self.cell_size = cell_size
        self.sheet = Image.open(self.path).convert("RGBA")
        self.sheet_w, self.sheet_h = self.sheet.size
        self.cols = self.sheet_w // cell_size
        self.rows = self.sheet_h // cell_size
        self._cache: dict[tuple[int, int], Image.Image] = {}

    def frame(self, row: int, col: int) -> Image.Image | None:
        """Get frame at grid position. Returns None if out of bounds."""
        if row < 0 or row >= self.rows or col < 0 or col >= self.cols:
            return None
        key = (row, col)
        if key not in self._cache:
            x = col * self.cell_size
            y = row * self.cell_size
            self._cache[key] = self.sheet.crop(
                (x, y, x + self.cell_size, y + self.cell_size)
            )
        return self._cache[key]

    @property
    def is_full_character(self) -> bool:
        """Detect if this is a full 4-direction character sheet."""
        return self.rows >= 4 and self.cols >= 4

    @property
    def total_cols(self) -> int:
        return self.cols

    @property
    def total_rows(self) -> int:
        return self.rows


# ─── Checkerboard helper ─────────────────────────────────────────────────────

def make_checkerboard(width: int, height: int, tile: int = CHECKER_SIZE) -> Image.Image:
    """Create a checkerboard RGBA image for transparency display."""
    img = Image.new("RGBA", (width, height))
    pixels = img.load()
    light = (0x3C, 0x3C, 0x3C, 255)
    dark = (0x2C, 0x2C, 0x2C, 255)
    for y in range(height):
        for x in range(width):
            if ((x // tile) + (y // tile)) % 2 == 0:
                pixels[x, y] = light
            else:
                pixels[x, y] = dark
    return img


# ─── Main Application ────────────────────────────────────────────────────────

class SpriteViewer:
    def __init__(self, root: tk.Tk, sheet_path: str | None = None, cell_size: int = DEFAULT_CELL):
        self.root = root
        self.root.title("WAR MEAT Sprite Viewer")
        self.root.configure(bg="#1e1e1e")
        self.root.resizable(True, True)

        self.cell_size = cell_size
        self.parser: SheetParser | None = None

        # Animation state
        self.current_row = 0
        self.current_anim = "IDLE"
        self.current_frame_idx = 0
        self.playing = False
        self.fps = DEFAULT_FPS
        self._after_id: str | None = None

        # Tk variables
        self.var_direction = tk.IntVar(value=0)
        self.var_anim = tk.StringVar(value="IDLE")

        # Pre-compute checkerboards
        main_px = cell_size * ZOOM_MAIN
        strip_px = cell_size * ZOOM_STRIP
        self._checker_main = make_checkerboard(main_px, main_px)
        self._checker_strip = make_checkerboard(strip_px, strip_px)

        # PhotoImage refs (prevent GC)
        self._main_photo: ImageTk.PhotoImage | None = None
        self._strip_photos: list[ImageTk.PhotoImage] = []

        self._build_ui()
        self._bind_keys()

        if sheet_path:
            self._load_sheet(sheet_path)

    # ─── UI Construction ──────────────────────────────────────────────────

    def _build_ui(self):
        # Colors
        bg = "#1e1e1e"
        fg = "#e0e0e0"
        accent = "#4a9eff"
        panel_bg = "#252526"
        btn_bg = "#333333"

        # ── Top bar ──────────────────────────────────────────────────────
        top = tk.Frame(self.root, bg=panel_bg, pady=4, padx=8)
        top.pack(fill=tk.X)

        tk.Label(top, text="WAR MEAT Sprite Viewer", font=("Consolas", 11, "bold"),
                 bg=panel_bg, fg=accent).pack(side=tk.LEFT)

        tk.Button(top, text="Otwórz plik...", command=self._open_file,
                  bg=btn_bg, fg=fg, relief=tk.FLAT, padx=10,
                  activebackground="#555", activeforeground=fg).pack(side=tk.RIGHT)

        # ── Main area: left panel + right canvas ─────────────────────────
        main_area = tk.Frame(self.root, bg=bg)
        main_area.pack(fill=tk.BOTH, expand=True)

        # Left control panel
        left = tk.Frame(main_area, bg=panel_bg, width=160, padx=10, pady=10)
        left.pack(side=tk.LEFT, fill=tk.Y)
        left.pack_propagate(False)

        # Direction section
        tk.Label(left, text="KIERUNEK", font=("Consolas", 9, "bold"),
                 bg=panel_bg, fg=accent).pack(anchor=tk.W, pady=(0, 4))

        self._dir_radios = []
        for i, d in enumerate(DIRECTIONS):
            rb = tk.Radiobutton(
                left, text=d, variable=self.var_direction, value=i,
                command=self._on_direction_change,
                bg=panel_bg, fg=fg, selectcolor=btn_bg,
                activebackground=panel_bg, activeforeground=fg,
                font=("Consolas", 9), indicatoron=True
            )
            rb.pack(anchor=tk.W)
            self._dir_radios.append(rb)

        tk.Frame(left, bg="#444", height=1).pack(fill=tk.X, pady=8)

        # Animation type section
        tk.Label(left, text="ANIMACJA", font=("Consolas", 9, "bold"),
                 bg=panel_bg, fg=accent).pack(anchor=tk.W, pady=(0, 4))

        self._anim_radios = []
        for name in ANIM_ORDER:
            start, count = ANIM_DEFS[name]
            label = f"{name} ({count}f)"
            rb = tk.Radiobutton(
                left, text=label, variable=self.var_anim, value=name,
                command=self._on_anim_change,
                bg=panel_bg, fg=fg, selectcolor=btn_bg,
                activebackground=panel_bg, activeforeground=fg,
                font=("Consolas", 9), indicatoron=True
            )
            rb.pack(anchor=tk.W)
            self._anim_radios.append(rb)

        tk.Frame(left, bg="#444", height=1).pack(fill=tk.X, pady=8)

        # FPS slider
        tk.Label(left, text="FPS", font=("Consolas", 9, "bold"),
                 bg=panel_bg, fg=accent).pack(anchor=tk.W, pady=(0, 2))

        self.fps_label = tk.Label(left, text=f"{self.fps}", font=("Consolas", 9),
                                  bg=panel_bg, fg=fg)
        self.fps_label.pack(anchor=tk.W)

        self.fps_slider = tk.Scale(
            left, from_=1, to=30, orient=tk.HORIZONTAL,
            variable=tk.IntVar(value=self.fps),
            command=self._on_fps_change,
            bg=panel_bg, fg=fg, troughcolor=btn_bg,
            highlightthickness=0, length=130, sliderlength=15
        )
        self.fps_slider.set(self.fps)
        self.fps_slider.pack(anchor=tk.W, pady=(0, 8))

        # Play/Pause button
        self.btn_play = tk.Button(
            left, text="▶  Play", command=self._toggle_play,
            bg="#2d5a1e", fg=fg, relief=tk.FLAT, padx=10, pady=4,
            font=("Consolas", 10, "bold"),
            activebackground="#3d7a2e", activeforeground=fg, width=12
        )
        self.btn_play.pack(pady=(4, 0))

        # Frame counter
        self.frame_label = tk.Label(left, text="Frame: -/-", font=("Consolas", 9),
                                    bg=panel_bg, fg="#888")
        self.frame_label.pack(anchor=tk.W, pady=(8, 0))

        # ── Right side: main canvas + frame strip ────────────────────────
        right = tk.Frame(main_area, bg=bg)
        right.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        # Main canvas
        canvas_size = self.cell_size * ZOOM_MAIN
        self.canvas = tk.Canvas(
            right, width=canvas_size, height=canvas_size,
            bg="#1a1a1a", highlightthickness=1, highlightbackground="#444"
        )
        self.canvas.pack(padx=10, pady=10)

        # ── Frame strip ──────────────────────────────────────────────────
        strip_frame = tk.Frame(right, bg=panel_bg, pady=6, padx=6)
        strip_frame.pack(fill=tk.X, padx=10, pady=(0, 6))

        tk.Label(strip_frame, text="KLATKI", font=("Consolas", 8, "bold"),
                 bg=panel_bg, fg="#888").pack(anchor=tk.W)

        self.strip_canvas = tk.Canvas(
            strip_frame, height=self.cell_size * ZOOM_STRIP + 12,
            bg=panel_bg, highlightthickness=0
        )
        self.strip_canvas.pack(fill=tk.X)
        self.strip_canvas.bind("<Button-1>", self._on_strip_click)

        # ── Status bar ───────────────────────────────────────────────────
        self.status = tk.Label(
            self.root, text="Brak pliku — kliknij 'Otwórz plik...' lub przeciągnij na podglad.bat",
            font=("Consolas", 9), bg="#007acc", fg="#fff", anchor=tk.W, padx=8, pady=2
        )
        self.status.pack(fill=tk.X, side=tk.BOTTOM)

    # ─── Key Bindings ─────────────────────────────────────────────────────

    def _bind_keys(self):
        self.root.bind("<space>", lambda e: self._toggle_play())
        self.root.bind("<Left>", lambda e: self._step_frame(-1))
        self.root.bind("<Right>", lambda e: self._step_frame(1))

        # Direction: 1-4
        for i in range(4):
            self.root.bind(str(i + 1), lambda e, idx=i: self._set_direction(idx))

        # Animation: Q W E R T
        keys = ["q", "w", "e", "r", "t"]
        for i, k in enumerate(keys):
            if i < len(ANIM_ORDER):
                self.root.bind(k, lambda e, name=ANIM_ORDER[i]: self._set_anim(name))

    # ─── File Loading ─────────────────────────────────────────────────────

    def _open_file(self):
        path = filedialog.askopenfilename(
            title="Wybierz sprite sheet",
            filetypes=[("PNG files", "*.png"), ("All files", "*.*")]
        )
        if path:
            self._load_sheet(path)

    def _load_sheet(self, path: str):
        try:
            self.parser = SheetParser(path, self.cell_size)
        except Exception as ex:
            self.status.config(text=f"BŁĄD: {ex}")
            return

        p = self.parser
        self.current_frame_idx = 0
        self.current_row = 0
        self.var_direction.set(0)

        # Determine mode
        if p.is_full_character:
            self.current_anim = "IDLE"
            self.var_anim.set("IDLE")
            self._set_controls_enabled(True)
            mode = "4-kierunkowy"
        else:
            self.current_anim = "__SIMPLE__"
            self._set_controls_enabled(False)
            mode = "prosty"

        self.status.config(
            text=f"{p.path.name}  |  {p.cols}×{p.rows} siatka  |  "
                 f"{p.cols * p.rows} klatek  |  {self.cell_size}px  |  tryb: {mode}"
        )

        self._update_display()
        self._update_strip()

    def _set_controls_enabled(self, character_mode: bool):
        """Enable/disable direction and animation controls based on sheet type."""
        state = tk.NORMAL if character_mode else tk.DISABLED
        for rb in self._dir_radios:
            rb.config(state=state)
        for rb in self._anim_radios:
            rb.config(state=state)

    # ─── Animation Logic ──────────────────────────────────────────────────

    def _get_frame_range(self) -> tuple[int, int]:
        """Return (start_col, frame_count) for current animation."""
        if not self.parser:
            return (0, 0)

        if self.current_anim == "__SIMPLE__":
            return (0, self.parser.cols)

        start, count = ANIM_DEFS.get(self.current_anim, (0, 4))
        # Clamp to actual sheet size
        available = max(0, self.parser.cols - start)
        count = min(count, available)
        return (start, count)

    def _get_current_frame(self) -> Image.Image | None:
        if not self.parser:
            return None
        start, count = self._get_frame_range()
        if count == 0:
            return None
        col = start + (self.current_frame_idx % count)
        return self.parser.frame(self.current_row, col)

    def _toggle_play(self):
        if self.playing:
            self._stop()
        else:
            self._play()

    def _play(self):
        self.playing = True
        self.btn_play.config(text="⏸  Pause", bg="#5a2d1e")
        self._tick()

    def _stop(self):
        self.playing = False
        self.btn_play.config(text="▶  Play", bg="#2d5a1e")
        if self._after_id:
            self.root.after_cancel(self._after_id)
            self._after_id = None

    def _tick(self):
        if not self.playing:
            return
        _, count = self._get_frame_range()
        if count > 0:
            self.current_frame_idx = (self.current_frame_idx + 1) % count
            self._update_display()
            self._update_strip_highlight()
        delay = max(16, 1000 // self.fps)
        self._after_id = self.root.after(delay, self._tick)

    def _step_frame(self, delta: int):
        """Step forward/backward by delta frames."""
        _, count = self._get_frame_range()
        if count == 0:
            return
        self._stop()
        self.current_frame_idx = (self.current_frame_idx + delta) % count
        self._update_display()
        self._update_strip_highlight()

    # ─── Control Callbacks ────────────────────────────────────────────────

    def _on_direction_change(self):
        self.current_row = self.var_direction.get()
        self.current_frame_idx = 0
        self._update_display()
        self._update_strip()

    def _on_anim_change(self):
        self.current_anim = self.var_anim.get()
        self.current_frame_idx = 0
        self._update_display()
        self._update_strip()

    def _set_direction(self, idx: int):
        if not self.parser or not self.parser.is_full_character:
            return
        self.var_direction.set(idx)
        self._on_direction_change()

    def _set_anim(self, name: str):
        if not self.parser or not self.parser.is_full_character:
            return
        self.var_anim.set(name)
        self._on_anim_change()

    def _on_fps_change(self, val):
        self.fps = int(val)
        self.fps_label.config(text=f"{self.fps}")

    # ─── Display Updates ──────────────────────────────────────────────────

    def _update_display(self):
        """Update the main canvas with current frame."""
        frame = self._get_current_frame()
        if frame is None:
            self.canvas.delete("all")
            self._main_photo = None
            self.frame_label.config(text="Frame: -/-")
            return

        _, count = self._get_frame_range()
        self.frame_label.config(text=f"Frame: {self.current_frame_idx + 1}/{count}")

        # Composite: checkerboard + frame, then zoom
        size = self.cell_size * ZOOM_MAIN
        bg = self._checker_main.copy()
        frame_zoomed = frame.resize((size, size), Image.NEAREST)
        bg.paste(frame_zoomed, (0, 0), frame_zoomed)

        self._main_photo = ImageTk.PhotoImage(bg)
        self.canvas.delete("all")
        self.canvas.create_image(0, 0, anchor=tk.NW, image=self._main_photo)

    def _update_strip(self):
        """Rebuild the entire frame strip."""
        self.strip_canvas.delete("all")
        self._strip_photos.clear()

        if not self.parser:
            return

        start, count = self._get_frame_range()
        if count == 0:
            return

        strip_px = self.cell_size * ZOOM_STRIP
        pad = 4
        total_w = count * (strip_px + pad) + pad
        self.strip_canvas.config(scrollregion=(0, 0, total_w, strip_px + 12))

        for i in range(count):
            col = start + i
            frame = self.parser.frame(self.current_row, col)
            if frame is None:
                continue

            bg = self._checker_strip.copy()
            frame_z = frame.resize((strip_px, strip_px), Image.NEAREST)
            bg.paste(frame_z, (0, 0), frame_z)

            photo = ImageTk.PhotoImage(bg)
            self._strip_photos.append(photo)

            x = pad + i * (strip_px + pad)
            y = 6
            self.strip_canvas.create_image(x, y, anchor=tk.NW, image=photo, tags=f"frame_{i}")

            # Frame number label
            self.strip_canvas.create_text(
                x + strip_px // 2, y + strip_px + 2,
                text=str(i + 1), fill="#888", font=("Consolas", 8), anchor=tk.N
            )

        self._update_strip_highlight()

    def _update_strip_highlight(self):
        """Update which frame in strip is highlighted."""
        self.strip_canvas.delete("highlight")
        _, count = self._get_frame_range()
        if count == 0:
            return

        strip_px = self.cell_size * ZOOM_STRIP
        pad = 4
        idx = self.current_frame_idx % count
        x = pad + idx * (strip_px + pad)
        y = 6
        self.strip_canvas.create_rectangle(
            x - 2, y - 2, x + strip_px + 2, y + strip_px + 2,
            outline="#4a9eff", width=2, tags="highlight"
        )

    def _on_strip_click(self, event):
        """Click on a frame in the strip to jump to it."""
        if not self.parser:
            return
        _, count = self._get_frame_range()
        if count == 0:
            return

        strip_px = self.cell_size * ZOOM_STRIP
        pad = 4
        # Calculate which frame was clicked
        idx = (event.x - pad) // (strip_px + pad)
        if 0 <= idx < count:
            self._stop()
            self.current_frame_idx = idx
            self._update_display()
            self._update_strip_highlight()


# ─── Entry Point ──────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser(description="WAR MEAT Sprite Viewer")
    p.add_argument("input", nargs="?", default=None, help="Sprite sheet PNG file")
    p.add_argument("--size", type=int, default=DEFAULT_CELL, help=f"Cell size in pixels (default: {DEFAULT_CELL})")
    args = p.parse_args()

    root = tk.Tk()
    root.geometry("560x500")
    root.minsize(480, 400)

    app = SpriteViewer(root, sheet_path=args.input, cell_size=args.size)
    root.mainloop()


if __name__ == "__main__":
    main()
