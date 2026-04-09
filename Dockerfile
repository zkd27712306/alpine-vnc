FROM alpine:latest

RUN apk update && apk add --no-cache \
    xvfb x11vnc fluxbox bash chromium \
    nss cups-libs gtk+3.0 dbus dbus-x11 \
    ttf-dejavu mesa-dri-gallium mesa-gl \
    libxcb libxshmfence python3 py3-pip curl unzip

RUN mkdir -p /app && cd /app && \
    curl -L https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar xz && \
    mv noVNC-1.4.0 novnc

RUN pip3 install websockify --break-system-packages

# 创建默认 index.html 自动跳转
RUN echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0; url=vnc_lite.html?path=websockify"></head><body>Redirecting...</body></html>' > /app/novnc/index.html

RUN cat > /app/start.sh << 'EOF'
#!/bin/bash
rm -f /tmp/.X0-lock 2>/dev/null
mkdir -p /tmp/.X11-unix /run/dbus
chmod 1777 /tmp/.X11-unix
dbus-daemon --system --fork 2>/dev/null || true

Xvfb :0 -screen 0 1280x800x24 -ac &
sleep 3
export DISPLAY=:0
fluxbox 2>/dev/null &
sleep 2
x11vnc -display :0 -forever -nopw -listen 0.0.0.0 -rfbport 5900 2>/dev/null &
sleep 2
DISPLAY=:0 chromium-browser --no-sandbox --incognito --window-size=1280,800 https://google.com 2>/dev/null &
sleep 3

echo "=== 服务已启动 ==="
cd /app/novnc
websockify --web /app/novnc 0.0.0.0:8080 localhost:5900
EOF

RUN chmod +x /app/start.sh
EXPOSE 8080
ENV PORT=8080
CMD ["/app/start.sh"]
