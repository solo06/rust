#!/bin/sh
# 容器入口：首次启动按环境变量生成 config.toml，之后复用已存在的配置。
# 程序本身不读环境变量，密码以 SHA-256 落盘，所以这里负责把变量翻译成配置。

set -eu

CFG="${CONFIG_PATH:-/data/config.toml}"
USER_NAME="${PANEL_USERNAME:-admin}"
PASS="${PANEL_PASSWORD:-admin}"
PORT="${PANEL_PORT:-19899}"
TZ_OFF="${TIMEZONE_OFFSET_HOURS:-8}"

mkdir -p "$(dirname "$CFG")"

need_write=0
[ -f "$CFG" ] || need_write=1
[ "${FORCE_PANEL_CREDENTIALS:-false}" = "true" ] && need_write=1

if [ "$need_write" = "1" ]; then
  HASH="$(printf '%s' "$PASS" | sha256sum | awk '{print $1}')"
  cat > "$CFG" <<TOML
# 由容器入口脚本根据环境变量生成。
# 在面板里保存后，程序会把本文件改写成完整配置，此后以文件为准。
[server]
bind = "0.0.0.0:${PORT}"
timezone_offset_hours = ${TZ_OFF}
log_level = "info"
edge_mode = "${EDGE_MODE:-off}"

[panel]
enabled         = true
username        = "${USER_NAME}"
password_sha256 = "${HASH}"
session_ttl     = 86400

[cache]
backend             = "disk"
disk_path           = "./cache"
m3u8_max_entries    = 500
segment_max_entries = 2000
disk_max_mb         = 0

[auth]
token_enabled = false
TOML
  chmod 600 "$CFG"
  echo "[entrypoint] 已生成 $CFG（用户 ${USER_NAME}，端口 ${PORT}）"
else
  echo "[entrypoint] 复用已有 $CFG"
fi

exec /usr/local/bin/iptv-proxy "$CFG"
