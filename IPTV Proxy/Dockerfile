# syntax=docker/dockerfile:1
# IPTV Proxy 多架构镜像（amd64 / arm64 / armv7）
# 仓库自带三个平台的预编译二进制，这里按目标平台挑选，不做交叉编译。

FROM alpine:3.22 AS artifacts
ARG TARGETARCH
ARG TARGETVARIANT
WORKDIR /src
COPY . .
RUN set -eux; \
    case "${TARGETARCH}${TARGETVARIANT}" in \
      amd64)  BIN=iptv-proxy-linux-amd64 ;; \
      arm64)  BIN=iptv-proxy-linux-arm64 ;; \
      armv7)  BIN=iptv-proxy-linux-armv7 ;; \
      *) echo "unsupported arch: ${TARGETARCH}${TARGETVARIANT}" >&2; exit 1 ;; \
    esac; \
    test -f "${BIN}"; \
    install -m 0755 "${BIN}" /out-iptv-proxy

FROM alpine:3.22
RUN apk add --no-cache \
        ca-certificates \
        tzdata \
        ffmpeg \
        python3 \
        py3-pip \
        py3-requests

COPY --from=artifacts /out-iptv-proxy /usr/local/bin/iptv-proxy
COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/iptv-proxy /entrypoint.sh

# 配置、缓存、数据和录制文件都落在这里
WORKDIR /data
VOLUME ["/data"]
EXPOSE 19899

# 首次启动按环境变量生成 config.toml；之后以面板里的设置为准
ENTRYPOINT ["/entrypoint.sh"]
