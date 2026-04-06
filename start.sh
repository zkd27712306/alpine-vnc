#!/bin/bash

echo "=========================================="
echo "  Starting Alpine VNC Desktop"
echo "=========================================="

# 清理
rm -rf /tmp/.X0-lock /tmp/.X11-unix 2>/dev/null

# 启动虚拟显示器
Xvfb :0 -screen 0 ${RESOLUTION}x24 -ac &
sleep 3

export DISPLAY=:0

# 启动窗口管理器
fluxbox -display :0 2>/dev/null &
sleep 3

# 启动浏览器
chromium-browser \
    --display=:0 \
    --incognito \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-setuid-sandbox \
    https://www.google.com &
sleep 5

# 启动 VNC
x11vnc -display :0 -forever -passwd ${PASSWORD} -shared -rfbport 5900 -nowf -noxdamage &
sleep 2

# 启动 noVNC（修复版）
websockify --web /usr/share/novnc --listen 8080 localhost:5900 &

echo "=========================================="
echo "  ✅ Ready!"
echo "  🔑 Password: ${PASSWORD}"
echo "  📍 https://alpine-vnc.onrender.com/vnc.html"
echo "=========================================="

while true; do
    sleep 300
done
