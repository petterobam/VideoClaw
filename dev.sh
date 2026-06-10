#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$ROOT_DIR/video-claw/video-claw/backend"
FRONTEND_DIR="$ROOT_DIR/video-claw/video-claw/frontend"

BACKEND_PORT=8000
FRONTEND_PORT=3000

PIDS=()

cleanup() {
    echo ""
    echo "正在关闭所有服务..."
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            wait "$pid" 2>/dev/null || true
        fi
    done
    echo "已关闭所有服务。"
    exit 0
}

trap cleanup SIGINT SIGTERM

kill_port() {
    local port=$1
    local pids
    pids=$(lsof -ti :"$port" 2>/dev/null || true)
    if [ -n "$pids" ]; then
        echo "端口 $port 已被占用，正在关闭旧进程..."
        echo "$pids" | xargs kill 2>/dev/null || true
        sleep 1
        # force kill if still alive
        pids=$(lsof -ti :"$port" 2>/dev/null || true)
        if [ -n "$pids" ]; then
            echo "$pids" | xargs kill -9 2>/dev/null || true
            sleep 1
        fi
        echo "端口 $port 已释放。"
    fi
}

# Kill existing processes on both ports
kill_port "$BACKEND_PORT"
kill_port "$FRONTEND_PORT"

# Start backend
echo "启动后端 (port $BACKEND_PORT)..."
cd "$BACKEND_DIR"
uv run python api_server.py &
PIDS+=($!)
BACKEND_PID=$!

# Start frontend
echo "启动前端 (port $FRONTEND_PORT)..."
cd "$FRONTEND_DIR"
npm run dev &
PIDS+=($!)
FRONTEND_PID=$!

cd "$ROOT_DIR"

echo ""
echo "======================================"
echo "  VideoClaw 开发环境已启动"
echo "  后端: http://localhost:$BACKEND_PORT (PID $BACKEND_PID)"
echo "  前端: http://localhost:$FRONTEND_PORT (PID $FRONTEND_PID)"
echo "  按 Ctrl+C 关闭所有服务"
echo "======================================"
echo ""

# Wait for any child to exit
wait
