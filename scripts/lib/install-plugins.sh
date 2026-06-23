#!/usr/bin/env bash

migrate_from_ycm() {
  if [[ -d "$HOME/.vim/plugged/YouCompleteMe" ]]; then
    info "Removing legacy YouCompleteMe..."
    vim +PlugClean! +qall --not-a-term 2>/dev/null || true
    rm -rf "$HOME/.vim/plugged/YouCompleteMe"
  fi
  rm -f "$HOME/.ycm_extra_conf.py"
}

install_vim_plug() {
  mkdir -p "$HOME/.vim/autoload"
  if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
    download "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" \
      "$HOME/.vim/autoload/plug.vim"
    ok "vim-plug installed"
  fi
}

coc_install_with_retry() {
  local editor vim_bin
  if command -v nvim &>/dev/null; then
    editor="nvim"
  else
    editor="vim"
  fi
  local try
  for try in 1 2 3; do
    info "CocInstall attempt $try..."
    if "$editor" --headless "+CocInstall -sync coc-clangd coc-go coc-pyright" +qa 2>/dev/null; then
      ok "coc extensions installed"
      return 0
    fi
    sleep 2
  done
  die "CocInstall failed after 3 attempts"
}

install_plugins() {
  install_vim_plug
  migrate_from_ycm
  info "PlugInstall (may take several minutes)..."
  vim +PlugInstall +qall --not-a-term || die "PlugInstall failed"
  coc_install_with_retry
}
