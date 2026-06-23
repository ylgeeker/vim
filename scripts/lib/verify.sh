#!/usr/bin/env bash

verify_install() {
  local failed=0
  check() {
    if eval "$2" &>/dev/null; then
      ok "$1"
    else
      err "$1 MISSING"
      failed=1
    fi
  }

  check "vim" "command -v vim"
  check "node>=18" '[[ $(node_major_version) -ge 18 ]]'
  check "clangd" "command -v clangd"
  check "gopls" "command -v gopls"
  check "nasm" "command -v nasm"
  check "coc-settings" "[[ -f $HOME/.vim/coc-settings.json ]]"

  local coc_ext_dir="${XDG_CONFIG_HOME:-$HOME/.config}/coc/extensions/node_modules"
  for ext in coc-clangd coc-go coc-pyright; do
    if [[ -d "$coc_ext_dir/$ext" ]]; then
      ok "$ext extension"
    else
      err "$ext extension MISSING"
      failed=1
    fi
  done

  local fixture_asm="${REPO_ROOT}/test/fixtures/nasm/hello.asm"
  if [[ -f "$fixture_asm" ]]; then
    local fmt="${NASM_FMT:-elf64}"
    nasm -f "$fmt" "$fixture_asm" -o /tmp/vim-nasm-test.o 2>/dev/null && ok "NASM compile fixture" || {
      err "NASM compile fixture FAILED"
      failed=1
    }
  fi

  [[ "$failed" -eq 0 ]] || die "Verification failed"
  ok "All L1 verification checks passed"
}
