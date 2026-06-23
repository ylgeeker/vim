#!/usr/bin/env bash

vim_major_version() {
  local line
  line="$(first_line vim --version)" || return 0
  sed -n 's/.*IMproved \([0-9]\+\).*/\1/p' <<<"$line"
}

install_vim() {
  local major
  major="$(vim_major_version)"
  if [[ -n "$major" && "$major" -ge 9 ]]; then
    ok "Vim $(first_line vim --version)"
    return 0
  fi

  if [[ "$IS_MACOS" -eq 1 ]]; then
    brew install vim
    ok "Vim $(first_line vim --version)"
    return 0
  fi

  if [[ "$USER_INSTALL" != "1" && "$IS_DEBIAN" -eq 1 ]]; then
    run_as_root apt-get install -y vim 2>/dev/null || true
    major="$(vim_major_version)"
    [[ -n "$major" && "$major" -ge 9 ]] && { ok "Vim from packages"; return 0; }
  fi

  info "Building Vim 9 from source..."
  local build_root="$INSTALL_ROOT"
  mkdir -p "$build_root"
  if [[ ! -d "$build_root/vim-src" ]]; then
    git clone --depth 1 https://github.com/vim/vim.git "$build_root/vim-src"
  fi
  local prefix="${INSTALL_PREFIX:-/usr/local}"
  if [[ "$USER_INSTALL" == "1" ]]; then
    prefix="$HOME/.local"
    mkdir -p "$prefix/bin"
    ensure_path_line 'export PATH="$HOME/.local/bin:$PATH"'
  fi
  (
    cd "$build_root/vim-src/src" && \
    ./configure --prefix="$prefix" --enable-cscope --enable-fontset \
      --enable-python3interp=yes \
      --with-python3-config-dir="$(python3-config --configdir 2>/dev/null || echo "")" && \
    make -j"$(nproc 2>/dev/null || echo 2)"
  ) || die "Vim build failed (see log)"
  if [[ "$USER_INSTALL" == "1" ]]; then
    make -C "$build_root/vim-src/src" install
  else
    run_as_root make -C "$build_root/vim-src/src" install || die "Vim install failed"
  fi
  ok "Vim $(first_line vim --version)"
}
