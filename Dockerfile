FROM alpine:latest

RUN apk update && apk add --no-cache \
    x11vnc \
    xvfb \
    openbox \
    bash \
    novnc \
    fluxbox \
    ttf-dejavu \
    chromium \
    nss \
    cups-libs \
    gtk+3.0 \
    dbus \
    dbus-x11 \
    mesa-dri-gallium

# 启动 dbus 服务
RUN mkdir -p /run/dbus

# 创建启动脚本
RUN cat > /app/start.sh << 'EOF'
#!/bin/bash

echo "=== 启动服务 ==="

# 清理残留
rm -f /tmp/.X0-lock /tmp/.X11-unix/X0 2>/dev/null

# 启动 dbus
echo "启动 dbus..."
dbus-daemon --system --fork

# 启动 Xvfb
echo "启动 Xvfb..."
Xvfb :0 -screen 0 1280x800x24 -ac &
sleep 3

# 设置 DISPLAY
export DISPLAY=:0

# 启动 fluxbox
echo "启动 fluxbox..."
fluxbox 2>/dev/null &
sleep 2

# 启动 x11vnc
echo "启动 x11vnc..."
x11vnc -display :0 -forever -nopw -listen 0.0.0.0 -rfbport 5900 2>/dev/null &
sleep 2

# 启动 Chromium 并自动打开 Google
echo "启动 Chromium 无痕模式，打开 Google..."
DISPLAY=:0 chromium-browser \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --window-size=1280,800 \
    --incognito \
    --no-first-run \
    --disable-dbus \
    --user-data-dir=/tmp/chrome \
    https://www.google.com 2>/dev/null &

sleep 3

# 检查 Chrome 是否启动
if pgrep -f chromium > /dev/null; then
    echo "✅ Chromium 已成功启动"
else
    echo "⚠️ Chromium 启动失败，但 VNC 仍可手动启动浏览器"
fi

echo "=========================================="
echo "✅ 服务已就绪"
echo "📺 VNC 端口: 5900"
echo "🌐 noVNC 端口: ${PORT:-8080}"
echo "🔗 访问: https://你的域名.onrender.com"
echo "🌍 Chrome 已打开: https://www.google.com"
echo "=========================================="

# 启动 noVNC
if [ -f /usr/bin/novnc_server ]; then
    /usr/bin/novnc_server --vnc localhost:5900 --listen 0.0.0.0:${PORT:-8080}
else
    websockify --web /usr/share/novnc ${PORT:-8080} localhost:5900
fi

# 保持运行
wait
EOF

RUN chmod +x /app/start.sh

EXPOSE 8080 5900

ENV DISPLAY=:0 \
    PORT=8080

CMD ["/bin/bash", "/app/start.sh"]
