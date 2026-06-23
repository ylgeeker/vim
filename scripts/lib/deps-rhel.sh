#!/usr/bin/env bash

fix_centos_vault() {
  for f in /etc/yum.repos.d/CentOS-*; do
    [[ -f "$f" ]] || continue
    run_as_root sed -i 's/mirrorlist=/#mirrorlist=/g' "$f" 2>/dev/null || true
    run_as_root sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' "$f" 2>/dev/null || true
  done
}

install_deps_rhel() {
  if [[ "$USER_INSTALL" == "1" ]]; then
    warn "USER_INSTALL: skipping system package install on RHEL family"
    return 0
  fi

  fix_centos_vault
  if [[ "$USE_DNF" -eq 1 ]]; then
    run_as_root dnf makecache -y
    if [[ "$SYSTEM_UPGRADE" == "1" ]]; then
      info "Running system package upgrade (--system-upgrade)..."
      run_as_root dnf upgrade -y || warn "dnf upgrade failed; continuing with dependency install"
    fi
    run_as_root dnf groupinstall -y "Development Tools" || true
    run_as_root dnf install -y autoconf automake libtool pkg-config gettext ncurses-devel \
      curl git wget make cmake python3-devel clang llvm clang-tools-extra \
      the_silver_searcher nasm binutils zsh
  else
    run_as_root yum makecache
    if [[ "$SYSTEM_UPGRADE" == "1" ]]; then
      info "Running system package upgrade (--system-upgrade)..."
      run_as_root yum update -y || warn "yum update failed; continuing with dependency install"
    fi
    run_as_root yum groupinstall -y "Development Tools" || true
    run_as_root yum install -y autoconf automake libtool m4 pkg-config gettext ncurses-devel \
      curl git wget make cmake python3-devel clang llvm \
      the_silver_searcher nasm binutils zsh
    run_as_root yum install -y epel-release 2>/dev/null || true
  fi
  ok "RHEL/CentOS dependencies installed"
}
