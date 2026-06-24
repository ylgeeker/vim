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
  if vim --version 2>&1 | grep -q '+python3'; then
    check "vim+python3" 'out="$(vim --not-a-term -c "py3 import sys" -c "qa!" 2>&1)"; ! grep -qE "E263|E370|无法加载|can.t load Python" <<<"$out"'
  fi
  check "node>=20" '[[ $(node_major_version) -ge 20 ]]'
  check "node+crypto" 'node_has_global_crypto'
  check "go>=${GO_VERSION}" 'go_version_sufficient'
  check "clangd" "command -v clangd"
  check "gopls" "command -v gopls"
  check "nasm" "command -v nasm"
  check "coc-settings" "[[ -f $HOME/.vim/coc-settings.json ]]"

  local coc_ext_dir legacy_dir ext
  coc_ext_dir="$(coc_ext_modules_dir)"
  legacy_dir="$(coc_legacy_ext_modules_dir)"
  for ext in "${COC_EXTENSIONS[@]}"; do
    if [[ -d "$coc_ext_dir/$ext" ]]; then
      ok "$ext extension"
    else
      if [[ -d "$legacy_dir/$ext" ]]; then
        warn "$ext extension found at legacy path $legacy_dir/$ext (re-run ./install.sh to migrate)"
      fi
      err "$ext extension MISSING"
      failed=1
    fi
  done

  local fmt nasm_rc repo_fixture
  fmt="$(nasm_resolve_fmt)"
  set +e
  nasm_smoke_compile "$fmt"
  nasm_rc=$?
  if [[ "$nasm_rc" -ne 0 ]]; then
    repo_fixture="$(nasm_verify_fixture)"
    if [[ -f "$repo_fixture" ]]; then
      nasm -f "$fmt" "$repo_fixture" -o /tmp/vim-nasm-test.o &>/dev/null
      nasm_rc=$?
    fi
  fi
  set -e
  if [[ "$nasm_rc" -eq 0 ]]; then
    ok "NASM compile fixture"
  else
    err "NASM compile fixture FAILED"
    failed=1
  fi

  [[ "$failed" -eq 0 ]] || die "Verification failed"
  ok "All L1 verification checks passed"
}
