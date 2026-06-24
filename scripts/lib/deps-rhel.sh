#!/usr/bin/env bash

install_deps_rhel() {
  if [[ "$USER_INSTALL" == "1" ]]; then
    ensure_linux_user_dependencies
    return 0
  fi
  fix_centos_vault
  if [[ "$SYSTEM_UPGRADE" == "1" ]]; then
    if [[ "$USE_DNF" -eq 1 ]]; then
      run_as_root dnf makecache -y
      info "Running system package upgrade (--system-upgrade)..."
      run_as_root dnf upgrade -y || warn "dnf upgrade failed; continuing with dependency install"
    else
      run_as_root yum makecache
      info "Running system package upgrade (--system-upgrade)..."
      run_as_root yum update -y || warn "yum update failed; continuing with dependency install"
    fi
  fi
  ensure_rhel_packages
  if [[ "$SYSTEM_UPGRADE" == "1" && "$USE_DNF" -eq 1 ]]; then
    _pkg_mgr_install the_silver_searcher zsh || true
  fi
  ok "RHEL/CentOS dependencies ready"
}
