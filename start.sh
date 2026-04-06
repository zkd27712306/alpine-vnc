#!/bin/bash

echo "=========================================="
echo "  Starting Alpine VNC Desktop on Render"
echo "=========================================="

# 创建必要的目录
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# 清理旧文件
rm -rf /tmp/.X0-lock 2>/dev/null

echo "Starting Xvfb..."
Xvfb :0 -screen 0 1280x720x24 -ac &
sleep 3

export DISPLAY=:0

echo "Starting Fluxbox..."
fluxbox -display :0 2>/dev/null &
sleep 3

echo "Starting Chromium (no sandbox)..."
chromium-browser \
    --display=:0 \
    --incognito \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-setuid-sandbox \
    --disable-gpu \
    --disable-software-rasterizer \
    --disable-features=VizDisplayCompositor \
    https://www.google.com &
sleep 5

echo "Starting x11vnc..."
x11vnc -display :0 -forever -passwd secret -shared -rfbport 5900 -nowf -noxdamage &
sleep 2

echo "Starting noVNC..."
websockify --web /usr/share/novnc 8080 localhost:5900 &

echo "=========================================="
echo "  ✅ VNC Desktop Ready!"
echo "  🔑 Password: secret"
echo "  📍 https://alpine-vnc.onrender.com:8080/vnc.html"
echo "=========================================="

while true; do
    sleep 300
done
