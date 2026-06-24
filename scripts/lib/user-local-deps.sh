#!/usr/bin/env bash
# User-local (~/.local) dependency installs for --user-install and package-manager fallbacks.

user_local_bin() {
  printf '%s' "$HOME/.local/bin"
}

resolve_node_release() {
  local major="${NODE_VERSION:-20}" ver=""
  if need_cmd curl; then
    ver="$(curl -fsSL https://nodejs.org/dist/index.json 2>/dev/null | \
      grep -o "\"version\":\"v${major}\.[0-9]*\.[0-9]*\"" | head -1 | \
      sed 's/.*"v\([^"]*\)".*/\1/')"
  fi
  [[ -n "$ver" ]] || ver="${major}.19.0"
  printf '%s' "$ver"
}

normalize_node_arch() {
  case "$(normalize_go_arch)" in
    amd64) printf '%s' 'x64' ;;
    arm64) printf '%s' 'arm64' ;;
    *) printf '%s' "$(normalize_go_arch)" ;;
  esac
}

resolve_clangd_release() {
  local ver="${CLANGD_VERSION:-}"
  if [[ -z "$ver" ]] && need_cmd curl; then
    ver="$(curl -fsSL https://api.github.com/repos/clangd/clangd/releases/latest 2>/dev/null | \
      sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  fi
  [[ -n "$ver" ]] || ver="19.1.2"
  printf '%s' "$ver"
}

_extract_zip() {
  local zip="$1" dest="$2"
  mkdir -p "$dest"
  if command -v unzip &>/dev/null; then
    unzip -qo "$zip" -d "$dest"
    return 0
  fi
  if command -v python3 &>/dev/null; then
    python3 - "$zip" "$dest" <<'PY'
import sys, zipfile
zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])
PY
    return 0
  fi
  warn "Need unzip or python3 to extract $zip"
  return 1
}

linux_user_can_build() {
  command -v make &>/dev/null && { command -v gcc &>/dev/null || command -v cc &>/dev/null; }
}

install_node_user_local() {
  local ver arch tarball extracted dir url build_root
  ver="$(resolve_node_release)"
  arch="$(normalize_node_arch)"
  tarball="node-v${ver}-linux-${arch}.tar.gz"
  build_root="${INSTALL_ROOT}/node"
  mkdir -p "$build_root"
  url="https://nodejs.org/dist/v${ver}/${tarball}"
  info "Installing Node.js v${ver} to ~/.local/node..."
  download "$url" "$build_root/${tarball}" || die "Node.js download failed ($url)"
  rm -rf "$HOME/.local/node"
  tar -xzf "$build_root/${tarball}" -C "$HOME/.local"
  extracted="$(find "$HOME/.local" -maxdepth 1 -type d -name "node-v${ver}-linux-${arch}" | head -1)"
  [[ -n "$extracted" ]] || die "Node.js extract failed"
  mv "$extracted" "$HOME/.local/node"
  ensure_path_line 'export PATH="$HOME/.local/node/bin:$PATH"'
  export PATH="$HOME/.local/node/bin:$PATH"
  npm config set prefix "$HOME/.npm-global" 2>/dev/null || true
  ensure_path_line 'export PATH="$HOME/.npm-global/bin:$PATH"'
  ok "Node.js $(node -v) (~/.local/node)"
}

install_clangd_user_local() {
  [[ "$IS_MACOS" -eq 1 ]] && return 1
  local version arch asset zip url build_root extract_root bindir
  version="$(resolve_clangd_release)"
  arch="$(normalize_go_arch)"
  if [[ "$arch" == "amd64" ]]; then
    asset="clangd-linux-${version}.zip"
  else
    asset="clangd-linux-${arch}-${version}.zip"
  fi
  build_root="${INSTALL_ROOT}/clangd"
  mkdir -p "$build_root"
  zip="$build_root/${asset}"
  url="https://github.com/clangd/clangd/releases/download/${version}/${asset}"
  info "Installing clangd ${version} to ~/.local/clangd..."
  download "$url" "$zip" || { warn "clangd download failed ($url)"; return 1; }
  extract_root="$build_root/extract"
  rm -rf "$extract_root" "$HOME/.local/clangd"
  _extract_zip "$zip" "$extract_root" || return 1
  bindir="$(find "$extract_root" -type f -name clangd -perm -111 2>/dev/null | head -1)"
  [[ -n "$bindir" ]] || { warn "clangd binary not found in ${asset}"; return 1; }
  mkdir -p "$HOME/.local/clangd/bin"
  cp -f "$bindir" "$HOME/.local/clangd/bin/clangd"
  chmod +x "$HOME/.local/clangd/bin/clangd"
  ensure_path_line 'export PATH="$HOME/.local/clangd/bin:$PATH"'
  export PATH="$HOME/.local/clangd/bin:$PATH"
  ok "clangd $(first_line "$HOME/.local/clangd/bin/clangd" --version)"
}

install_nasm_user_local() {
  [[ "$IS_MACOS" -eq 1 ]] && return 1
  local version="${NASM_VERSION:-2.16.03}" build_root src_dir
  if command -v nasm &>/dev/null; then
    return 0
  fi
  if ! linux_user_can_build; then
    warn "nasm: need make and gcc/cc to build from source (~/.local)"
    return 1
  fi
  build_root="${INSTALL_ROOT}/nasm-src"
  src_dir="$build_root/nasm-${version}"
  info "Building nasm ${version} for ~/.local..."
  mkdir -p "$build_root"
  if [[ ! -f "$src_dir/configure" ]]; then
    download "https://www.nasm.us/pub/nasm/releasebuilds/${version}/nasm-${version}.tar.gz" \
      "$build_root/nasm-${version}.tar.gz" || { warn "nasm source download failed"; return 1; }
    tar -xzf "$build_root/nasm-${version}.tar.gz" -C "$build_root"
  fi
  (
    cd "$src_dir" && \
    ./configure --prefix="$HOME/.local" && \
    make -j"$(parallel_jobs)" && \
    make install
  ) || { warn "nasm build failed"; return 1; }
  ensure_path_line 'export PATH="$HOME/.local/bin:$PATH"'
  export PATH="$HOME/.local/bin:$PATH"
  command -v nasm &>/dev/null && ok "nasm $(first_line nasm -v)"
}

ensure_linux_user_dependencies() {
  [[ "$IS_MACOS" -eq 1 ]] && return 0
  info "User install: provisioning ~/.local dependencies..."
  ensure_clangd || true
  ensure_nasm || true
  ok "User-local Linux dependencies ready"
}
