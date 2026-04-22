#!/bin/bash
# Docker 安装脚本 - 阿里云轻量应用服务器

set -e

echo "=== Docker 安装脚本 ==="

# 检查是否 root 用户
if [ "$EUID" -ne 0 ]; then
  echo "请使用 sudo 或以 root 用户运行此脚本"
  exit 1
fi

# 更新系统包
echo "[1/6] 更新系统包..."
apt-get update

# 安装依赖
echo "[2/6] 安装依赖..."
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 添加 Docker GPG key
echo "[3/6] 添加 Docker GPG key..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 添加 Docker 仓库
echo "[4/6] 添加 Docker 仓库..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# 安装 Docker
echo "[5/6] 安装 Docker..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 启动 Docker
echo "[6/6] 启动 Docker 并设置开机自启..."
systemctl enable docker
systemctl start docker

# 添加当前用户到 docker 组 (可选，避免使用 sudo)
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker $SUDO_USER
    echo "用户 $SUDO_USER 已添加到 docker 组，请重新登录后生效"
fi

# 验证安装
echo ""
echo "=== Docker 安装完成 ==="
docker --version
docker compose version

echo ""
echo "Docker 已就绪！"
