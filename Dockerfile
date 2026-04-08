FROM alpine:latest

RUN apk update && apk add --no-cache \
    xvfb \
    x11vnc \
    fluxbox \
    bash \
    chromium \
    nss \
    cups-libs \
    gtk+3.0 \
    dbus \
    dbus-x11 \
    curl \
    python3 \
    py3-pip

# 下载 noVNC 和 websockify
RUN mkdir -p /app && \
    cd /app && \
    curl -L -o novnc.zip https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.zip && \
    unzip -q novnc.zip && \
    mv noVNC-1.4.0 novnc && \
    rm novnc.zip && \
    curl -L -o websockify.zip https://github.com/novnc/websockify/archive/refs/tags/v0.11.0.zip && \
    unzip -q websockify.zip && \
    mv websockify-0.11.0 websockify && \
    rm websockify.zip

# 创建启动脚本
RUN cat > /app/start.sh << 'EOF'
#!/bin/bash

echo "=========================================="
echo "       启动 Alpine VNC + Chrome          "
echo "=========================================="

# 清理
rm -f /tmp/.X0-lock 2>/dev/null
mkdir -p /run/dbus

# 启动 dbus
dbus-daemon --system --fork 2>/dev/null

# 启动 Xvfb
echo "[1/5] 启动虚拟显示器..."
Xvfb :0 -screen 0 1280x800x24 -ac &
sleep 3

export DISPLAY=:0

# 启动 fluxbox
echo "[2/5] 启动窗口管理器..."
fluxbox 2>/dev/null &
sleep 2

# 启动 x11vnc
echo "[3/5] 启动 VNC 服务..."
x11vnc -display :0 -forever -nopw -listen 0.0.0.0 -rfbport 5900 2>/dev/null &
sleep 2

# 启动 Chrome
echo "[4/5] 启动 Chrome 无痕模式..."
DISPLAY=:0 chromium-browser \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --window-size=1280,800 \
    --incognito \
    --no-first-run \
    --user-data-dir=/tmp/chrome \
    https://www.google.com 2>/dev/null &

sleep 3

echo "[5/5] 启动 noVNC Web 服务..."
echo ""
echo "=========================================="
echo "✅ 服务已启动！"
echo "=========================================="
echo "📌 访问地址: https://你的域名.onrender.com"
echo "📌 如果连接失败，尝试: https://你的域名.onrender.com/vnc.html?path=websockify"
echo "=========================================="
echo ""

# 启动 websockify（直接监听 8080，不使用 nginx）
cd /app/novnc
python3 /app/websockify/run --web /app/novnc --cert=none 0.0.0.0:8080 localhost:5900
EOF

RUN chmod +x /app/start.sh

EXPOSE 8080 5900

ENV DISPLAY=:0 \
    PORT=8080

CMD ["/bin/bash", "/app/start.sh"]
