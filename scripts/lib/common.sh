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
    export\ GPG_TTY=*)
      export GPG_TTY="${TTY:-$(tty 2>/dev/null || true)}"
      ;;
  esac
}

ensure_gpg_signing() {
  local pinentry gpg_agent_conf
  need_cmd gpg || return 0
  if command -v pinentry-mac &>/dev/null; then
    pinentry="$(command -v pinentry-mac)"
  elif command -v pinentry-tty &>/dev/null; then
    pinentry="$(command -v pinentry-tty)"
  else
    pinentry="$(command -v pinentry 2>/dev/null || true)"
  fi
  gpg_agent_conf="$HOME/.gnupg/gpg-agent.conf"
  mkdir -p "$HOME/.gnupg"
  chmod 700 "$HOME/.gnupg"
  if [[ -n "$pinentry" ]]; then
    cat > "$gpg_agent_conf" <<EOF
default-cache-ttl 34560000
max-cache-ttl 34560000
pinentry-program $pinentry
allow-loopback-pinentry
EOF
    if command -v gpg-connect-agent &>/dev/null; then
      gpg-connect-agent reloadagent /bye &>/dev/null || true
    fi
  else
    warn "pinentry not found; gpg commit signing may fail until pinentry is installed"
  fi
  ensure_path_line 'export GPG_TTY=$(tty)'
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

# coc.nvim requires Node >= 20.19 (global Web Crypto API).
node_has_global_crypto() {
  need_cmd node || return 1
  node -e 'process.exit(typeof globalThis.crypto !== "undefined" ? 0 : 1)' 2>/dev/null
}

go_installed_version() {
  need_cmd go || return 1
  go version 2>/dev/null | sed -n 's/.*go\([0-9]\+\.[0-9]\+\(\.[0-9]\+\)\?\).*/\1/p' | head -1
}

# True when installed Go is >= requested GO_VERSION (e.g. 1.24.2).
go_version_sufficient() {
  local installed="${1:-$(go_installed_version)}"
  local required="${GO_VERSION:-1.24.2}"
  [[ -n "$installed" ]] || return 1
  [[ "$(printf '%s\n' "$required" "$installed" | sort -V | head -1)" == "$required" ]]
}

# Go official tarballs use darwin/linux + amd64/arm64.
normalize_go_arch() {
  case "${1:-$ARCH}" in
    x86_64|amd64) printf '%s' 'amd64' ;;
    aarch64|arm64) printf '%s' 'arm64' ;;
    *) printf '%s' "${1:-$ARCH}" ;;
  esac
}

parallel_jobs() {
  local n
  n="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)"
  [[ -n "$n" && "$n" -gt 0 ]] && printf '%s' "$n" || printf '%s' '2'
}

# Avoid SIGPIPE under pipefail when only the first line of a command is needed.
first_line() {
  local out
  out="$("$@" 2>/dev/null)" || true
  [[ -n "$out" ]] || return 1
  printf '%s' "${out%%$'\n'*}"
}

COC_EXTENSIONS=(coc-clangd coc-go coc-pyright)

coc_data_home() {
  printf '%s' "${XDG_CONFIG_HOME:-$HOME/.config}/coc"
}

coc_ext_modules_dir() {
  printf '%s' "$(coc_data_home)/extensions/node_modules"
}

coc_legacy_ext_modules_dir() {
  printf '%s' "$HOME/.vim/coc/extensions/node_modules"
}

# Print missing extension names (one per line); no output when all are installed.
coc_extensions_missing() {
  local ext dir
  dir="$(coc_ext_modules_dir)"
  for ext in "${COC_EXTENSIONS[@]}"; do
    [[ -d "$dir/$ext" ]] || printf '%s\n' "$ext"
  done
}

nasm_verify_fixture() {
  printf '%s' "${REPO_ROOT:?}/test/fixtures/nasm/smoke.asm"
}

nasm_resolve_fmt() {
  if [[ -n "${NASM_FMT:-}" ]]; then
    printf '%s' "$NASM_FMT"
    return 0
  fi
  case "$(uname -s)" in
    Darwin) printf '%s' 'macho64' ;;
    *) printf '%s' 'elf64' ;;
  esac
}

# Assemble a minimal nop fixture (no repo file dependency; works on elf64 + macho64).
nasm_smoke_compile() {
  local fmt="$1" tmp_asm tmp_o err_out rc
  tmp_asm="$(mktemp "${TMPDIR:-/tmp}/vim-nasm-smoke.XXXXXX.asm")"
  tmp_o="$(mktemp "${TMPDIR:-/tmp}/vim-nasm-smoke.XXXXXX.o")"
  err_out="$(mktemp "${TMPDIR:-/tmp}/vim-nasm-smoke.XXXXXX.log")"
  cat > "$tmp_asm" <<'EOF'
section .text
    nop
EOF
  set +e
  nasm -f "$fmt" "$tmp_asm" -o "$tmp_o" >"$err_out" 2>&1
  rc=$?
  set -e
  if [[ "$rc" -ne 0 && -s "$err_out" ]]; then
    warn "nasm -f ${fmt}: $(tail -1 "$err_out")"
  fi
  rm -f "$tmp_asm" "$tmp_o" "$err_out"
  return "$rc"
}
