FROM alpine:3.19

ARG TARGETPLATFORM

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apk add --no-cache ca-certificates tzdata wget unzip && \
    case "$TARGETPLATFORM" in \
        linux/amd64) aria2_arch="x86_64" ;; \
        linux/arm64) aria2_arch="aarch64" ;; \
        *) echo "Unsupported architecture: $TARGETPLATFORM" && exit 1 ;; \
    esac && \
    wget -q -O /tmp/aria2.zip \
    https://github.com/yaobiao131/downkyi-aria2-static-build/releases/download/1.37.0/aria2-${aria2_arch}-linux-musl_static.zip && \
    unzip -o /tmp/aria2.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/aria2c && \
    rm /tmp/aria2.zip

RUN mkdir -p /downloads /root/.aria2 && \
    touch /root/.aria2/aria2.session

# 使用仓库里的完整配置文件（便于 magnet/DHT/BT 参数生效）
COPY aria2/aria2.conf /root/.aria2/aria2.conf

EXPOSE 6800 51413/tcp 51413/udp

ENTRYPOINT ["aria2c", "--conf-path=/root/.aria2/aria2.conf"]
