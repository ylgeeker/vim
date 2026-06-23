#!/usr/bin/env bash

install_node() {
  local major setup_ver
  major="$(node_major_version)"
  if [[ "$major" -ge 18 ]]; then
    ok "Node.js $(node -v) OK"
    return 0
  fi

  setup_ver="${NODE_VERSION}"
  info "Installing Node.js ${setup_ver} LTS..."
  if [[ "$IS_MACOS" -eq 1 ]]; then
    need_cmd brew || die "Homebrew required on macOS"
    brew install "node@${setup_ver}" || brew install node
    local prefix
    prefix="$(brew --prefix "node@${setup_ver}" 2>/dev/null || brew --prefix node)"
    ensure_path_line "export PATH=\"$prefix/bin:\$PATH\""
    npm config set prefix "$HOME/.npm-global" 2>/dev/null || true
    ensure_path_line 'export PATH="$HOME/.npm-global/bin:$PATH"'
  elif [[ "$IS_DEBIAN" -eq 1 ]]; then
    if [[ "$USER_INSTALL" == "1" ]]; then
      die "--user-install: install Node 18+ manually (fnm/nvm)"
    fi
    run_as_root bash -c "curl -fsSL https://deb.nodesource.com/setup_${setup_ver}.x | bash -" || true
    run_as_root apt-get install -y nodejs || die "Failed to install nodejs"
  elif [[ "$IS_RHEL" -eq 1 ]]; then
    if [[ "$USER_INSTALL" == "1" ]]; then
      die "--user-install: install Node 18+ manually"
    fi
    run_as_root bash -c "curl -fsSL https://rpm.nodesource.com/setup_${setup_ver}.x | bash -" || true
    run_as_root "$PKG_MGR" install -y nodejs || die "Failed to install nodejs"
  fi

  major="$(node_major_version)"
  [[ "$major" -ge 18 ]] || die "Node.js >= 18 required (got $(node -v 2>/dev/null || echo none))"
  ok "Node.js $(node -v)"
}
