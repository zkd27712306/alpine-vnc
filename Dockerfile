FROM alpine:latest

# 安装必要软件
RUN apk add --no-cache \
    xvfb \
    x11vnc \
    fluxbox \
    chromium \
    novnc \
    websockify \
    bash \
    curl \
    ttf-freefont \
    ttf-dejavu \
    ttf-liberation \
    netcat-openbsd

# 创建必要目录
RUN mkdir -p /var/run/dbus /run/dbus /tmp/.X11-unix

# 设置环境变量
ENV DISPLAY=:0
ENV RESOLUTION=1280x720
ENV PASSWORD=secret

# 复制启动脚本
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 暴露端口
EXPOSE 8080

# 启动命令
CMD ["/start.sh"]
