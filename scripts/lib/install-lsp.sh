#!/usr/bin/env bash

install_go() {
  command -v go &>/dev/null && return 0
  info "Installing Go ${GO_VERSION}..."
  local goos goarch tar url build_root
  goos="$(uname -s | tr '[:upper:]' '[:lower:]')"
  [[ "$goos" == "darwin" ]] && goos="darwin" || goos="linux"
  goarch="$ARCH"
  [[ "$goarch" == "x86_64" ]] && goarch="amd64"
  tar="go${GO_VERSION}.${goos}-${goarch}.tar.gz"
  build_root="$INSTALL_ROOT"
  mkdir -p "$build_root"
  url="https://dl.google.com/go/${tar}"
  download "$url" "$build_root/$tar" || die "Go download failed"
  if [[ "$USER_INSTALL" == "1" ]]; then
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
  ok "Go $(go version)"
}

install_gopls() {
  if command -v gopls &>/dev/null; then
    ok "gopls $(first_line gopls version)"
    return 0
  fi
  install_go
  export PATH="${HOME}/go/bin:/usr/local/go/bin:${HOME}/.local/go/bin:$PATH"
  go install golang.org/x/tools/gopls@latest || warn "gopls install failed (install Go module manually)"
  command -v gopls &>/dev/null && ensure_path_line 'export PATH="$HOME/go/bin:$PATH"'
  command -v gopls &>/dev/null && ok "gopls $(first_line gopls version)" || warn "gopls not available"
}

install_ctags() {
  if command -v ctags &>/dev/null && ctags --version 2>/dev/null | grep -qi universal; then
    ok "ctags: $(first_line ctags --version)"
    return 0
  fi
  if [[ "$IS_MACOS" -eq 1 ]]; then
    brew install universal-ctags 2>/dev/null || true
    command -v ctags &>/dev/null && ok "ctags installed" && return 0
  fi
  info "Building universal-ctags..."
  local build_root="$INSTALL_ROOT"
  rm -rf "$build_root/ctags"
  git clone --depth 1 https://github.com/universal-ctags/ctags.git "$build_root/ctags"
  (
    cd "$build_root/ctags" && ./autogen.sh && ./configure && make -j"$(nproc 2>/dev/null || echo 2)"
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
  info "Installing fzf..."
  rm -rf "$HOME/.fzf"
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --all <<< "y" || warn "fzf install failed"
  command -v fzf &>/dev/null && ok "fzf installed"
}

install_lsp_stack() {
  install_gopls
  install_ctags || true
  install_fzf || true
  command -v clangd &>/dev/null || warn "clangd not in PATH"
  command -v nasm &>/dev/null || warn "nasm not in PATH"
  ok "LSP/toolchain step done"
}

resolve_clangd_path() {
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
