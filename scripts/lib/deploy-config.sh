#!/usr/bin/env bash

link_or_copy() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ "$COPY_CONFIG" == "1" ]]; then
    cp -f "$src" "$dest"
  else
    ln -sfn "$src" "$dest"
  fi
}

deploy_config() {
  local repo="${REPO_ROOT:?}"
  mkdir -p "$HOME/.vim" "$HOME/.config/nvim"

  link_or_copy "$repo/vimrc" "$HOME/.vimrc"
  ok "vimrc -> $HOME/.vimrc"

  if [[ -d "$repo/after" ]]; then
    link_or_copy "$repo/after" "$HOME/.vim/after"
    ok "after/ -> ~/.vim/after"
  fi

  if [[ -f "$repo/plugin/cursor.vim" ]]; then
    mkdir -p "$HOME/.vim/plugin"
    link_or_copy "$repo/plugin/cursor.vim" "$HOME/.vim/plugin/cursor.vim"
    ok "cursor.vim -> ~/.vim/plugin/"
  fi

  local template="$repo/coc-settings.json.in"
  [[ -f "$template" ]] || die "Missing $template"
  # shellcheck source=/dev/null
  source "$LIB_DIR/install-lsp.sh"
  local clangd gopls
  clangd="$(resolve_clangd_path)"
  gopls="$(resolve_gopls_path)"
  sed -e "s|@CLANGD_PATH@|${clangd}|g" \
      -e "s|@GOPLS_PATH@|${gopls}|g" \
      "$template" > "$HOME/.vim/coc-settings.json"
  ok "Generated ~/.vim/coc-settings.json"

  cat > "$HOME/.config/nvim/init.vim" <<'EOF'
set runtimepath^=~/.vim
source ~/.vimrc
EOF
  ok "Neovim init.vim configured"

  ensure_gpg_signing
  ok "GPG signing helpers configured"

  if [[ "$INCLUDE_GITCONFIG" == "1" && -f "$repo/gitconfig" ]]; then
    if [[ -f "$HOME/.gitconfig" ]]; then
      if grep -qF "$repo/gitconfig" "$HOME/.gitconfig" 2>/dev/null; then
        info "Git config: repo gitconfig already included, skipping"
      else
        info "Git config: ~/.gitconfig already exists, skipping repo gitconfig"
      fi
    else
      {
        echo "[include]"
        echo "  path = $repo/gitconfig"
      } > "$HOME/.gitconfig"
      ok "Git include: $repo/gitconfig"
    fi
  fi

  # Export for lang-nasm.vim via env file
  mkdir -p "$HOME/.vim"
  cat > "$HOME/.vim/nasm-env.vim" <<EOF
let g:nasm_fmt = '${NASM_FMT}'
let g:nasm_ld_cmd = '${NASM_LD_CMD}'
EOF
  ok "NASM build vars written"
}
