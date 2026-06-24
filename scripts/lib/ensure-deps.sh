#!/usr/bin/env bash
# Install missing required system/user dependencies (upgrade only when version is insufficient).

can_install_system_packages() {
  [[ "$USER_INSTALL" != "1" ]] && { [[ "$IS_DEBIAN" -eq 1 ]] || [[ "$IS_RHEL" -eq 1 ]]; }
}

fix_centos_vault() {
  [[ "$IS_RHEL" -eq 1 ]] || return 0
  local f
  for f in /etc/yum.repos.d/CentOS-*; do
    [[ -f "$f" ]] || continue
    run_as_root sed -i 's/mirrorlist=/#mirrorlist=/g' "$f" 2>/dev/null || true
    run_as_root sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' "$f" 2>/dev/null || true
  done
}

_apt_pkg_installed() {
  dpkg -s "$1" &>/dev/null
}

_apt_install_packages() {
  local missing=() pkg
  for pkg in "$@"; do
    _apt_pkg_installed "$pkg" || missing+=("$pkg")
  done
  [[ ${#missing[@]} -eq 0 ]] && return 0
  info "Installing apt packages: ${missing[*]}"
  run_as_root apt-get update -qq || warn "apt-get update failed; continuing"
  run_as_root apt-get install -y "${missing[@]}"
}

_pkg_mgr_install() {
  info "Installing ${PKG_MGR} packages: $*"
  run_as_root "$PKG_MGR" install -y "$@"
}

_ensure_apt_for_command() {
  local cmd="$1"
  shift
  command -v "$cmd" &>/dev/null && return 0
  [[ "$IS_DEBIAN" -eq 1 ]] || return 1
  can_install_system_packages || return 1
  _apt_install_packages "$@"
}

_ensure_rhel_for_command() {
  local cmd="$1"
  shift
  command -v "$cmd" &>/dev/null && return 0
  [[ "$IS_RHEL" -eq 1 ]] || return 1
  can_install_system_packages || return 1
  _pkg_mgr_install "$@"
}

_ensure_brew_formula() {
  local formula="$1"
  [[ "$IS_MACOS" -eq 1 ]] || return 1
  need_cmd brew || return 1
  if brew list "$formula" &>/dev/null 2>&1; then
    return 0
  fi
  info "Installing brew formula: ${formula}"
  brew install "$formula"
}

ensure_bootstrap_tools() {
  if ! need_cmd curl && ! need_cmd wget; then
    if [[ "$IS_DEBIAN" -eq 1 ]]; then
      _ensure_apt_for_command curl curl || _ensure_apt_for_command wget wget || die "curl or wget required"
    elif [[ "$IS_RHEL" -eq 1 ]]; then
      _ensure_rhel_for_command curl curl || _ensure_rhel_for_command wget wget || die "curl or wget required"
    elif [[ "$IS_MACOS" -eq 1 ]]; then
      _ensure_brew_formula curl || die "curl or wget required"
    else
      die "curl or wget required"
    fi
  fi
  if ! need_cmd git; then
    if [[ "$IS_DEBIAN" -eq 1 ]]; then
      _ensure_apt_for_command git git || die "git required"
    elif [[ "$IS_RHEL" -eq 1 ]]; then
      _ensure_rhel_for_command git git || die "git required"
    elif [[ "$IS_MACOS" -eq 1 ]]; then
      _ensure_brew_formula git || die "git required"
    else
      die "git required"
    fi
  fi
  ok "Bootstrap tools OK"
}

ensure_clangd() {
  if command -v clangd &>/dev/null; then
    ok "clangd $(first_line clangd --version)"
    return 0
  fi
  info "clangd not found; installing..."
  if [[ "$IS_MACOS" -eq 1 ]]; then
    _ensure_brew_formula llvm || warn "brew install llvm failed"
    local llvm_prefix
    llvm_prefix="$(brew --prefix llvm 2>/dev/null || true)"
    [[ -n "$llvm_prefix" ]] && ensure_path_line "export PATH=\"$llvm_prefix/bin:\$PATH\""
  elif [[ "$IS_DEBIAN" -eq 1 ]]; then
    _ensure_apt_for_command clangd clangd clang llvm || warn "clangd apt install failed"
  elif [[ "$IS_RHEL" -eq 1 ]]; then
    if [[ "$USE_DNF" -eq 1 ]]; then
      _ensure_rhel_for_command clangd clang-tools-extra clang llvm || warn "clangd dnf install failed"
    else
      run_as_root yum install -y epel-release 2>/dev/null || true
      _ensure_rhel_for_command clangd clang-tools-extra || true
      _ensure_rhel_for_command clangd clang clang-devel llvm || warn "clangd yum install failed"
    fi
  fi
  if ! command -v clangd &>/dev/null && [[ "$IS_MACOS" -ne 1 ]]; then
    install_clangd_user_local || true
  fi
  if command -v clangd &>/dev/null; then
    ok "clangd $(first_line clangd --version)"
    return 0
  fi
  warn "clangd still not in PATH"
  return 1
}

ensure_nasm() {
  if command -v nasm &>/dev/null; then
    ok "nasm $(first_line nasm -v)"
    return 0
  fi
  info "nasm not found; installing..."
  if [[ "$IS_MACOS" -eq 1 ]]; then
    _ensure_brew_formula nasm || warn "brew install nasm failed"
  elif [[ "$IS_DEBIAN" -eq 1 ]]; then
    _ensure_apt_for_command nasm nasm binutils || warn "nasm apt install failed"
  elif [[ "$IS_RHEL" -eq 1 ]]; then
    _ensure_rhel_for_command nasm nasm binutils || warn "nasm install failed"
  fi
  if ! command -v nasm &>/dev/null && [[ "$IS_MACOS" -ne 1 ]]; then
    install_nasm_user_local || true
  fi
  if command -v nasm &>/dev/null; then
    ok "nasm $(first_line nasm -v)"
    return 0
  fi
  warn "nasm still not in PATH"
  return 1
}

ensure_python3_build_deps() {
  if [[ "$IS_DEBIAN" -eq 1 ]] && can_install_system_packages; then
    _apt_install_packages python3 python3-dev python3-pip python3-venv || true
  elif [[ "$IS_RHEL" -eq 1 ]] && can_install_system_packages; then
    _pkg_mgr_install python3 python3-devel || true
  elif [[ "$IS_MACOS" -eq 1 ]]; then
    _ensure_brew_formula python3 || true
  fi
}

ensure_build_deps() {
  if [[ "$IS_DEBIAN" -eq 1 ]] && can_install_system_packages; then
    _apt_install_packages build-essential autoconf automake libtool pkg-config m4 gettext \
      flex bison cmake make || true
  elif [[ "$IS_RHEL" -eq 1 ]] && can_install_system_packages; then
    run_as_root "$PKG_MGR" groupinstall -y "Development Tools" 2>/dev/null || true
    _pkg_mgr_install autoconf automake libtool pkg-config gettext ncurses-devel cmake make || true
  elif [[ "$IS_MACOS" -eq 1 ]]; then
    _ensure_brew_formula make || true
    _ensure_brew_formula cmake || true
  fi
}

ensure_debian_packages() {
  can_install_system_packages || return 0
  _ensure_apt_for_command curl curl
  _ensure_apt_for_command wget wget
  _ensure_apt_for_command git git
  _ensure_apt_for_command clangd clangd clang llvm
  _ensure_apt_for_command nasm nasm binutils
  _ensure_apt_for_command make make build-essential
  _ensure_apt_for_command python3 python3 python3-dev python3-pip python3-venv
  _ensure_apt_for_command pkg-config pkg-config
  ensure_build_deps
}

ensure_rhel_packages() {
  can_install_system_packages || return 0
  fix_centos_vault
  if [[ "$USE_DNF" -ne 1 ]]; then
    run_as_root yum install -y epel-release 2>/dev/null || true
  fi
  _ensure_rhel_for_command curl curl
  _ensure_rhel_for_command wget wget
  _ensure_rhel_for_command git git
  _ensure_rhel_for_command clangd clang-tools-extra clang llvm
  _ensure_rhel_for_command nasm nasm binutils
  _ensure_rhel_for_command make make
  _ensure_rhel_for_command python3 python3 python3-devel
  ensure_build_deps
}

ensure_macos_packages() {
  [[ "$IS_MACOS" -eq 1 ]] || return 0
  need_cmd brew || die "Install Homebrew: https://brew.sh"
  local formula
  for formula in git curl wget make cmake python3 llvm nasm ripgrep; do
    _ensure_brew_formula "$formula" || warn "brew install ${formula} failed"
  done
  local llvm_prefix
  llvm_prefix="$(brew --prefix llvm 2>/dev/null || true)"
  [[ -n "$llvm_prefix" ]] && ensure_path_line "export PATH=\"$llvm_prefix/bin:\$PATH\""
}

ensure_system_dependencies() {
  if [[ "$USER_INSTALL" == "1" && "$IS_MACOS" -eq 0 ]]; then
    ensure_linux_user_dependencies
    return 0
  fi
  if [[ "$IS_DEBIAN" -eq 1 ]]; then
    ensure_debian_packages
  elif [[ "$IS_RHEL" -eq 1 ]]; then
    ensure_rhel_packages
  elif [[ "$IS_MACOS" -eq 1 ]]; then
    ensure_macos_packages
  fi
  ensure_clangd || true
  ensure_nasm || true
  ok "Required dependencies ensured"
}
