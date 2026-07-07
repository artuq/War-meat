"""
WRZUC SPRITE — Web UI
Uruchamia lokalny serwer HTTP i otwiera przeglądarkę.
Działa na każdym Python 3.x, zero zależności od Tk/Qt.
"""
from __future__ import annotations

import cgi
import html
import io
import json
import os
import socket
import sys
import tempfile
import threading
import webbrowser
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent
REPO_ROOT = TOOLS_DIR.parent
sys.path.insert(0, str(TOOLS_DIR))

import process_sprite as ps

PORT = 8765

# ── HTML ──────────────────────────────────────────────────────────────────────

HTML = """<!DOCTYPE html>
<html lang="pl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>WRZUC SPRITE — War Meat Pipeline</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
         background: #1e1e2e; color: #e0e0e0; padding: 24px; }
  h1 { color: #ffd700; font-size: 1.4rem; margin-bottom: 4px; }
  p.sub { color: #888; font-size: .85rem; margin-bottom: 20px; }
  .card { background: #2a2a3e; border-radius: 8px; padding: 18px;
          margin-bottom: 16px; }
  .card h2 { font-size: .95rem; color: #4a9eff; margin-bottom: 12px;
             text-transform: uppercase; letter-spacing: .05em; }
  label { display: block; font-size: .88rem; color: #aaa; margin-bottom: 4px; }
  input[type=file] { width: 100%; padding: 10px;
                     background: #1e1e2e; border: 2px dashed #4a4a6e;
                     border-radius: 6px; color: #e0e0e0; cursor: pointer;
                     font-size: .9rem; }
  input[type=file]:hover { border-color: #4a9eff; }
  select, input[type=text] {
    background: #1e1e2e; border: 1px solid #4a4a6e; border-radius: 4px;
    color: #e0e0e0; padding: 6px 10px; font-size: .9rem; }
  select { width: 180px; } input[type=text] { width: 120px; }
  .row { display: flex; gap: 24px; flex-wrap: wrap; align-items: flex-end; }
  .field { display: flex; flex-direction: column; gap: 4px; }
  .checks { display: flex; gap: 20px; margin-top: 4px; }
  .checks label { display: flex; align-items: center; gap: 6px;
                  color: #e0e0e0; cursor: pointer; }
  .checks input[type=checkbox] { width: 15px; height: 15px; cursor: pointer; }
  button { background: #4a9eff; color: #000; border: none; border-radius: 6px;
           padding: 10px 28px; font-size: 1rem; font-weight: 700;
           cursor: pointer; margin-top: 8px; transition: background .15s; }
  button:hover { background: #6ab0ff; }
  button:disabled { background: #444; color: #777; cursor: not-allowed; }
  #log { background: #0d0d1a; border-radius: 6px; padding: 14px;
         font-family: "Menlo", "Consolas", monospace; font-size: .82rem;
         white-space: pre-wrap; min-height: 120px; max-height: 400px;
         overflow-y: auto; color: #ccc; }
  .ok   { color: #5a9e5a; } .warn { color: #e07020; }
  .err  { color: #cc4444; } .hdr  { color: #ffd700; }
  #status { font-size: .85rem; margin-top: 6px; color: #888; }
</style>
</head>
<body>
<h1>WRZUC SPRITE &mdash; War Meat Pipeline</h1>
<p class="sub">AI Studio JPG/PNG &rarr; game-ready PNG &bull; localhost only</p>

<form id="form" enctype="multipart/form-data">
  <div class="card">
    <h2>Pliki</h2>
    <label>Wybierz JPG/PNG (można zaznaczyd kilka)</label>
    <input type="file" name="files" multiple accept=".jpg,.jpeg,.png" required>
  </div>

  <div class="card">
    <h2>Opcje</h2>
    <div class="row">
      <div class="field">
        <label>Kategoria</label>
        <select name="category" id="cat" onchange="onCatChange()">
          <option value="">(auto-detect)</option>
          <option value="soldiers">soldiers — postacie (→ assets/sprites/soldiers/)</option>
          <option value="enemies">enemies — wrogowie (→ assets/sprites/enemies/)</option>
          <option value="weapons">weapons — bronie (→ assets/sprites/weapons/)</option>
          <option value="loot">loot — coin/crate/gem (→ assets/sprites/loot/)</option>
          <option value="fx">fx — efekty (→ assets/sprites/fx/)</option>
          <option value="cards">cards — karty UI (→ assets/sprites/ui/cards/shop/ lub upgrade/)</option>
        </select>
      </div>
      <div class="field">
        <label>Resize</label>
        <input type="text" name="resize" id="resize" value="auto"
               placeholder="auto / 128 / 96x32 / 192x256">
      </div>
    </div>
    <div id="hint" style="margin-top:10px; font-size:.82rem; color:#888; min-height:18px;"></div>
    <div class="checks" style="margin-top:14px;">
      <label><input type="checkbox" name="no_palette" id="no_palette"> Pomiń paletę</label>
      <label><input type="checkbox" name="no_bg"> Pomiń usuwanie tła</label>
      <label><input type="checkbox" name="outline"> Dodaj outline</label>
    </div>
  </div>

  <button type="submit" id="btn">&#9654; PRZETWÓRZ</button>
  <div id="status"></div>
</form>

<div class="card" style="margin-top:16px;">
  <h2>Log</h2>
  <div id="log">Gotowy. Wybierz pliki i kliknij PRZETWÓRZ.</div>
</div>

<script>
const HINTS = {
  "": "Auto-detect z nazwy pliku.",
  "soldiers": "Resize: 128×128 px. Paleta WAR MEAT. Tło białe usuwane.",
  "enemies": "Resize: auto (Grunt=80, Rusher=64, Tank=112, Boss=192). Paleta WAR MEAT.",
  "weapons": "Resize: ręcznie (np. 128x64 dla rifle, 80x56 pistol). Paleta WAR MEAT.",
  "loot": "Resize: 48×48 px. Paleta WAR MEAT.",
  "fx": "Resize: 64×64 px. Paleta WAR MEAT.",
  "cards": "Resize: 192×256 px (auto). Paleta WYŁĄCZONA. → ui/cards/shop/ lub upgrade/ (z nazwy pliku).",
};
function onCatChange() {
  const cat = document.getElementById("cat").value;
  document.getElementById("hint").textContent = HINTS[cat] || "";
  if (cat === "cards") {
    document.getElementById("resize").value = "192x256";
    document.getElementById("no_palette").checked = true;
  } else if (cat !== "") {
    document.getElementById("resize").value = "auto";
    document.getElementById("no_palette").checked = false;
  }
}

document.getElementById("form").addEventListener("submit", function(e) {
  e.preventDefault();
  const btn = document.getElementById("btn");
  const log = document.getElementById("log");
  btn.disabled = true;
  btn.textContent = "Przetwarzam...";
  log.textContent = "";

  const fd = new FormData(e.target);
  const xhr = new XMLHttpRequest();
  xhr.open("POST", "/process", true);
  xhr.onload = function() {
    const lines = xhr.responseText.split("\\n");
    log.textContent = "";
    for (const line of lines) {
      const span = document.createElement("span");
      if (line.startsWith("  OK") || line.includes("Saved"))
        span.className = "ok";
      else if (line.includes("WARNING") || line.includes("blad") || line.includes("bledow"))
        span.className = "warn";
      else if (line.includes("BLAD") || line.includes("ERROR"))
        span.className = "err";
      else if (line.startsWith("===") || line.startsWith(">>>"))
        span.className = "hdr";
      span.textContent = line + "\\n";
      log.appendChild(span);
    }
    log.scrollTop = log.scrollHeight;
    btn.disabled = false;
    btn.textContent = "▶ PRZETWÓRZ";
  };
  xhr.onerror = function() {
    log.textContent = "Blad polaczenia XHR. Sprawdz czy serwer dziala na http://127.0.0.1:8765";
    btn.disabled = false;
    btn.textContent = "▶ PRZETWÓRZ";
  };
  xhr.send(fd);
});
</script>
</body>
</html>
"""


# ── HTTP handler ──────────────────────────────────────────────────────────────

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_: object) -> None:
        pass  # silent

    def do_GET(self) -> None:
        body = HTML.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:
        ctype, pdict = cgi.parse_header(self.headers.get("Content-Type", ""))
        if ctype != "multipart/form-data":
            self.send_response(400); self.end_headers(); return

        pdict["boundary"] = pdict["boundary"].encode()
        pdict["CONTENT-LENGTH"] = int(self.headers.get("Content-Length", 0))
        form = cgi.parse_multipart(self.rfile, pdict)

        category    = (form.get("category", [""])[0] or "").strip()
        resize_raw  = (form.get("resize",   ["auto"])[0] or "auto").strip()
        no_palette  = "no_palette" in form
        no_bg       = "no_bg"      in form
        add_outline = "outline"    in form
        file_items  = form.get("files", [])

        out = io.StringIO()
        old_stdout = sys.stdout
        sys.stdout = out

        ok = fail = 0
        for item in file_items:
            # item is bytes from multipart
            if not isinstance(item, bytes):
                continue
            # We need the filename — parse from the form headers isn't
            # straightforward with cgi.parse_multipart; use a temp file.
            suffix = ".png"
            with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
                tmp.write(item)
                tmp_path = Path(tmp.name)

            print(f"\n>>> {tmp_path.name}")
            argv: list[str] = [str(tmp_path)]
            if category:
                argv += ["--category", category]
            if resize_raw.lower() != "auto":
                argv += ["--resize", resize_raw]
            if no_palette:
                argv.append("--no-palette")
            if no_bg:
                argv.append("--no-bg")
            if add_outline:
                argv.append("--outline")

            try:
                code = ps.main(argv)
                if code == 0:
                    ok += 1
                else:
                    fail += 1
            except Exception as exc:
                print(f"  BLAD: {exc}")
                fail += 1
            finally:
                tmp_path.unlink(missing_ok=True)

        sys.stdout = old_stdout
        print(f"\n{'='*50}", file=out)
        print(f"  Gotowe: {ok} OK  |  {fail} bledow", file=out)
        print(f"{'='*50}", file=out)

        body = out.getvalue().encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)


# ── Problem: cgi.parse_multipart doesn't give us filenames.
# Rewrite POST to use email.parser for proper multipart handling.
# ─────────────────────────────────────────────────────────────

class Handler(BaseHTTPRequestHandler):  # type: ignore[no-redef]
    def log_message(self, *_: object) -> None:
        pass

    def do_GET(self) -> None:
        body = HTML.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:
        from email import message_from_bytes
        from email.policy import HTTP as HTTP_POLICY

        content_type = self.headers.get("Content-Type", "")
        content_len  = int(self.headers.get("Content-Length", 0))
        raw_body     = self.rfile.read(content_len)

        # Build a fake email message so email.parser can parse multipart
        fake_msg = b"Content-Type: " + content_type.encode() + b"\r\n\r\n" + raw_body
        msg = message_from_bytes(fake_msg)

        fields: dict[str, list[str]]  = {}
        files:  list[tuple[str, bytes]] = []  # (filename, data)

        if msg.is_multipart():
            for part in msg.get_payload():  # type: ignore[union-attr]
                disp   = str(part.get("Content-Disposition", ""))
                _, params = cgi.parse_header(disp)
                name     = params.get("name", "")
                filename = params.get("filename", "")
                data     = part.get_payload(decode=True) or b""
                if filename:
                    files.append((filename, data))
                else:
                    fields.setdefault(name, []).append(data.decode(errors="replace"))

        category    = (fields.get("category",  [""])[0]    or "").strip()
        resize_raw  = (fields.get("resize",    ["auto"])[0] or "auto").strip()
        no_palette  = "no_palette" in fields
        no_bg       = "no_bg"      in fields
        add_outline = "outline"    in fields

        out = io.StringIO()
        old_stdout = sys.stdout
        sys.stdout = out

        ok = fail = 0
        for filename, data in files:
            # Use a dedicated temp dir so the file keeps its original name.
            # process_sprite.py derives the output name from the input stem,
            # so "Assault.jpg" → "Assault.png" (not "Assault_randomchars.png").
            tmp_dir = Path(tempfile.mkdtemp())
            tmp_path = tmp_dir / filename
            tmp_path.write_bytes(data)

            print(f"\n>>> {filename}")
            argv: list[str] = [str(tmp_path)]
            if category:
                argv += ["--category", category]
            if resize_raw.lower() != "auto":
                argv += ["--resize", resize_raw]
            if no_palette:
                argv.append("--no-palette")
            if no_bg:
                argv.append("--no-bg")
            if add_outline:
                argv.append("--outline")

            try:
                code = ps.main(argv)
                ok += 1 if code == 0 else 0
                if code != 0:
                    fail += 1
            except Exception as exc:
                print(f"  BLAD: {exc}")
                fail += 1
            finally:
                import shutil
                shutil.rmtree(tmp_dir, ignore_errors=True)

        sys.stdout = old_stdout
        print(f"\n{'='*50}", file=out)
        print(f"  Gotowe: {ok} OK  |  {fail} bledow", file=out)
        print(f"{'='*50}", file=out)

        body = out.getvalue().encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)


# ── Main ──────────────────────────────────────────────────────────────────────

class DualStackServer(HTTPServer):
    """Accepts both IPv4 (127.0.0.1) and IPv6 (::1) — fixes Safari localhost XHR."""
    address_family = socket.AF_INET6

    def server_bind(self) -> None:
        self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
        super().server_bind()


def main() -> None:
    try:
        server: HTTPServer = DualStackServer(("::", PORT), Handler)
    except OSError:
        server = HTTPServer(("0.0.0.0", PORT), Handler)

    print(f"\n{'='*50}")
    print(f"  WAR MEAT — WRZUC SPRITE  (web UI)")
    print(f"{'='*50}")
    print(f"  Serwer: http://localhost:{PORT}")
    print(f"  Ctrl+C aby zatrzymac")
    print(f"{'='*50}\n")

    # Open browser after short delay (server needs to start first)
    def _open() -> None:
        import time; time.sleep(0.4)
        webbrowser.open(f"http://localhost:{PORT}")
    threading.Thread(target=_open, daemon=True).start()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nZatrzymano.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
