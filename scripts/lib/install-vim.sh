#!/usr/bin/env bash

vim_major_version() {
  local line
  line="$(first_line vim --version)" || return 0
  sed -n 's/.*IMproved \([0-9]\+\).*/\1/p' <<<"$line"
}

vim_python3_works() {
  local out
  out="$(vim --not-a-term -c 'py3 import sys' -c 'qa!' 2>&1)" || true
  ! grep -qE 'E263|E370|无法加载|can.t load Python|not available' <<<"$out"
}

vim_python3_brew_formula() {
  local formula
  formula="$(vim --version 2>/dev/null | sed -n 's/.*opt\/\(python@[0-9.]*\)\/.*/\1/p' | head -1)"
  [[ -n "$formula" ]] || formula="python@3.14"
  printf '%s' "$formula"
}

ensure_vim_python3_runtime() {
  command -v vim &>/dev/null || return 0
  if ! vim --version 2>&1 | grep -q '+python3'; then
    warn "Vim lacks +python3; UltiSnips will not work"
    return 0
  fi
  if vim_python3_works; then
    ok "Vim Python3 runtime OK"
    return 0
  fi

  local formula
  formula="$(vim_python3_brew_formula)"

  if [[ "$IS_MACOS" -eq 1 ]] && command -v brew &>/dev/null; then
    warn "Vim +python3/dyn cannot load (install ${formula} for UltiSnips)"
    info "Installing ${formula}..."
    brew install "$formula" || warn "brew install ${formula} failed"
  elif [[ "$IS_DEBIAN" -eq 1 ]] || [[ "$IS_RHEL" -eq 1 ]]; then
    warn "Vim cannot load Python3; installing Python build deps..."
    ensure_python3_build_deps
    if [[ "$IS_DEBIAN" -eq 1 ]]; then
      run_as_root apt-get install -y vim 2>/dev/null || true
    elif [[ "$IS_RHEL" -eq 1 ]]; then
      run_as_root "${PKG_MGR:-dnf}" install -y vim 2>/dev/null || true
    fi
  else
    warn "Vim cannot load Python3; UltiSnips disabled until Python runtime is fixed"
    return 0
  fi

  if vim_python3_works; then
    ok "Vim Python3 runtime OK"
  else
    warn "Vim still cannot load Python3 (UltiSnips will show a warning)"
  fi
}

install_vim() {
  local major
  major="$(vim_major_version)"
  if [[ -n "$major" && "$major" -ge 9 ]]; then
    ok "Vim $(first_line vim --version)"
    ensure_vim_python3_runtime
    return 0
  fi

  if [[ "$IS_MACOS" -eq 1 ]]; then
    brew install vim
    ok "Vim $(first_line vim --version)"
    ensure_vim_python3_runtime
    return 0
  fi

  if [[ "$USER_INSTALL" != "1" && "$IS_DEBIAN" -eq 1 ]]; then
    run_as_root apt-get install -y vim 2>/dev/null || true
    major="$(vim_major_version)"
    if [[ -n "$major" && "$major" -ge 9 ]]; then
      ok "Vim from packages"
      ensure_vim_python3_runtime
      return 0
    fi
  fi

  if [[ "$USER_INSTALL" != "1" && "$IS_RHEL" -eq 1 ]]; then
    run_as_root "$PKG_MGR" install -y vim 2>/dev/null || true
    major="$(vim_major_version)"
    if [[ -n "$major" && "$major" -ge 9 ]]; then
      ok "Vim from packages"
      ensure_vim_python3_runtime
      return 0
    fi
  fi

  info "Building Vim 9 from source..."
  ensure_build_deps
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
    make -j"$(parallel_jobs)"
  ) || die "Vim build failed (see log)"
  if [[ "$USER_INSTALL" == "1" ]]; then
    make -C "$build_root/vim-src/src" install
  else
    run_as_root make -C "$build_root/vim-src/src" install || die "Vim install failed"
  fi
  ok "Vim $(first_line vim --version)"
  ensure_vim_python3_runtime
}
