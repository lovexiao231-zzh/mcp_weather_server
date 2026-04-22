#!/bin/bash
# Jenkins 安装脚本 - 使用 Docker 运行 Jenkins

set -e

echo "=== Jenkins 安装脚本 ==="

# 检查 Docker 是否已安装
if ! command -v docker &> /dev/null; then
    echo "错误：Docker 未安装，请先运行 docker-setup.sh"
    exit 1
fi

# 创建 Jenkins 数据目录
JENKINS_HOME="/opt/jenkins"
echo "[1/3] 创建 Jenkins 数据目录：$JENKINS_HOME"
mkdir -p $JENKINS_HOME

# 授予权限（重要：避免权限问题）
echo "[2/3] 设置目录权限..."
# Windows Git Bash 可能需要特殊处理
if [[ $(uname -o) == *Msys* ]] || [[ $(uname -o) == *Cygwin* ]]; then
    echo "检测到 MSYS/Cygwin 环境，跳过 chown"
else
    chown -R 1000:1000 $JENKINS_HOME 2>/dev/null || true
fi

# 运行 Jenkins 容器
echo "[3/3] 启动 Jenkins 容器..."
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8081:8080 \
  -p 50000:50000 \
  -v $JENKINS_HOME:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/bin/docker:/usr/bin/docker \
  jenkins/jenkins:lts-jdk17

# 等待 Jenkins 启动
echo ""
echo "等待 Jenkins 启动..."
sleep 10

# 获取初始管理员密码
echo ""
echo "=== Jenkins 安装完成 ==="
echo ""
echo "访问地址：http://localhost:8081"
echo ""
echo "初始管理员密码："
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || \
    echo "请在 Jenkins 容器日志中查找密码"
echo ""
echo "请复制上述密码完成初始化配置"