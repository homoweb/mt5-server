#!/bin/bash
set -euo pipefail

Xvfb :1 -screen 0 1920x1080x24 &
sleep 2
fluxbox &
x11vnc -display :1 -forever -shared -nopw -rfbport 5900 &
websockify --web=/usr/share/novnc/ 8080 localhost:5900 &

export DISPLAY=:1
export WINEPREFIX="${WINEPREFIX:-/root/.wine}"

mkdir -p "$WINEPREFIX"

CUR_UID="$(id -u)"
CUR_GID="$(id -g)"
OWN_UID="$(stat -c %u "$WINEPREFIX" 2>/dev/null || echo "$CUR_UID")"
OWN_GID="$(stat -c %g "$WINEPREFIX" 2>/dev/null || echo "$CUR_GID")"

if [ "$CUR_UID" != "$OWN_UID" ] || [ "$CUR_GID" != "$OWN_GID" ]; then
  chown -R "$CUR_UID:$CUR_GID" "$WINEPREFIX"
fi
chmod 700 "$WINEPREFIX" || true

MT5_BIN="$(find "$WINEPREFIX/drive_c" -iname "terminal64.exe" 2>/dev/null | head -n 1 || true)"

if [ -z "$MT5_BIN" ]; then
  echo "[INFO] MT5 not found. Launching installer..."
  wineboot -i || true
  # interactive installer via VNC
  wine /app/mt5setup.exe || true
  sleep 3
  MT5_BIN="$(find "$WINEPREFIX/drive_c" -iname "terminal64.exe" 2>/dev/null | head -n 1 || true)"
fi

if [ -n "$MT5_BIN" ]; then
  echo "[INFO] Starting MT5: $MT5_BIN"
  wine "$MT5_BIN" &
else
  echo "[WARN] terminal64.exe not found after installer."
fi

cd /app
exec uvicorn main:app --host 0.0.0.0 --port 8000
