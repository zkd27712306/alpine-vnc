FROM alpine:latest

# 安装所有必要软件（增加 Xvfb 依赖）
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
    ttf-dejavu \
    mesa-dri-gallium \
    mesa-gl \
    libxcb \
    libxshmfence \
    python3 \
    py3-pip \
    curl \
    unzip

# 下载 noVNC 和 websockify
RUN mkdir -p /app && \
    cd /app && \
    curl -L -o novnc.zip https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.zip && \
    unzip -q novnc.zip && \
    mv noVNC-1.4.0 novnc && \
    rm novnc.zip

# 用 pip 安装 websockify（避免 shell 语法问题）
RUN pip3 install websockify

# 创建启动脚本
RUN cat > /app/start.sh << 'EOF'
#!/bin/bash

echo "=========================================="
echo "     Alpine VNC + Chrome 启动中...       "
echo "=========================================="

# 清理残留
rm -f /tmp/.X0-lock 2>/dev/null
rm -rf /tmp/.X11-unix 2>/dev/null
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# 启动 dbus
mkdir -p /run/dbus
dbus-daemon --system --fork 2>/dev/null || true

# 1. 启动 Xvfb（增加更多参数）
echo "[1/5] 启动虚拟显示器 Xvfb..."
Xvfb :0 -screen 0 1280x800x24 -ac +extension GLX +render -noreset &
sleep 3

# 检查 Xvfb 是否启动成功
if ! pgrep Xvfb > /dev/null; then
    echo "❌ Xvfb 启动失败，尝试备用方式..."
    Xvfb :0 -screen 0 1024x768x16 &
    sleep 3
fi

export DISPLAY=:0

# 2. 启动 fluxbox
echo "[2/5] 启动窗口管理器 Fluxbox..."
fluxbox 2>/dev/null &
sleep 2

# 3. 启动 x11vnc
echo "[3/5] 启动 VNC 服务..."
x11vnc -display :0 -forever -nopw -listen 0.0.0.0 -rfbport 5900 2>/dev/null &
sleep 2

# 4. 启动 Chromium
echo "[4/5] 启动 Chromium 无痕模式..."
DISPLAY=:0 chromium-browser \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --disable-software-rasterizer \
    --window-size=1280,800 \
    --incognito \
    --no-first-run \
    --disable-dbus \
    --user-data-dir=/tmp/chrome \
    https://www.google.com 2>/dev/null &

sleep 3

# 5. 启动 noVNC
echo "[5/5] 启动 noVNC Web 服务..."
echo ""
echo "=========================================="
echo "           服务已成功启动！               "
echo "=========================================="
echo "  VNC 端口: 5900"
echo "  Web 端口: ${PORT:-8080}"
echo "  访问地址: https://你的域名.onrender.com"
echo "=========================================="
echo ""

# 启动 websockify（使用 pip 安装的版本）
websockify --web /app/novnc 0.0.0.0:${PORT:-8080} localhost:5900
EOF

RUN chmod +x /app/start.sh

EXPOSE 8080 5900

ENV DISPLAY=:0 \
    PORT=8080

CMD ["/bin/bash", "/app/start.sh"]
