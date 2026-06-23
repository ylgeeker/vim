#!/usr/bin/env bash
# CLI argument parsing for install/bootstrap/uninstall (no environment variable overrides).

install_usage() {
  cat <<'EOF'
Usage: ./install.sh [OPTIONS]

  --with-cursor       Install Cursor editor and agent CLI
  --copy-config       Copy config files instead of symlinks
  --user-install      Install without sudo (~/.local)
  --include-gitconfig Include repo gitconfig in ~/.gitconfig
  --minimal-upgrade   Run apt/yum upgrade before install
  --install-bazel     Install Bazel (optional)
  --node-version N    Node.js major version (default: 20)
  --go-version V      Go toolchain version (default: 1.24.2)
  --install-root PATH Build cache directory
  --dry-run           Detect OS and exit
  -h, --help          Show this help

Default: Vim/Neovim + coc.nvim dev env only (no Cursor).
EOF
}

uninstall_usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [OPTIONS]

  --full              Also remove ~/.vim/plugged and ~/.config/coc
  -h, --help          Show this help

Default: remove symlinks and generated coc-settings only.
EOF
}

_parse_install_defaults() {
  SKIP_CURSOR=1
  COPY_CONFIG=0
  USER_INSTALL=0
  INCLUDE_GITCONFIG=0
  MINIMAL_UPGRADE=0
  INSTALL_BAZEL=0
  NODE_VERSION=20
  GO_VERSION=1.24.2
  INSTALL_ROOT="/tmp/ylgeeker/vim-build"
  DRY_RUN=0
}

check_install_args_known() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --with-cursor|--copy-config|--user-install|--include-gitconfig)
        shift ;;
      --minimal-upgrade|--install-bazel|--dry-run)
        shift ;;
      --node-version|--go-version|--install-root)
        [[ $# -ge 2 ]] || { echo "ERR: $1 requires a value" >&2; return 1; }
        shift 2
        ;;
      -h|--help)
        install_usage
        exit 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo "ERR: unknown option: $1 (try --help)" >&2
        return 1
        ;;
      *)
        echo "ERR: unexpected argument(s): $*" >&2
        return 1
        ;;
    esac
  done

  if [[ $# -gt 0 ]]; then
    echo "ERR: unexpected argument(s): $*" >&2
    return 1
  fi
  return 0
}

parse_install_args() {
  _parse_install_defaults
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --with-cursor) SKIP_CURSOR=0; shift ;;
      --copy-config) COPY_CONFIG=1; shift ;;
      --user-install) USER_INSTALL=1; shift ;;
      --include-gitconfig) INCLUDE_GITCONFIG=1; shift ;;
      --minimal-upgrade) MINIMAL_UPGRADE=1; shift ;;
      --install-bazel) INSTALL_BAZEL=1; shift ;;
      --node-version)
        [[ $# -ge 2 ]] || { echo "ERR: --node-version requires a value" >&2; exit 1; }
        NODE_VERSION="$2"
        shift 2
        ;;
      --go-version)
        [[ $# -ge 2 ]] || { echo "ERR: --go-version requires a value" >&2; exit 1; }
        GO_VERSION="$2"
        shift 2
        ;;
      --install-root)
        [[ $# -ge 2 ]] || { echo "ERR: --install-root requires a value" >&2; exit 1; }
        INSTALL_ROOT="$2"
        shift 2
        ;;
      --dry-run) DRY_RUN=1; shift ;;
      -h|--help) install_usage; exit 0 ;;
      --) shift; break ;;
      -*)
        echo "ERR: unknown option: $1 (try --help)" >&2
        exit 1
        ;;
      *) break ;;
    esac
  done

  if [[ $# -gt 0 ]]; then
    echo "ERR: unexpected argument(s): $*" >&2
    exit 1
  fi

  export SKIP_CURSOR COPY_CONFIG USER_INSTALL INCLUDE_GITCONFIG
  export MINIMAL_UPGRADE INSTALL_BAZEL NODE_VERSION GO_VERSION
  export INSTALL_ROOT DRY_RUN
}

parse_uninstall_args() {
  FULL=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --full) FULL=1; shift ;;
      -h|--help) uninstall_usage; exit 0 ;;
      -*)
        echo "ERR: unknown option: $1 (try --help)" >&2
        exit 1
        ;;
      *)
        echo "ERR: unexpected argument: $1" >&2
        exit 1
        ;;
    esac
  done
  export FULL
}
