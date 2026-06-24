#!/usr/bin/env bash

install_go() {
  if command -v go &>/dev/null && go_version_sufficient; then
    ok "Go $(go version)"
    return 0
  fi
  if command -v go &>/dev/null; then
    local installed_ver
    installed_ver="$(go_installed_version)"
    if [[ -n "$installed_ver" ]]; then
      warn "Go ${installed_ver} is older than ${GO_VERSION}; upgrading..."
    else
      warn "Go present but version unreadable; installing ${GO_VERSION}..."
    fi
  else
    info "Installing Go ${GO_VERSION}..."
  fi
  local goos goarch tar url build_root
  goos="$(uname -s | tr '[:upper:]' '[:lower:]')"
  [[ "$goos" == "darwin" ]] && goos="darwin" || goos="linux"
  goarch="$(normalize_go_arch)"
  tar="go${GO_VERSION}.${goos}-${goarch}.tar.gz"
  build_root="$INSTALL_ROOT"
  mkdir -p "$build_root"
  url="https://dl.google.com/go/${tar}"
  download "$url" "$build_root/$tar" || die "Go download failed"
  if [[ "$USER_INSTALL" == "1" ]] || [[ "$IS_MACOS" -eq 1 ]]; then
    rm -rf "$HOME/.local/go"
    tar -C "$HOME/.local" -xzf "$build_root/$tar"
    ensure_path_line 'export PATH="$HOME/.local/go/bin:$PATH"'
    export PATH="$HOME/.local/go/bin:$PATH"
  else
    run_as_root rm -rf /usr/local/go
    run_as_root tar -C /usr/local -xzf "$build_root/$tar"
    ensure_path_line 'export PATH="/usr/local/go/bin:$PATH"'
    export PATH="/usr/local/go/bin:$PATH"
  fi
  go_version_sufficient || die "Go upgrade failed (got $(go_installed_version), need >= ${GO_VERSION})"
  ok "Go $(go version)"
}

install_gopls() {
  install_go
  export PATH="${HOME}/go/bin:/usr/local/go/bin:${HOME}/.local/go/bin:$PATH"
  if command -v gopls &>/dev/null; then
    info "Ensuring gopls is up to date..."
  else
    info "Installing gopls..."
  fi
  go install golang.org/x/tools/gopls@latest || warn "gopls install failed (install Go module manually)"
  command -v gopls &>/dev/null && ensure_path_line 'export PATH="$HOME/go/bin:$PATH"'
  if command -v gopls &>/dev/null; then
    ok "gopls $(first_line gopls version)"
  else
    warn "gopls not available"
    return 1
  fi
}

install_ctags() {
  if command -v ctags &>/dev/null && ctags --version 2>/dev/null | grep -qi universal; then
    ok "ctags: $(first_line ctags --version)"
    return 0
  fi
  if [[ "$IS_MACOS" -eq 1 ]]; then
    _ensure_brew_formula universal-ctags 2>/dev/null || true
    command -v ctags &>/dev/null && ok "ctags installed" && return 0
  fi
  ensure_build_deps
  info "Building universal-ctags..."
  local build_root="$INSTALL_ROOT"
  rm -rf "$build_root/ctags"
  git clone --depth 1 https://github.com/universal-ctags/ctags.git "$build_root/ctags"
  (
    cd "$build_root/ctags" && ./autogen.sh && ./configure && make -j"$(parallel_jobs)"
  ) || { warn "ctags build failed; NASM tag jump may be limited"; return 1; }
  if [[ "$USER_INSTALL" == "1" ]]; then
    make -C "$build_root/ctags" install prefix="$HOME/.local"
  else
    run_as_root make -C "$build_root/ctags" install || { warn "ctags install failed"; return 1; }
  fi
  ok "universal-ctags installed"
}

install_fzf() {
  command -v fzf &>/dev/null && return 0
  need_cmd git || die "git required for fzf install"
  info "Installing fzf..."
  rm -rf "$HOME/.fzf"
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --all --no-update-rc --no-bash --no-fish --no-zsh || warn "fzf install failed"
  command -v fzf &>/dev/null && ok "fzf installed"
}

install_lsp_stack() {
  ensure_clangd || true
  ensure_nasm || true
  install_gopls || true
  install_ctags || true
  install_fzf || true
  command -v clangd &>/dev/null || warn "clangd not in PATH"
  command -v nasm &>/dev/null || warn "nasm not in PATH"
  ok "LSP/toolchain step done"
}

resolve_clangd_path() {
  if [[ -x "$HOME/.local/clangd/bin/clangd" ]]; then
    echo "$HOME/.local/clangd/bin/clangd"
    return
  fi
  if [[ "$IS_MACOS" -eq 1 ]] && command -v brew &>/dev/null; then
    local p
    p="$(brew --prefix llvm 2>/dev/null)/bin/clangd"
    [[ -x "$p" ]] && echo "$p" && return
  fi
  command -v clangd 2>/dev/null || echo "clangd"
}

resolve_gopls_path() {
  if [[ -x "$HOME/go/bin/gopls" ]]; then
    echo "$HOME/go/bin/gopls"
  else
    command -v gopls 2>/dev/null || echo "$HOME/go/bin/gopls"
  fi
}
