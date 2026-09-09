#!/usr/bin/env python3
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
import os

HOST = "127.0.0.1"
PORT = 8000
ROOT = Path(__file__).resolve().parent
UNLOCK = datetime(2026, 9, 10, 0, 0, 0, tzinfo=ZoneInfo("Asia/Jakarta"))

LOCKED_HTML = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Not yet.</title>
<style>
body{margin:0;min-height:100vh;display:grid;place-items:center;background:#141312;color:#faf7f0;font-family:Georgia,serif;text-align:center}
.wrap{padding:24px}
.k{font:10px monospace;letter-spacing:.25em;text-transform:uppercase;color:#9c948d}
h1{font-size:clamp(70px,15vw,150px);font-weight:400;line-height:.78;margin:26px 0}
p{font-size:18px;line-height:1.6;color:#c8c0b8}
</style>
</head>
<body><div class="wrap">
<div class="k">A PRIVATE EDITION · 10 SEPTEMBER 2026</div>
<h1>Not<br>yet.</h1>
<p>This page is sealed until the birthday begins.</p>
</div></body>
</html>"""

class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_GET(self):
        now = datetime.now(ZoneInfo("Asia/Jakarta"))
        path = self.path.split("?", 1)[0]
        if now < UNLOCK and (path == "/" or path in ("/index.html", "")):
            body = LOCKED_HTML.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        return super().do_GET()

if __name__ == "__main__":
    os.chdir(ROOT)
    print(f"Sasya birthday site: http://{HOST}:{PORT}")
    print(f"Unlock: {UNLOCK.isoformat()}")
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
