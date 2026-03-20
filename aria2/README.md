# aria2 Docker (magnet/DHT)

## Pull image

```bash
docker pull xuanyan/aria2:latest
```

## Run (amd64 + arm64)

> Magnet / BT / DHT 需要 UDP 端口映射。请确保 `51413/udp` 对外可达。

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

## RPC endpoint (optional)

- Address: `http://<host>:6800/jsonrpc`

