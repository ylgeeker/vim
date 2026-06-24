#!/usr/bin/env bash

install_node() {
  local major setup_ver
  setup_ver="${NODE_VERSION}"
  major="$(node_major_version)"
  if [[ "$major" -ge 20 ]] && node_has_global_crypto; then
    ok "Node.js $(node -v) OK"
    return 0
  fi
  if [[ "$major" -ge 18 ]]; then
    warn "Node.js $(node -v) is too old for coc.nvim (requires >= 20); upgrading to ${setup_ver}..."
  fi

  info "Installing Node.js ${setup_ver} LTS..."
  if [[ "$IS_MACOS" -eq 1 ]]; then
    need_cmd brew || die "Homebrew required on macOS"
    brew install "node@${setup_ver}" || brew install node
    local prefix
    prefix="$(brew --prefix "node@${setup_ver}" 2>/dev/null || brew --prefix node)"
    ensure_path_line "export PATH=\"$prefix/bin:\$PATH\""
    npm config set prefix "$HOME/.npm-global" 2>/dev/null || true
    ensure_path_line 'export PATH="$HOME/.npm-global/bin:$PATH"'
  elif [[ "$USER_INSTALL" == "1" ]] || [[ "$IS_DEBIAN" -ne 1 && "$IS_RHEL" -ne 1 ]]; then
    install_node_user_local || die "Failed to install Node.js to ~/.local"
  elif [[ "$IS_DEBIAN" -eq 1 ]]; then
    run_as_root bash -c "curl -fsSL https://deb.nodesource.com/setup_${setup_ver}.x | bash -" || true
    run_as_root apt-get install -y nodejs || die "Failed to install nodejs"
  elif [[ "$IS_RHEL" -eq 1 ]]; then
    run_as_root bash -c "curl -fsSL https://rpm.nodesource.com/setup_${setup_ver}.x | bash -" || true
    run_as_root "$PKG_MGR" install -y nodejs || die "Failed to install nodejs"
  fi

  major="$(node_major_version)"
  [[ "$major" -ge 20 ]] || die "Node.js >= 20 required for coc.nvim (got $(node -v 2>/dev/null || echo none))"
  node_has_global_crypto || die "Node.js $(node -v) missing global crypto; use Node >= 20.19"
  ok "Node.js $(node -v)"
}
