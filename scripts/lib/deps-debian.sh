#!/usr/bin/env bash

install_bazel_debian() {
  command -v bazel &>/dev/null && return 0
  run_as_root apt-get install -y apt-transport-https ca-certificates gnupg
  local gpg_file="${INSTALL_ROOT}/bazel.gpg"
  curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > "$gpg_file"
  run_as_root mv "$gpg_file" /usr/share/keyrings/bazel-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8" | \
    run_as_root tee /etc/apt/sources.list.d/bazel.list >/dev/null
  run_as_root apt-get update
  run_as_root apt-get install -y bazel || warn "Bazel install failed"
}

install_deps_debian() {
  if [[ "$USER_INSTALL" == "1" ]]; then
    info "Skipping system package install (--user-install)"
    ok "Debian/Ubuntu dependencies skipped"
    return 0
  fi
  if [[ "$SYSTEM_UPGRADE" != "1" ]]; then
    info "Skipping system package install (use --system-upgrade to install/upgrade system dependencies)"
    ok "Debian/Ubuntu dependencies skipped"
    return 0
  fi
  run_as_root apt-get update
  info "Running system package upgrade (--system-upgrade)..."
  run_as_root apt-get upgrade -y || warn "apt-get upgrade failed; continuing with dependency install"
  run_as_root apt-get install -y \
    build-essential autoconf automake libtool pkg-config m4 gettext flex bison \
    curl git wget make cmake python3-dev python3-venv python3-pip \
    clang clangd clang-format llvm silversearcher-ag ripgrep \
    nasm binutils zsh
  if [[ "$INSTALL_BAZEL" == "1" ]]; then
    install_bazel_debian || true
  fi
  ok "Debian/Ubuntu dependencies installed"
}
