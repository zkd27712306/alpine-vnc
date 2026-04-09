FROM alpine:latest

# 第一步：只安装最基础的包
RUN apk update && apk add --no-cache \
    xvfb \
    x11vnc \
    fluxbox \
    bash \
    chromium \
    python3 \
    py3-pip \
    curl

# 第二步：用 pip 安装 websockify
RUN pip3 install websockify --break-system-packages

# 第三步：下载 noVNC
RUN mkdir -p /app/novnc && \
    cd /app && \
    curl -L https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar xz && \
    mv noVNC-1.4.0/* novnc/

# 第四步：创建最简单的启动脚本
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo 'rm -f /tmp/.X0-lock' >> /start.sh && \
    echo 'Xvfb :0 -screen 0 1024x768x16 &' >> /start.sh && \
    echo 'sleep 3' >> /start.sh && \
    echo 'fluxbox &' >> /start.sh && \
    echo 'x11vnc -display :0 -forever -nopw &' >> /start.sh && \
    echo 'sleep 2' >> /start.sh && \
    echo 'DISPLAY=:0 chromium-browser --no-sandbox --incognito https://google.com &' >> /start.sh && \
    echo 'websockify --web /app/novnc 0.0.0.0:8080 localhost:5900' >> /start.sh && \
    chmod +x /start.sh

EXPOSE 8080

CMD ["/bin/bash", "/start.sh"]
