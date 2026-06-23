#!/usr/bin/env bash

install_deps_macos() {
  need_cmd brew || die "Install Homebrew: https://brew.sh"
  xcode-select -p &>/dev/null || xcode-select --install 2>/dev/null || warn "Xcode CLT may be required"

  brew install git curl wget make cmake python3 llvm nasm ripgrep universal-ctags vim neovim zsh
  local llvm_prefix
  llvm_prefix="$(brew --prefix llvm)"
  ensure_path_line "export PATH=\"$llvm_prefix/bin:\$PATH\""
  ok "macOS dependencies installed"
}
