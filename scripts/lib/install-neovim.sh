#!/usr/bin/env bash

install_neovim() {
  if command -v nvim &>/dev/null; then
    ok "Neovim $(first_line nvim --version)"
    return 0
  fi

  if [[ "$IS_MACOS" -eq 1 ]]; then
    brew install neovim
  elif [[ "$IS_DEBIAN" -eq 1 && "$USER_INSTALL" != "1" ]]; then
    run_as_root apt-get install -y neovim 2>/dev/null || true
  elif [[ "$IS_RHEL" -eq 1 && "$USER_INSTALL" != "1" ]]; then
    run_as_root "$PKG_MGR" install -y neovim 2>/dev/null || true
  fi

  command -v nvim &>/dev/null && ok "Neovim installed" || warn "Neovim not installed (optional; Vim still works)"
}
