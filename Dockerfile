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
    ttf-dejavu \
    mesa-dri-gallium \
    mesa-gl \
    libxcb \
    libxshmfence \
    python3 \
    py3-pip \
    curl \
    unzip \
    net-tools

# 下载 noVNC
RUN mkdir -p /app && \
    cd /app && \
    curl -L -o novnc.zip https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.zip && \
    unzip -q novnc.zip && \
    mv noVNC-1.4.0 novnc && \
    rm novnc.zip

# 安装 websockify
RUN pip3 install websockify --break-system-packages

# 创建启动脚本 - 增加调试信息
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

# 1. 启动 Xvfb
echo "[1/5] 启动虚拟显示器 Xvfb..."
Xvfb :0 -screen 0 1280x800x24 -ac +extension GLX +render &
sleep 3

# 检查 Xvfb
if pgrep Xvfb > /dev/null; then
    echo "✅ Xvfb 启动成功"
else
    echo "❌ Xvfb 启动失败"
fi

export DISPLAY=:0

# 2. 启动 fluxbox
echo "[2/5] 启动窗口管理器 Fluxbox..."
fluxbox 2>/dev/null &
sleep 2

# 3. 启动 x11vnc
echo "[3/5] 启动 VNC 服务..."
x11vnc -display :0 -forever -nopw -listen 0.0.0.0 -rfbport 5900 2>/tmp/vnc.log &
sleep 3

# 检查 VNC
if pgrep x11vnc > /dev/null; then
    echo "✅ VNC 启动成功，监听端口 5900"
else
    echo "❌ VNC 启动失败"
    cat /tmp/vnc.log
fi

# 测试 VNC 端口
sleep 1
if netstat -tlnp 2>/dev/null | grep 5900 > /dev/null; then
    echo "✅ 端口 5900 正在监听"
else
    echo "❌ 端口 5900 未监听"
fi

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
echo "=========================================="
echo ""

# 修改 noVNC 默认连接配置
cd /app/novnc
# 创建自定义配置
cat > /app/novnc/custom.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>VNC Client</title>
    <script>
        window.onload = function() {
            var url = window.location.protocol + '//' + window.location.hostname;
            if(window.location.port) url += ':' + window.location.port;
            var wsurl = url.replace('http', 'ws');
            var path = wsurl + '/websockify';
            
            var rfb = new RFB({
                target: document.getElementById('screen'),
                url: path,
                credentials: { password: '' },
                repeaterID: '',
                shared: true,
                wsProtocols: ['binary']
            });
        };
    </script>
</head>
<body style="margin:0; background:#000;">
    <div id="screen" style="width:100vw; height:100vh;"></div>
    <script src="app/ui.js"></script>
</body>
</html>
HTML

# 启动 websockify
websockify --web /app/novnc 0.0.0.0:${PORT:-8080} localhost:5900
EOF

RUN chmod +x /app/start.sh

EXPOSE 8080 5900

ENV DISPLAY=:0 \
    PORT=8080

CMD ["/bin/bash", "/app/start.sh"]
