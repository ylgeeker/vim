#!/usr/bin/env bash

install_deps_macos() {
  if ! xcode-select -p &>/dev/null; then
    if [[ -t 0 ]]; then
      xcode-select --install 2>/dev/null || warn "Xcode CLT install may need manual confirmation"
    else
      warn "Xcode CLT not installed (non-TTY install); run: xcode-select --install"
    fi
  fi
  if [[ "$SYSTEM_UPGRADE" == "1" ]]; then
    need_cmd brew || die "Install Homebrew: https://brew.sh"
    info "Refreshing Homebrew (--system-upgrade)..."
    brew update || warn "brew update failed; continuing with dependency install"
  fi
  ensure_macos_packages
  if [[ "$SYSTEM_UPGRADE" == "1" ]]; then
    _ensure_brew_formula universal-ctags || true
    _ensure_brew_formula vim || true
    _ensure_brew_formula neovim || true
    _ensure_brew_formula zsh || true
    _ensure_brew_formula gnupg || true
    _ensure_brew_formula pinentry-mac || true
  fi
  ok "macOS dependencies ready"
}
