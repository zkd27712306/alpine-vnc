FROM alpine:latest

# 安装所有必要软件
RUN apk update && apk add --no-cache \
    x11vnc \
    xvfb \
    openbox \
    xterm \
    bash \
    novnc \
    fluxbox \
    dbus-x11 \
    mesa-dri-gallium \
    ttf-dejavu \
    ttf-liberation \
    font-noto \
    chromium \
    udev \
    nss \
    cups-libs \
    libxrandr \
    gtk+3.0 \
    alsa-lib

# 创建启动脚本
RUN mkdir -p /app && \
    echo '#!/bin/bash' > /app/start.sh && \
    echo 'set -e' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# 启动 Xvfb 虚拟显示' >> /app/start.sh && \
    echo 'Xvfb :0 -screen 0 1280x800x24 -ac +extension GLX +render -noreset &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# 等待 X 启动' >> /app/start.sh && \
    echo 'sleep 2' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# 启动窗口管理器' >> /app/start.sh && \
    echo 'fluxbox -display :0 &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# 启动 VNC 服务' >> /app/start.sh && \
    echo 'x11vnc -display :0 -forever -nopw -shared -rfbport 5900 &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# 启动 Chromium 无痕模式' >> /app/start.sh && \
    echo 'sleep 3' >> /app/start.sh && \
    echo 'DISPLAY=:0 chromium-browser \' >> /app/start.sh && \
    echo '    --no-sandbox \' >> /app/start.sh && \
    echo '    --disable-dev-shm-usage \' >> /app/start.sh && \
    echo '    --disable-gpu \' >> /app/start.sh && \
    echo '    --disable-setuid-sandbox \' >> /app/start.sh && \
    echo '    --window-size=1280,800 \' >> /app/start.sh && \
    echo '    --incognito \' >> /app/start.sh && \
    echo '    --no-first-run \' >> /app/start.sh && \
    echo '    --no-default-browser-check \' >> /app/start.sh && \
    echo '    --disable-sync \' >> /app/start.sh && \
    echo '    --disable-translate \' >> /app/start.sh && \
    echo '    --ignore-certificate-errors \' >> /app/start.sh && \
    echo '    --user-data-dir=/tmp/chrome-profile \' >> /app/start.sh && \
    echo '    ${CHROME_URL:-https://www.google.com} &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# 启动 noVNC Web 服务' >> /app/start.sh && \
    echo 'echo "=================================="' >> /app/start.sh && \
    echo 'echo "VNC 服务已启动在端口 5900"' >> /app/start.sh && \
    echo 'echo "noVNC Web 界面已启动在端口 8080"' >> /app/start.sh && \
    echo 'echo "Chrome 无痕模式已启动"' >> /app/start.sh && \
    echo 'echo "=================================="' >> /app/start.sh && \
    echo '/usr/bin/novnc_server --vnc localhost:5900 --listen 8080' >> /app/start.sh && \
    chmod +x /app/start.sh

# 暴露端口
EXPOSE 8080 5900

# 设置环境变量
ENV DISPLAY=:0 \
    CHROME_URL=https://www.google.com

# 直接启动
CMD ["/bin/bash", "/app/start.sh"]
