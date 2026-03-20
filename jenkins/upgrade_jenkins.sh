#!/bin/sh

# Jenkins升级脚本 (Docker版)
# 功能：检查版本 -> 停止服务 -> 更新当前目录下的jenkins.war并备份旧版本 -> 启动服务
# 用法：./upgrade_jenkins.sh <JENKINS_DOWNLOAD_URL>

set -e

JENKINS_WAR="jenkins.war"
JENKINS_PID_FILE="/tmp/jenkins.pid"
JENKINS_PORT=${JENKINS_PORT:-8080}

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1" >&2
}

usage() {
    echo "Jenkins升级脚本 (Docker版)" >&2
    echo "用法: $0 <JENKINS_DOWNLOAD_URL>" >&2
    echo "" >&2
    echo "示例:" >&2
    echo "  $0 https://get.jenkins.io/war/2.414.1/jenkins.war" >&2
    echo "  $0 https://get.jenkins.io/war-stable/2.528.1/jenkins.war" >&2
    echo "" >&2
}

extract_version_from_url() {
    url="$1"
    log_debug "解析URL: $url"

    echo "$url" | grep -oE '/war(-[a-z]+)?/[0-9]+\.[0-9]+(\.[0-9]+)?/jenkins\.war' | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?'
}

get_current_version() {
    if [ ! -f "$JENKINS_WAR" ]; then
        echo "unknown"
        return
    fi

    if command -v java >/dev/null 2>&1; then
        version=$(java -jar "$JENKINS_WAR" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
        if [ -n "$version" ]; then
            echo "$version"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

is_jenkins_running() {
    if [ -f "$JENKINS_PID_FILE" ]; then
        pid=$(cat "$JENKINS_PID_FILE")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi

    if pgrep -f "jenkins.war" > /dev/null 2>&1; then
        return 0
    fi

    return 1
}

stop_jenkins() {
    log_info "停止Jenkins服务..."

    if [ -f "$JENKINS_PID_FILE" ]; then
        pid=$(cat "$JENKINS_PID_FILE")
        if [ -n "$pid" ]; then
            kill "$pid" 2>/dev/null || true
            sleep 2
            kill -9 "$pid" 2>/dev/null || true
        fi
        rm -f "$JENKINS_PID_FILE"
    fi

    pids=$(pgrep -f "jenkins.war" 2>/dev/null || true)
    if [ -n "$pids" ]; then
        for pid in $pids; do
            kill "$pid" 2>/dev/null || true
        done
        sleep 2
        pids=$(pgrep -f "jenkins.war" 2>/dev/null || true)
        if [ -n "$pids" ]; then
            for pid in $pids; do
                kill -9 "$pid" 2>/dev/null || true
            done
        fi
    fi

    log_info "Jenkins已停止"
}

start_jenkins() {
    log_info "启动Jenkins服务..."

    nohup java -server -jar "$JENKINS_WAR" > /var/log/jenkins.log 2>&1 &
    pid=$!
    echo "$pid" > "$JENKINS_PID_FILE"

    sleep 5

    if is_jenkins_running; then
        log_info "Jenkins启动成功 (PID: $pid)"
    else
        log_error "Jenkins启动失败"
        exit 1
    fi
}

restart_container() {
    log_info "=============================================="
    log_info "Jenkins war 包已更新完成"
    log_warn "需要重启容器才能生效"
    log_info "请执行以下命令重启容器:"
    CONTAINER_NAME=$(hostname)
    log_info "  docker restart $CONTAINER_NAME"
    log_info "=============================================="
}

need_update() {
    current_ver="$1"
    target_ver="$2"

    if [ "$current_ver" = "unknown" ]; then
        return 0
    fi

    if [ "$target_ver" = "unknown" ]; then
        return 1
    fi

    if [ "$current_ver" = "$target_ver" ]; then
        return 1
    fi

    current_major=$(echo "$current_ver" | cut -d. -f1)
    current_minor=$(echo "$current_ver" | cut -d. -f2)
    current_patch=$(echo "$current_ver" | cut -d. -f3)

    target_major=$(echo "$target_ver" | cut -d. -f1)
    target_minor=$(echo "$target_ver" | cut -d. -f2)
    target_patch=$(echo "$target_ver" | cut -d. -f3)

    [ -z "$current_patch" ] && current_patch=0
    [ -z "$target_patch" ] && target_patch=0

    if [ "$current_major" -lt "$target_major" ]; then
        return 0
    elif [ "$current_major" -gt "$target_major" ]; then
        return 1
    fi

    if [ "$current_minor" -lt "$target_minor" ]; then
        return 0
    elif [ "$current_minor" -gt "$target_minor" ]; then
        return 1
    fi

    if [ "$current_patch" -lt "$target_patch" ]; then
        return 0
    fi

    return 1
}

if [ $# -ne 1 ]; then
    log_error "缺少下载URL参数"
    usage
    exit 1
fi

JENKINS_DOWNLOAD_URL="$1"

case "$JENKINS_DOWNLOAD_URL" in
    http://*|https://*) ;;
    *)
    log_error "无效的URL格式: $JENKINS_DOWNLOAD_URL"
    exit 1
    ;;
esac

log_info "开始Jenkins升级检查..."

TARGET_VERSION=$(extract_version_from_url "$JENKINS_DOWNLOAD_URL")
log_info "目标版本: $TARGET_VERSION"

if [ ! -f "$JENKINS_WAR" ]; then
    log_warn "当前目录下未找到 jenkins.war 文件，将直接下载"
    CURRENT_VERSION="unknown"
else
    log_info "检查当前Jenkins版本..."
    CURRENT_VERSION=$(get_current_version)
    log_info "当前版本: $CURRENT_VERSION"
fi

if need_update "$CURRENT_VERSION" "$TARGET_VERSION"; then
    log_info "开始升级Jenkins: $CURRENT_VERSION -> $TARGET_VERSION"
else
    if [ "$CURRENT_VERSION" = "$TARGET_VERSION" ]; then
        log_info "当前版本 ($CURRENT_VERSION) 与目标版本 ($TARGET_VERSION) 相同，无需更新"
    else
        log_info "当前版本 ($CURRENT_VERSION) >= 目标版本 ($TARGET_VERSION)，无需更新"
    fi
    exit 0
fi

if [ -f "$JENKINS_WAR" ]; then
    BACKUP_NAME="jenkins.war.backup.${CURRENT_VERSION}"
    log_info "备份现有版本到: $BACKUP_NAME"
    cp "$JENKINS_WAR" "$BACKUP_NAME"
fi

log_info "下载Jenkins $TARGET_VERSION..."
if command -v wget >/dev/null 2>&1; then
    wget -O "${JENKINS_WAR}.new" "$JENKINS_DOWNLOAD_URL"
elif command -v curl >/dev/null 2>&1; then
    curl -L -o "${JENKINS_WAR}.new" "$JENKINS_DOWNLOAD_URL"
else
    log_error "未找到wget或curl命令"
    exit 1
fi

if [ ! -f "${JENKINS_WAR}.new" ] || [ ! -s "${JENKINS_WAR}.new" ]; then
    log_error "下载失败或文件为空"
    exit 1
fi

log_info "验证下载文件版本..."
if command -v java >/dev/null 2>&1; then
    DOWNLOADED_VERSION=$(java -jar "${JENKINS_WAR}.new" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    log_debug "下载文件版本: $DOWNLOADED_VERSION"
fi

log_info "更新jenkins.war..."
mv "${JENKINS_WAR}.new" "$JENKINS_WAR"
chmod 644 "$JENKINS_WAR"

restart_container

log_info "升级完成！"
log_info "版本变更: $CURRENT_VERSION -> $TARGET_VERSION"
if [ -n "$BACKUP_NAME" ]; then
    log_info "备份文件: $BACKUP_NAME"
fi
log_info "Jenkins访问地址: http://localhost:$JENKINS_PORT"
