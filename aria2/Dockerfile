FROM alpine:3.19

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 使用发行版 aria2（含 BitTorrent / 磁力）。downkyi 静态包编译时带 --disable-bittorrent，无法识别 magnet: 协议。
RUN apk add --no-cache ca-certificates tzdata \
    --repository=https://dl-cdn.alpinelinux.org/alpine/v3.19/community \
    aria2

RUN mkdir -p /downloads /root/.aria2 && \
    touch /root/.aria2/aria2.session

# dht.dat 等由 aria2 在运行时自动生成；如需保留 DHT 表可挂载 /root/.aria2
COPY aria2/aria2.conf /root/.aria2/aria2.conf

EXPOSE 6800 51413/tcp 51413/udp

ENTRYPOINT ["aria2c", "--conf-path=/root/.aria2/aria2.conf"]
