FROM alpine:latest

RUN apk add --no-cache \
    xvfb \
    x11vnc \
    fluxbox \
    chromium \
    nginx \
    bash \
    curl

# 下载 noVNC
RUN mkdir -p /app/novnc && \
    cd /app && \
    curl -L https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar xz && \
    mv noVNC-1.4.0 novnc && \
    curl -L https://github.com/novnc/websockify/archive/refs/tags/v0.11.0.tar.gz | tar xz && \
    mv websockify-0.11.0 websockify

# nginx 配置
RUN cat > /etc/nginx/http.d/default.conf << 'EOF'
server {
    listen 8080;
    location / {
        root /app/novnc;
        index vnc.html;
    }
    location /websockify {
        proxy_pass http://127.0.0.1:6080/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

# 启动脚本
RUN cat > /start.sh << 'EOF'
#!/bin/bash
mkdir -p /run/nginx
Xvfb :0 -screen 0 1280x800x24 &
sleep 3
fluxbox &
x11vnc -display :0 -forever -nopw -listen 127.0.0.1 -rfbport 5900 &
sleep 2
DISPLAY=:0 chromium-browser --no-sandbox --incognito https://google.com &
python3 /app/websockify/run --web /app/novnc 127.0.0.1:6080 127.0.0.1:5900 &
nginx -g "daemon off;"
EOF

RUN chmod +x /start.sh

EXPOSE 8080
CMD ["/start.sh"]
