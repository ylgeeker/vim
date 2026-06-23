#!/usr/bin/env bash

install_cursor_stack() {
  local build_root="$INSTALL_ROOT"
  mkdir -p "$build_root"

  if ! command -v cursor &>/dev/null; then
    if [[ "$IS_MACOS" -eq 1 ]]; then
      brew install --cask cursor 2>/dev/null || warn "Install Cursor from https://cursor.com/download"
    else
      local arch="x64"
      [[ "$ARCH" == "aarch64" ]] && arch="arm64"
      if command -v dpkg &>/dev/null; then
        local deb="$build_root/cursor.deb"
        download "https://api2.cursor.sh/updates/download/golden/linux-${arch}-deb/cursor/2.4" "$deb" 2>/dev/null || true
        [[ -f "$deb" ]] && run_as_root dpkg -i "$deb" 2>/dev/null || run_as_root apt-get install -f -y
      elif command -v rpm &>/dev/null; then
        local rpm="$build_root/cursor.rpm"
        download "https://api2.cursor.sh/updates/download/golden/linux-${arch}-rpm/cursor/2.4" "$rpm" 2>/dev/null || true
        [[ -f "$rpm" ]] && run_as_root rpm -i "$rpm" 2>/dev/null || true
      fi
      for p in /usr/share/cursor/bin/cursor /opt/Cursor/cursor; do
        [[ -x "$p" ]] && run_as_root ln -sf "$p" /usr/local/bin/cursor 2>/dev/null && break
      done
    fi
  fi
  command -v cursor &>/dev/null && ok "cursor CLI available" || warn "cursor not in PATH"

  ensure_path_line 'export PATH="$HOME/.local/bin:$PATH"'
  if ! command -v agent &>/dev/null; then
    (curl -fsSL https://cursor.com/install-fsS | bash) || warn "Cursor agent CLI install failed"
  fi
  command -v agent &>/dev/null && ok "agent CLI available" || warn "agent not in PATH"
}
