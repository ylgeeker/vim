#!/usr/bin/env bash

install_deps_macos() {
  if [[ "$SYSTEM_UPGRADE" != "1" ]]; then
    info "Skipping Homebrew dependency install (use --system-upgrade to install/upgrade system dependencies)"
    ok "macOS dependencies skipped"
    return 0
  fi
  need_cmd brew || die "Install Homebrew: https://brew.sh"
  if ! xcode-select -p &>/dev/null; then
    if [[ -t 0 ]]; then
      xcode-select --install 2>/dev/null || warn "Xcode CLT install may need manual confirmation"
    else
      warn "Xcode CLT not installed (non-TTY install); run: xcode-select --install"
    fi
  fi

  info "Refreshing Homebrew (--system-upgrade)..."
  brew update || warn "brew update failed; continuing with dependency install"

  brew install git curl wget make cmake python3 llvm nasm ripgrep universal-ctags vim neovim zsh gnupg pinentry pinentry-mac
  local llvm_prefix
  llvm_prefix="$(brew --prefix llvm)"
  ensure_path_line "export PATH=\"$llvm_prefix/bin:\$PATH\""
  ok "macOS dependencies installed"
}
