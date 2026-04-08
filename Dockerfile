FROM alpine:latest

RUN apk add --no-cache \
    xvfb \
    x11vnc \
    fluxbox \
    novnc \
    bash \
    chromium

RUN echo '#!/bin/bash' > /start.sh && \
    echo '' >> /start.sh && \
    echo '# 清理' >> /start.sh && \
    echo 'rm -f /tmp/.X0-lock' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Xvfb' >> /start.sh && \
    echo 'Xvfb :0 -screen 0 1024x768x16 &' >> /start.sh && \
    echo 'sleep 2' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Fluxbox' >> /start.sh && \
    echo 'fluxbox &' >> /start.sh && \
    echo 'sleep 1' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# x11vnc' >> /start.sh && \
    echo 'x11vnc -display :0 -forever -nopw &' >> /start.sh && \
    echo 'sleep 1' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Chrome' >> /start.sh && \
    echo 'DISPLAY=:0 chromium-browser --no-sandbox --incognito about:blank &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# noVNC' >> /start.sh && \
    echo 'websockify --web /usr/share/novnc 8080 localhost:5900' >> /start.sh

RUN chmod +x /start.sh

EXPOSE 8080

CMD ["/bin/bash", "/start.sh"]
