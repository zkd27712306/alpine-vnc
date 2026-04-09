FROM alpine:latest

RUN apk add --no-cache \
    xvfb \
    x11vnc \
    fluxbox \
    firefox \
    novnc \
    bash \
    curl \
    dbus \
    ttf-freefont \
    python3 \
    py3-pip

# 用 pip 安装 websockify（原来 apk 里有，现在没了）
RUN pip3 install websockify --break-system-packages

ENV DISPLAY=:0
ENV RESOLUTION=1280x720
ENV PASSWORD=secret

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8080

CMD ["/start.sh"]
