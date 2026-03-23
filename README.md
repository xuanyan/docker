# Docker 镜像集合

本仓库按**目录**划分三个独立镜像；说明统一写在仓库根目录本文件中。所有 `docker build` 均在**仓库根目录**执行（用 `-f` 指向对应 Dockerfile）。

| 目录 | 说明 | 默认镜像名（示例） |
|------|------|-------------------|
| [`aria2/`](aria2/) | aria2 下载（磁力 / BT / DHT），含仓库内 `aria2.conf` | `xuanyan/aria2:latest` |
| [`adminer/`](adminer/) | Adminer + PHP 内置服务器与自定义插件 | `adminer-multi-databases` |
| [`jenkins/`](jenkins/) | Alpine + OpenJDK 21 + Jenkins 稳定版 war | `jenkins-custom` |

---

## `aria2/`

### 概述

- **上下文**：构建时必须使用仓库根目录为 context（`COPY aria2/aria2.conf`）。
- **端口**：`6800`（RPC）、`51413/tcp` 与 `51413/udp`（BT/DHT；**UDP 必须映射**且宿主机可达）。

### 构建

本地：

```bash
docker build -t xuanyan/aria2:latest -f aria2/Dockerfile .
```

多架构构建并推送（维护者）：

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t xuanyan/aria2:latest \
  -t xuanyan/aria2:1.37.0 \
  --push \
  -f aria2/Dockerfile \
  .
```

也可直接拉取：`docker pull xuanyan/aria2:latest`

### 运行

```bash
docker run -d \
  --name aria2 \
  -p 6800:6800 \
  -p 51413:51413 \
  -p 51413:51413/udp \
  -v /path/to/downloads:/downloads \
  -v /path/to/aria2-data:/root/.aria2 \
  xuanyan/aria2:latest
```

### 可选

- JSON-RPC：`http://<host>:6800/jsonrpc`

---

## `adminer/`

### 概述

- **上下文**：构建目录为 `adminer/`（与 Dockerfile 同目录的 `index.php`、插件等一并打包）。
- **端口**：`8080`。
- **配置**：若挂载 `databases.php`，请挂到容器内 `/external/databases.php`；启动脚本会复制到 `/app/databases.php`（见 [`adminer/docker-entrypoint.sh`](adminer/docker-entrypoint.sh)）。

### 构建

```bash
docker build -t adminer-multi-databases -f adminer/Dockerfile adminer
```

### 运行

```bash
docker run -d \
  --name adminer \
  -p 8080:8080 \
  -v /path/to/my-databases.php:/external/databases.php:ro \
  adminer-multi-databases
```

浏览器访问：`http://<host>:8080`

---

## `jenkins/`

### 概述

- **上下文**：构建目录为 `jenkins/`（内含 `upgrade_jenkins.sh` 等）。
- **端口**：`8080`。
- **数据目录**：建议挂载 `/root/.jenkins` 持久化。

### 构建

```bash
docker build -t jenkins-custom -f jenkins/Dockerfile jenkins
```

### 运行

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -v jenkins_home:/root/.jenkins \
  jenkins-custom
```

浏览器访问：`http://<host>:8080`；首次启动在容器日志中查看初始管理员密码并完成向导。
