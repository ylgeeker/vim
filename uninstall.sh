#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"

# shellcheck source=scripts/lib/parse-args.sh
source "$LIB_DIR/parse-args.sh"
parse_uninstall_args "$@"

rm -f "$HOME/.vimrc"
rm -f "$HOME/.vim/coc-settings.json" "$HOME/.vim/nasm-env.vim"
rm -f "$HOME/.config/nvim/init.vim"

for link in "$HOME/.vim/after" "$HOME/.vim/plugin/cursor.vim"; do
  [[ -L "$link" ]] && rm -f "$link"
done

if [[ "$FULL" == "1" ]]; then
  rm -rf "$HOME/.vim/plugged" "$HOME/.config/coc"
  ok_msg="Full uninstall (plugged + coc data removed)"
else
  ok_msg="Symlinks and generated config removed"
fi

echo "[OK] $ok_msg"
echo "[INFO] System packages (brew/apt) were not removed."
