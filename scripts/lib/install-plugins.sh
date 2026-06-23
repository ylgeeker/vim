#!/usr/bin/env bash

migrate_from_ycm() {
  if [[ -d "$HOME/.vim/plugged/YouCompleteMe" ]]; then
    info "Removing legacy YouCompleteMe..."
    vim +PlugClean! +qall --not-a-term </dev/null 2>/dev/null || true
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

_warn_coc_install_output() {
  local log_file="$1" try="$2" rc="$3"
  if [[ "$rc" -eq 124 ]]; then
    warn "CocInstall attempt $try timed out after 900s"
  else
    warn "CocInstall attempt $try failed (exit $rc)"
  fi
  [[ -s "$log_file" ]] || return 0
  warn "CocInstall output (last 20 lines):"
  tail -20 "$log_file" | while IFS= read -r line; do
    warn "  $line"
  done
}

coc_install_with_retry() {
  local try _coc_out _rc
  for try in 1 2 3; do
    info "CocInstall attempt $try (may take several minutes)..."
    _coc_out="$(mktemp)"
    set +e
    run_with_timeout 900 vim --not-a-term "+CocInstall -sync coc-clangd coc-go coc-pyright" +qall \
      >"$_coc_out" 2>&1 </dev/null
    _rc=$?
    set -e
    if [[ "$_rc" -eq 0 ]]; then
      rm -f "$_coc_out"
      ensure_output_newline
      ok "coc extensions installed"
      return 0
    fi
    _warn_coc_install_output "$_coc_out" "$try" "$_rc"
    rm -f "$_coc_out"
    sleep 2
  done
  die "CocInstall failed after 3 attempts"
}

install_plugins() {
  install_vim_plug
  migrate_from_ycm
  info "PlugInstall (may take several minutes)..."
  vim +PlugInstall +qall --not-a-term </dev/null || die "PlugInstall failed"
  ensure_output_newline
  coc_install_with_retry
}
