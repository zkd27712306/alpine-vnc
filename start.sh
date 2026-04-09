#!/bin/bash

echo "=========================================="
echo "  Starting Alpine VNC Desktop on Render"
echo "=========================================="

rm -rf /tmp/.X0-lock /tmp/.X11-unix 2>/dev/null

echo "Starting Xvfb..."
Xvfb :0 -screen 0 ${RESOLUTION}x24 &
sleep 3

export DISPLAY=:0

echo "Starting Fluxbox..."
fluxbox -display :0 &
sleep 3

echo "Starting Firefox (Private Mode)..."
firefox --display=:0 --private-window https://www.google.com &
sleep 5

echo "Starting x11vnc..."
x11vnc -display :0 -forever -passwd ${PASSWORD} -shared -rfbport 5900 &
sleep 2

echo "Starting noVNC..."
websockify --web /usr/share/novnc 8080 localhost:5900 &

echo "=========================================="
echo "  ✅ VNC Desktop Ready!"
echo "  🔑 Password: ${PASSWORD}"
echo "  📍 Port: 8080"
echo "=========================================="

while true; do
    sleep 300
done
