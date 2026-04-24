# MCP Weather Server 部署指南

本文档描述如何将 MCP Weather Server 部署到阿里云轻量应用服务器，并通过 Jenkins 实现 CI/CD 自动化。

## 目录

1. [环境准备](#1-环境准备)
2. [阿里云主机配置](#2-阿里云主机配置)
3. [Jenkins 环境搭建](#3-jenkins-环境搭建)
4. [Jenkins 凭证配置](#4-jenkins-凭证配置)
5. [Jenkins Pipeline 配置](#5-jenkins-pipeline-配置)
6. [GitHub Webhook 配置](#6-github-webhook-配置)
7. [手动部署](#7-手动部署)

---

## 1. 环境准备

### 前置条件
- GitHub 账号和项目仓库
- Docker Hub 账号（已配置自动发布）
- 阿里云账号
- 本地或云服务器（用于运行 Jenkins）

### 资源清单
| 资源 | 配置要求 | 用途 |
|------|----------|------|
| 阿里云轻量服务器 | 2 核 2GB, Ubuntu 22.04 | 运行 MCP 服务 |
| Jenkins 服务器 | 2 核 4GB 最低 | CI/CD 流水线 |

---

## 2. 阿里云主机配置

### 2.1 购买轻量应用服务器

1. 登录阿里云控制台
2. 选择「轻量应用服务器」
3. 选择镜像：**Ubuntu 22.04**
4. 选择配置：2 核 2GB 2M 带宽（最低）
5. 设置 root 密码或使用 SSH 密钥

### 2.2 开放防火墙端口

在阿里云控制台「防火墙」中开放以下端口：

| 端口 | 协议 | 用途 |
|------|------|------|
| 22 | TCP | SSH 远程连接 |
| 8085 | TCP | MCP 服务端口 |
| 80 | TCP | HTTP (可选) |
| 443 | TCP | HTTPS (可选) |

### 2.3 安装 Docker

SSH 登录服务器后执行：

```bash
# 下载并执行安装脚本
curl -fsSL https://get.docker.com | sh -s docker

# 启动 Docker
systemctl enable --now docker

# 验证安装
docker --version
docker compose version
```

### 2.4 创建部署目录

```bash
mkdir -p /opt/mcp-weather-server
cd /opt/mcp-weather-server
```

---

## 3. Jenkins 环境搭建

### 3.1 安装 Jenkins（Docker 方式）

```bash
# 创建 Jenkins 数据目录
mkdir -p /opt/jenkins

# 运行 Jenkins
docker run -d \
  --name jenkins \
  -p 8081:8080 \
  -p 50000:50000 \
  -v /opt/jenkins:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/bin/docker:/usr/bin/docker \
  jenkins/jenkins:lts-jdk17
```

访问 `http://your-server:8081` 完成初始化配置。

### 3.1.1 配置 Docker 权限（重要）

进入 Jenkins 容器，将 jenkins 用户加入 docker 组：

```bash
# 进入 Jenkins 容器
docker exec -it jenkins bash

# 获取 Docker 组 GID
DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)

# 创建 docker 组并添加 jenkins 用户
groupadd -g $DOCKER_GID docker 2>/dev/null || true
usermod -aG docker jenkins

# 重启 Jenkins 容器
exit
docker restart jenkins
```

### 3.2 安装必要插件

进入「系统管理」>「插件管理」，安装以下插件：

- **GitHub Integration Plugin** - GitHub 集成
- **Docker Plugin** - Docker 构建支持
- **Docker Pipeline** - Docker Pipeline 支持
- **SSH Agent Plugin** - SSH 密钥管理
- **Pipeline** - Pipeline 支持（默认已安装）

### 3.3 配置全局工具

进入「系统管理」>「全局工具配置」：

- **JDK**: 添加 JDK 17（如需要）
- **Docker**: 确认已自动检测

---

## 4. Jenkins 凭证配置

### 4.1 配置 Docker Hub 凭证

1. 进入「凭证」>「全局凭证」
2. 点击「添加凭证」
3. 类型：**Username with password**
4. ID: `docker-hub-credential`
5. 输入 Docker Hub 用户名和密码

### 4.2 配置阿里云 SSH 凭证

1. 生成 SSH 密钥对（本地执行）：
```bash
ssh-keygen -t ed25519 -C "jenkins-deploy" -f jenkins_aliyun_key
```

2. 将公钥复制到阿里云服务器：
```bash
ssh-copy-id -i jenkins_aliyun_key.pub root@your-aliyun-ip
```

3. 在 Jenkins 中添加凭证：
   - 类型：**SSH Username with private key**
   - ID: `aliyun-ssh-key`
   - Username: `root`
   - Private Key: 选择「直接进入」，粘贴私钥内容

---

## 5. Jenkins Pipeline 配置

### 5.1 创建 Pipeline 任务

1. 点击「新建任务」
2. 名称：`mcp-weather-deploy`
3. 类型：**Pipeline**
4. 点击「确定」

### 5.2 配置 Pipeline

在任务配置页：

1. **GitHub project**: 勾选并填写项目 URL
2. **源码管理**: Git
   - Repository URL: `https://github.com/isdaniel/mcp_weather_server.git`
   - Credentials: 配置 GitHub 凭证
   - Branches to build: `*/main`
3. **构建触发器**: 
   - 勾选「GitHub hook trigger for GITScm polling」
4. **Pipeline**: 
   - Definition: `Pipeline script from SCM`
   - Script Path: `deploy/Jenkinsfile`

保存配置。

---

## 6. GitHub Webhook 配置

### 6.1 在 GitHub 仓库配置 Webhook

1. 进入 GitHub 仓库 > Settings > Webhooks
2. 点击「Add webhook」
3. 配置：
   - **Payload URL**: `http://your-jenkins-url:8081/github-webhook/`
   - **Content type**: `application/json`
   - **Secret**: 留空或自定义
   - **Events**: 勾选「Push events」

### 6.2 验证 Webhook

点击 GitHub Webhook 配置页的「Recent Deliveries」查看触发记录。

---

## 7. 手动部署

### 7.1 手动执行部署脚本

在阿里云服务器上：

```bash
cd /opt/mcp-weather-server

# 拉取最新镜像
docker compose pull

# 重启服务
docker compose up -d

# 查看日志
docker logs -f mcp-weather-server
```

### 7.2 服务状态检查

```bash
# 检查容器状态
docker compose ps

# 测试服务
curl http://localhost:8085/mcp
```

---

## 附录

### A. 目录结构

```
/opt/mcp-weather-server/
├── docker-compose.yml    # Docker Compose 配置
└── deploy.sh            # 部署脚本（可选）
```

### B. 常见问题

**Q: Docker 镜像拉取失败**
- 检查 Docker Hub 凭证是否正确
- 检查网络连接

**Q: 容器启动失败**
- 查看日志：`docker logs mcp-weather-server`
- 检查端口占用：`netstat -tlnp | grep 8085`

**Q: Jenkins 无法连接 GitHub**
- 检查网络代理设置
- 验证 GitHub 凭证

### C. 安全建议

1. 配置 Jenkins HTTPS 访问
2. 使用 SSH 密钥而非密码
3. 定期更新系统和 Docker
4. 配置防火墙白名单