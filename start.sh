#!/bin/bash

# 清理锁文件
rm -rf /tmp/.X0-lock /tmp/.X11-unix 2>/dev/null

# 启动健康检查服务（解决 Render 健康检查问题）
echo "Starting health check server on port 8081..."
(
  while true; do
    echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nOK" | nc -l -p 8081 -q 1
  done
) &
HEALTH_PID=$!

# 启动 Xvfb（虚拟显示）
echo "Starting Xvfb with resolution ${RESOLUTION}..."
Xvfb :0 -screen 0 ${RESOLUTION}x24 -ac &
sleep 3

export DISPLAY=:0

# 启动 Fluxbox（窗口管理器）
echo "Starting Fluxbox window manager..."
fluxbox -display :0 &
sleep 3

# 启动 Chromium（优化参数，静默运行）
echo "Starting Chromium browser..."
chromium-browser \
  --display=:0 \
  --incognito \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  --disable-software-rasterizer \
  --disable-features=VizDisplayCompositor \
  --disable-background-timer-throttling \
  --disable-breakpad \
  --disable-crash-reporter \
  --disable-logging \
  --log-level=3 \
  --disable-notifications \
  --disable-sync \
  --no-first-run \
  --disable-default-apps \
  --disable-infobars \
  --disable-extensions \
  --disable-plugins \
  --disable-session-crashed-bubble \
  --remote-debugging-port=9222 \
  --window-size=1280,720 \
  --window-position=0,0 \
  https://www.google.com &
sleep 5

# 启动 x11vnc（VNC 服务器）
echo "Starting x11vnc VNC server..."
x11vnc \
  -display :0 \
  -forever \
  -passwd ${PASSWORD} \
  -shared \
  -rfbport 5900 \
  -noxdamage \
  -nowf \
  -noscr \
  -xkb \
  -repeat \
  -nevershared \
  -bg &
sleep 3

# 启动 noVNC（WebSocket 代理）- 使用循环自动重启
echo "Starting noVNC WebSocket proxy..."
(
  while true; do
    websockify \
      --web /usr/share/novnc \
      --heartbeat=30 \
      --timeout=0 \
      --idle-timeout=0 \
      0.0.0.0:8080 \
      localhost:5900
    echo "WebSocket proxy exited, restarting in 2 seconds..."
    sleep 2
  done
) &

echo ""
echo "=========================================="
echo "  ✅ VNC Desktop Ready!"
echo "  🔑 Password: ${PASSWORD}"
echo "  📍 VNC Port: 5900"
echo "  🌐 Web Port: 8080"
echo "  🔗 Access URL: https://你的服务名.onrender.com"
echo "=========================================="
echo ""

# 监控所有关键进程，自动重启失败的进程
while true; do
    # 检查关键进程
    if ! pgrep -x "Xvfb" > /dev/null; then
        echo "Xvfb died, restarting..."
        Xvfb :0 -screen 0 ${RESOLUTION}x24 -ac &
        export DISPLAY=:0
        sleep 3
    fi
    
    if ! pgrep -x "fluxbox" > /dev/null; then
        echo "Fluxbox died, restarting..."
        fluxbox -display :0 &
        sleep 2
    fi
    
    if ! pgrep -f "x11vnc" > /dev/null; then
        echo "x11vnc died, restarting..."
        x11vnc -display :0 -forever -passwd ${PASSWORD} -shared -rfbport 5900 -noxdamage -nowf -noscr -xkb -repeat -nevershared -bg &
        sleep 2
    fi
    
    # 健康检查服务器保持运行
    if ! kill -0 $HEALTH_PID 2>/dev/null; then
        echo "Health check server died, restarting..."
        (
          while true; do
            echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nOK" | nc -l -p 8081 -q 1
          done
        ) &
        HEALTH_PID=$!
    fi
    
    sleep 30
done
