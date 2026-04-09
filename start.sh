#!/bin/bash

echo "=========================================="
echo "  Starting Alpine VNC Desktop on Render"
echo "=========================================="

# 清理残留
rm -rf /tmp/.X0-lock /tmp/.X11-unix 2>/dev/null
mkdir -p /tmp/.X11-unix /run/dbus
chmod 1777 /tmp/.X11-unix

# 启动 dbus（Chrome 需要）
dbus-daemon --system --fork 2>/dev/null || true

echo "Starting Xvfb..."
Xvfb :0 -screen 0 ${RESOLUTION}x24 -ac &
sleep 3

export DISPLAY=:0

echo "Starting Fluxbox..."
fluxbox -display :0 2>/dev/null &
sleep 2

echo "Starting Chromium (Incognito Mode)..."
chromium-browser \
    --display=:0 \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --incognito \
    --no-first-run \
    --user-data-dir=/tmp/chrome \
    https://www.google.com 2>/dev/null &

sleep 3

echo "Starting x11vnc..."
x11vnc -display :0 -forever -passwd ${PASSWORD} -shared -rfbport 5900 2>/dev/null &
sleep 2

echo "Starting noVNC..."
cd /app/novnc
websockify --web /app/novnc 0.0.0.0:8080 localhost:5900 &

echo "=========================================="
echo "  ✅ VNC Desktop Ready!"
echo "  🔑 Password: ${PASSWORD}"
echo "  📍 Port: 8080"
echo "  🌐 https://alpine-vnc.onrender.com/vnc.html?path=websockify"
echo "=========================================="

# 保持运行
while true; do
    sleep 300
done
