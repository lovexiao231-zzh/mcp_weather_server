#!/bin/bash
# 部署脚本 - 用于 Jenkins 远程执行部署

set -e

IMAGE_NAME="lovexiao2311/mcp_weather_server"
VERSION=${VERSION:-"latest"}
COMPOSE_FILE="/opt/mcp-weather-server/docker-compose.yml"

echo "=== 开始部署 MCP Weather Server ==="
echo "镜像版本：$VERSION"

# 进入部署目录
cd /opt/mcp-weather-server

# 停止并移除旧容器
echo "[1/4] 停止旧容器..."
docker compose -f $COMPOSE_FILE down || true

# 拉取新镜像
echo "[2/4] 拉取新镜像..."
docker compose -f $COMPOSE_FILE pull

# 启动新容器
echo "[3/4] 启动新容器..."
docker compose -f $COMPOSE_FILE up -d

# 清理悬空镜像
echo "[4/4] 清理悬空镜像..."
docker image prune -f

# 检查容器状态
echo ""
echo "=== 部署完成，容器状态 ==="
docker compose -f $COMPOSE_FILE ps

echo ""
echo "服务日志 (最近 20 行):"
docker logs --tail 20 mcp-weather-server