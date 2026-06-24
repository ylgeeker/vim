#!/usr/bin/env bash

migrate_from_ycm() {
  if [[ -d "$HOME/.vim/plugged/YouCompleteMe" ]]; then
    info "Removing legacy YouCompleteMe..."
    vim --not-a-term +PlugClean! +qall </dev/null 2>/dev/null || true
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

install_coc_extensions_npm() {
  need_cmd npm || die "npm not found (Node.js stage should have installed it)"
  local ext_root
  ext_root="$(coc_data_home)/extensions"
  mkdir -p "$ext_root"
  if [[ ! -f "$ext_root/package.json" ]]; then
    echo '{"dependencies":{}}' > "$ext_root/package.json"
  fi
  info "Installing coc extensions via npm..."
  local _npm_out _npm_rc
  _npm_out="$(mktemp)"
  set +e
  (
    cd "$ext_root"
    npm install --global-style --ignore-scripts --no-bin-links \
      --no-package-lock --only=prod \
      "${COC_EXTENSIONS[@]}"
  ) >"$_npm_out" 2>&1
  _npm_rc=$?
  set -e
  if [[ "$_npm_rc" -ne 0 ]]; then
    warn "npm coc extension install failed (exit $_npm_rc)"
    [[ -s "$_npm_out" ]] && tail -20 "$_npm_out" | while IFS= read -r line; do warn "  $line"; done
    rm -f "$_npm_out"
    return 1
  fi
  rm -f "$_npm_out"
  return 0
}

coc_install_with_retry() {
  local try _coc_out _rc coc_cmd
  coc_cmd="CocInstall -sync ${COC_EXTENSIONS[*]}"
  for try in 1 2 3; do
    info "CocInstall attempt $try (may take several minutes)..."
    _coc_out="$(mktemp)"
    set +e
    run_with_timeout 900 vim --not-a-term "+$coc_cmd" +qall \
      >"$_coc_out" 2>&1 </dev/null
    _rc=$?
    set -e
    if [[ "$_rc" -eq 0 ]]; then
      rm -f "$_coc_out"
      ensure_output_newline
      return 0
    fi
    _warn_coc_install_output "$_coc_out" "$try" "$_rc"
    rm -f "$_coc_out"
    sleep 2
  done
  return 1
}

install_coc_extensions() {
  install_coc_extensions_npm || true
  if [[ -z "$(coc_extensions_missing)" ]]; then
    ok "coc extensions installed"
    return 0
  fi
  info "Some coc extensions still missing; trying CocInstall fallback..."
  coc_install_with_retry || true
  if [[ -n "$(coc_extensions_missing)" ]]; then
    die "coc extension install failed"
  fi
  ok "coc extensions installed"
}

install_plugins() {
  install_vim_plug
  migrate_from_ycm
  info "PlugInstall (may take several minutes)..."
  local _plug_out _plug_rc
  _plug_out="$(mktemp)"
  set +e
  vim --not-a-term +PlugInstall +qall >"$_plug_out" 2>&1 </dev/null
  _plug_rc=$?
  set -e
  if [[ "$_plug_rc" -ne 0 ]]; then
    warn "PlugInstall failed (exit $_plug_rc)"
    [[ -s "$_plug_out" ]] && tail -20 "$_plug_out" | while IFS= read -r line; do warn "  $line"; done
    rm -f "$_plug_out"
    die "PlugInstall failed"
  fi
  rm -f "$_plug_out"
  ensure_output_newline
  install_coc_extensions
}
