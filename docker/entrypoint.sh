#!/bin/bash
set -euo pipefail

export DISPLAY=:1
export WINEPREFIX=/root/.wine
export PYTHONUNBUFFERED=1

mkdir -p "$WINEPREFIX"
chown -R root:root "$WINEPREFIX" || true

# start X stack
Xvfb :1 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset >/tmp/xvfb.log 2>&1 &
fluxbox >/tmp/fluxbox.log 2>&1 &
x11vnc -display :1 -forever -shared -rfbport 5900 -nopw >/tmp/x11vnc.log 2>&1 &
websockify --web=/usr/share/novnc 8080 localhost:5900 >/tmp/websockify.log 2>&1 &

sleep 2

# run MT5 (installed terminal if exists, otherwise installer)
TERMINAL_EXE="$(find "$WINEPREFIX/drive_c" -type f -iname terminal64.exe 2>/dev/null | head -n1 || true)"
if [[ -n "${TERMINAL_EXE}" ]]; then
  wine "$TERMINAL_EXE" >/tmp/mt5.log 2>&1 &
else
  wine /app/mt5setup.exe >/tmp/mt5-install.log 2>&1 &
fi

# start FastAPI in foreground (keeps container alive + logs visible)
exec uvicorn main:app --host 0.0.0.0 --port 8000 --app-dir /app
