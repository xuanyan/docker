#!/usr/bin/env bash
set -euo pipefail

# 在 docker 仓库根目录执行 buildx（与 Dockerfile 中 COPY aria2/... 一致）
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKERFILE="$ROOT/aria2/Dockerfile"
TAG="xuanyan/aria2:latest"

cd "$ROOT"

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f "$DOCKERFILE" \
  -t "$TAG" \
  --push \
  "$ROOT"
