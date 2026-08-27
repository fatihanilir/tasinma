#!/usr/bin/env python3
"""Ev kayıtlarını homes.json dosyasına yazar. Tarayıcı kapansa da silinmez."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import json
import os

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "homes.json"
PORT = int(os.environ.get("PORT", "8765"))


def read_homes():
    if not DATA.exists():
        return []
    try:
        data = json.loads(DATA.read_text(encoding="utf-8"))
        return data if isinstance(data, list) else []
    except json.JSONDecodeError:
        return []


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def log_message(self, fmt, *args):
        print("[%s] " % self.log_date_time_string() + (fmt % args))

    def _send_json(self, payload, status=200):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/api/homes":
            self._send_json(read_homes())
            return
        super().do_GET()

    def do_PUT(self):
        path = self.path.split("?", 1)[0]
        if path != "/api/homes":
            self.send_error(404)
            return
        length = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(length)
        try:
            data = json.loads(raw.decode("utf-8"))
        except json.JSONDecodeError:
            self._send_json({"ok": False, "error": "json"}, 400)
            return
        if not isinstance(data, list):
            self._send_json({"ok": False, "error": "list"}, 400)
            return
        DATA.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        self._send_json({"ok": True})


if __name__ == "__main__":
    if not DATA.exists():
        DATA.write_text("[]", encoding="utf-8")
    httpd = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print(f"Hazır: http://127.0.0.1:{PORT}/")
    print("Kayıtlar bu dosyada: " + str(DATA))
    print("Durdurmak için Ctrl+C")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nDurdu.")
