FROM alpine:latest

# 安装所有必要软件
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
    mesa-dri-gallium \
    nginx \
    curl

# 创建目录
RUN mkdir -p /run/dbus /run/nginx /app

# 创建 nginx 配置 - 关键：正确转发 WebSocket
RUN cat > /etc/nginx/http.d/novnc.conf << 'EOF'
server {
    listen ${PORT:-8080};
    
    location / {
        root /usr/share/novnc;
        index vnc.html;
        try_files $uri $uri/ =404;
    }
    
    location /websockify {
        proxy_pass http://127.0.0.1:6080/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }
}
EOF

# 替换端口变量
RUN sed -i 's/${PORT:-8080}/8080/g' /etc/nginx/http.d/novnc.conf

# 创建启动脚本
RUN cat > /app/start.sh << 'EOF'
#!/bin/bash

echo "=== Alpine VNC + Chrome 启动中 ==="

# 清理残留
rm -f /tmp/.X0-lock /tmp/.X11-unix/X0 2>/dev/null

# 启动 dbus
dbus-daemon --system --fork 2>/dev/null

# 启动 Xvfb
echo "[1/6] 启动虚拟显示器 Xvfb..."
Xvfb :0 -screen 0 1280x800x24 -ac +extension GLX +render &
sleep 3

export DISPLAY=:0

# 启动 fluxbox
echo "[2/6] 启动窗口管理器 Fluxbox..."
fluxbox 2>/dev/null &
sleep 2

# 启动 x11vnc
echo "[3/6] 启动 VNC 服务..."
x11vnc -display :0 -forever -nopw -listen 127.0.0.1 -rfbport 5900 2>/dev/null &
sleep 2

# 启动 Chrome
echo "[4/6] 启动 Chrome 无痕模式..."
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

# 启动 websockify
echo "[5/6] 启动 WebSocket 代理..."
websockify --web /usr/share/novnc 127.0.0.1:6080 127.0.0.1:5900 2>/dev/null &
sleep 2

echo ""
echo "=========================================="
echo "✅ 所有服务已启动成功！"
echo "=========================================="
echo "📺 VNC 端口: 5900"
echo "🌐 HTTP 端口: ${PORT:-8080}"
echo "🔗 访问地址: https://你的域名.onrender.com"
echo "💡 提示: 直接访问即可，无需添加路径参数"
echo "=========================================="
echo ""

# 启动 nginx
echo "[6/6] 启动 Nginx..."
exec nginx -g "daemon off;"
EOF

RUN chmod +x /app/start.sh

EXPOSE 8080

ENV DISPLAY=:0 \
    PORT=8080

CMD ["/bin/bash", "/app/start.sh"]
