#!/usr/bin/env bash
# Shared helpers for install scripts.

reset_tty_line() {
  printf '\r\033[K'
}

ensure_output_newline() {
  reset_tty_line
  printf '\n'
}

run_with_timeout() {
  local secs="$1"
  shift
  if command -v timeout &>/dev/null; then
    timeout "$secs" "$@"
  else
    warn "timeout not found; running without time limit"
    "$@"
  fi
}

_print_status() {
  reset_tty_line
  printf '%b\n' "$1"
}

info()  { _print_status "\033[34;1m[INFO]\033[0m $*"; }
ok()    { _print_status "\033[32;1m[OK]\033[0m $*"; }
warn()  { _print_status "\033[33;1m[WARN]\033[0m $*"; }
err()   { _print_status "\033[31;1m[ERR]\033[0m $*"; }
die()   { err "$*"; exit 1; }

STAGE_START=$SECONDS
stage_begin() {
  STAGE_START=$SECONDS
  info "==> $*"
}
stage_end() {
  local elapsed=$((SECONDS - STAGE_START))
  ensure_output_newline
  ok "$1 (${elapsed}s)"
}

run_as_root() {
  if [[ "$USER_INSTALL" == "1" ]]; then
    return 1
  fi
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo &>/dev/null; then
    sudo "$@"
  else
    return 1
  fi
}

ensure_path_line() {
  local line="$1"
  local file
  for file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [[ -f "$file" ]] || continue
    grep -qF "$line" "$file" 2>/dev/null && continue
    echo "$line" >> "$file"
  done
  case "$line" in
    export\ PATH=*)
      local dir="${line#export PATH=}"
      dir="${dir%%:\$PATH*}"
      dir="${dir#\"}"
      dir="${dir%\"}"
      export PATH="$dir:$PATH"
      ;;
  esac
}

download() {
  local url="$1" dest="$2"
  if command -v curl &>/dev/null; then
    curl -fsSL -o "$dest" "$url"
  elif command -v wget &>/dev/null; then
    wget -q -O "$dest" "$url"
  else
    die "Need curl or wget to download $url"
  fi
}

need_cmd() {
  command -v "$1" &>/dev/null
}

node_major_version() {
  need_cmd node || echo 0
  node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0
}

# Avoid SIGPIPE under pipefail when only the first line of a command is needed.
first_line() {
  local out
  out="$("$@" 2>/dev/null)" || true
  [[ -n "$out" ]] || return 1
  printf '%s' "${out%%$'\n'*}"
}
