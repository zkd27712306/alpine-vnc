FROM alpine:latest

RUN apk add --no-cache \
    xvfb \
    x11vnc \
    fluxbox \
    chromium \
    novnc \
    websockify \
    bash \
    curl \
    dbus \
    ttf-freefont

ENV DISPLAY=:0
ENV RESOLUTION=1280x720
ENV PASSWORD=secret

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8080

CMD ["/start.sh"]
