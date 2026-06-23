#!/usr/bin/env bash
# One-click Vim/Neovim dev environment (C++/Go/Python/NASM + coc.nvim)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"

# shellcheck source=scripts/lib/parse-args.sh
source "$LIB_DIR/parse-args.sh"
parse_install_args "$@"

export REPO_ROOT LIB_DIR

if [[ "$DRY_RUN" == "1" ]]; then
  # shellcheck source=scripts/lib/common.sh
  source "$LIB_DIR/common.sh"
  # shellcheck source=scripts/lib/detect_os.sh
  source "$LIB_DIR/detect_os.sh"
  ok "dry-run: detect_os OK"
  exit 0
fi

# If piped without repo (no vimrc), clone full tree first
if [[ ! -f "$REPO_ROOT/vimrc" ]]; then
  mkdir -p "$(dirname "$INSTALL_DIR")"
  if [[ ! -d "$INSTALL_DIR/.git" ]]; then
    git clone --depth 1 "$GITHUB_REPO" "$INSTALL_DIR"
  fi
  REPO_ROOT="$INSTALL_DIR"
  LIB_DIR="$REPO_ROOT/scripts/lib"
  export REPO_ROOT LIB_DIR
fi

mkdir -p "$INSTALL_ROOT"

# shellcheck source=scripts/lib/common.sh
source "$LIB_DIR/common.sh"
# shellcheck source=scripts/lib/detect_os.sh
source "$LIB_DIR/detect_os.sh"
# shellcheck source=scripts/lib/install-node.sh
source "$LIB_DIR/install-node.sh"
# shellcheck source=scripts/lib/install-vim.sh
source "$LIB_DIR/install-vim.sh"
# shellcheck source=scripts/lib/install-neovim.sh
source "$LIB_DIR/install-neovim.sh"
# shellcheck source=scripts/lib/install-lsp.sh
source "$LIB_DIR/install-lsp.sh"
# shellcheck source=scripts/lib/deploy-config.sh
source "$LIB_DIR/deploy-config.sh"
# shellcheck source=scripts/lib/install-plugins.sh
source "$LIB_DIR/install-plugins.sh"
# shellcheck source=scripts/lib/install-cursor.sh
source "$LIB_DIR/install-cursor.sh"
# shellcheck source=scripts/lib/verify.sh
source "$LIB_DIR/verify.sh"

if [[ "$IS_DEBIAN" -eq 1 ]]; then
  # shellcheck source=scripts/lib/deps-debian.sh
  source "$LIB_DIR/deps-debian.sh"
elif [[ "$IS_RHEL" -eq 1 ]]; then
  # shellcheck source=scripts/lib/deps-rhel.sh
  source "$LIB_DIR/deps-rhel.sh"
elif [[ "$IS_MACOS" -eq 1 ]]; then
  # shellcheck source=scripts/lib/deps-macos.sh
  source "$LIB_DIR/deps-macos.sh"
fi

stage_begin "Node.js"
install_node
stage_end "Node.js"

stage_begin "System dependencies"
if [[ "$IS_DEBIAN" -eq 1 ]]; then install_deps_debian
elif [[ "$IS_RHEL" -eq 1 ]]; then install_deps_rhel
elif [[ "$IS_MACOS" -eq 1 ]]; then install_deps_macos
fi
stage_end "Dependencies"

stage_begin "Vim"
install_vim
stage_end "Vim"

stage_begin "Neovim"
install_neovim
stage_end "Neovim"

stage_begin "LSP & toolchain"
install_lsp_stack
stage_end "LSP"

stage_begin "Deploy configuration"
deploy_config
stage_end "Deploy"

stage_begin "Plugins"
install_plugins
stage_end "Plugins"

if [[ "$SKIP_CURSOR" == "0" ]]; then
  stage_begin "Cursor (optional)"
  install_cursor_stack
  stage_end "Cursor"
fi

stage_begin "Verify"
verify_install
stage_end "Verify"

echo ""
ok "Done. Open vim or nvim. coc: <leader>gd (go to definition)."
info "Customize: edit $REPO_ROOT/vimrc (symlinked to ~/.vimrc by default)."
echo -e "\033[32;1m\t Enjoy It ~ \033[0m"
