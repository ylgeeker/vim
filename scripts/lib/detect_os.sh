#!/usr/bin/env bash

OS_ID=""
PKG_MGR=""
ARCH="$(uname -m)"
IS_MACOS=0
IS_DEBIAN=0
IS_RHEL=0
USE_DNF=0
NASM_FMT="elf64"
NASM_LD_CMD='ld %:r.o -o %:r'

case "$(uname -s)" in
  Darwin)
    OS_ID="macos"
    IS_MACOS=1
    PKG_MGR="brew"
    if [[ "$ARCH" == "arm64" ]]; then
      NASM_FMT="macho64"
      NASM_LD_CMD='ld -arch arm64 -o %:r %:r.o -lSystem -syslibroot $(xcrun -sdk macosx --show-sdk-path)'
    else
      NASM_FMT="macho64"
      NASM_LD_CMD='ld -arch x86_64 -o %:r %:r.o -lSystem -syslibroot $(xcrun -sdk macosx --show-sdk-path)'
    fi
    ;;
  Linux)
    if [[ -f /etc/os-release ]]; then
      # shellcheck disable=SC1091
      . /etc/os-release
      case "${ID:-}" in
        ubuntu|debian|linuxmint|pop) OS_ID="$ID"; IS_DEBIAN=1; PKG_MGR="apt" ;;
        centos|rhel|rocky|almalinux|fedora|ol) OS_ID="$ID"; IS_RHEL=1 ;;
        *) OS_ID="${ID:-linux}" ;;
      esac
    fi
    if [[ -z "$PKG_MGR" ]]; then
      if command -v apt-get &>/dev/null; then
        IS_DEBIAN=1
        PKG_MGR="apt"
      elif command -v dnf &>/dev/null; then
        IS_RHEL=1
        PKG_MGR="dnf"
        USE_DNF=1
      elif command -v yum &>/dev/null; then
        IS_RHEL=1
        PKG_MGR="yum"
      fi
    fi
    if [[ "$ARCH" == "aarch64" ]]; then
      NASM_FMT="elf64"
    fi
    ;;
  *)
    die "Unsupported OS: $(uname -s)"
    ;;
esac

[[ -n "$PKG_MGR" ]] || die "No supported package manager (apt/yum/dnf/brew)."

export OS_ID PKG_MGR ARCH IS_MACOS IS_DEBIAN IS_RHEL USE_DNF NASM_FMT NASM_LD_CMD
ok "Detected OS=$OS_ID pkg=$PKG_MGR arch=$ARCH"
