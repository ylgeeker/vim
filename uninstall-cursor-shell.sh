#!/usr/bin/env bash
# 从 shell 中卸载 Cursor CLI（移除 "Install 'cursor' to shell" 添加的 PATH/配置）
# 用法: ./uninstall-cursor-shell.sh

set -e

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERR]${NC} $*"; }

changed=0

# 从 rc 文件中移除 Cursor 的 PATH 行（Install 'cursor' to shell 添加的通常是 export PATH=...cursor...）
remove_from_rc() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0
  if grep -qE 'export PATH=.*[cC]ursor|PATH=.*[cC]ursor' "$file" 2>/dev/null; then
    cp -a "$file" "${file}.bak.cursor.$(date +%Y%m%d%H%M%S)"
    sed '/export PATH=.*[cC]ursor/d; /^PATH=.*[cC]ursor/d' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    changed=1
    info "已从 $file 移除 Cursor PATH 行（备份: ${file}.bak.cursor.*）"
  fi
}

remove_from_rc "$HOME/.bashrc"
remove_from_rc "$HOME/.zshrc"
[[ -f "$HOME/.profile" ]] && remove_from_rc "$HOME/.profile"

# 移除常见 symlink，使 which cursor 不再找到
for path in /usr/local/bin/cursor "$HOME/.local/bin/cursor"; do
  if [[ -L "$path" ]] && readlink -f "$path" 2>/dev/null | grep -qi cursor; then
    rm -f "$path"
    info "已删除符号链接: $path"
    changed=1
  fi
done

if [[ "$changed" -eq 0 ]]; then
  warn "未在 .bashrc/.zshrc/.profile 或常见路径中发现 Cursor 配置；可能未安装或已卸载。"
  echo "若仍存在 cursor 命令，请用: which cursor 查看路径，并手动从对应 rc 文件删除相关 export PATH 行。"
else
  info "请执行 source ~/.bashrc 或 source ~/.zshrc（或重新打开终端）使更改生效。"
fi
