FROM alpine:latest

# 安装必要软件
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
    alsa-lib \
    curl

# 创建启动脚本 - 修复 noVNC 连接问题
RUN mkdir -p /app && \
    echo '#!/bin/bash' > /app/start.sh && \
    echo 'set -e' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# 清理旧进程' >> /app/start.sh && \
    echo 'rm -f /tmp/.X0-lock /tmp/.X11-unix/X0' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# 启动 Xvfb 虚拟显示' >> /app/start.sh && \
    echo 'Xvfb :0 -screen 0 1280x800x24 -ac +extension GLX +render &' >> /app/start.sh && \
    echo 'export DISPLAY=:0' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# 等待 X 启动' >> /app/start.sh && \
    echo 'sleep 3' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# 启动窗口管理器' >> /app/start.sh && \
    echo 'fluxbox &' >> /app/start.sh && \
    echo 'sleep 2' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# 启动 x11vnc - 允许外部连接' >> /app/start.sh && \
    echo 'x11vnc -display :0 -forever -nopw -shared -listen 0.0.0.0 -rfbport 5900 &' >> /app/start.sh && \
    echo 'sleep 2' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# 启动 Chromium 无痕模式' >> /app/start.sh && \
    echo 'chromium-browser \\' >> /app/start.sh && \
    echo '    --no-sandbox \\' >> /app/start.sh && \
    echo '    --disable-dev-shm-usage \\' >> /app/start.sh && \
    echo '    --disable-gpu \\' >> /app/start.sh && \
    echo '    --window-size=1280,800 \\' >> /app/start.sh && \
    echo '    --incognito \\' >> /app/start.sh && \
    echo '    --no-first-run \\' >> /app/start.sh && \
    echo '    --ignore-certificate-errors \\' >> /app/start.sh && \
    echo '    --user-data-dir=/tmp/chrome-profile \\' >> /app/start.sh && \
    echo '    about:blank &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# 创建 noVNC token 文件' >> /app/start.sh && \
    echo 'mkdir -p /root/.vnc' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "=================================="' >> /app/start.sh && \
    echo 'echo "服务已启动"' >> /app/start.sh && \
    echo 'echo "VNC 端口: 5900"' >> /app/start.sh && \
    echo 'echo "noVNC 端口: ${PORT:-8080}"' >> /app/start.sh && \
    echo 'echo "=================================="' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# 启动 noVNC - 关键：监听 0.0.0.0 并使用正确的 WebSocket 路径' >> /app/start.sh && \
    echo 'websockify --web /usr/share/novnc 0.0.0.0:${PORT:-8080} localhost:5900' >> /app/start.sh && \
    chmod +x /app/start.sh

EXPOSE 8080 5900

ENV DISPLAY=:0

CMD ["/bin/bash", "/app/start.sh"]
