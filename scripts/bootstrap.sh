#!/usr/bin/env bash
# Remote bootstrap: shallow clone then run install.sh
set -euo pipefail

_remote_entry_from_path() {
  local script_path="$1"
  local lib_dir

  [[ -n "$script_path" && -f "$script_path" ]] || return 1
  lib_dir="$(cd "$(dirname "$script_path")" && pwd)/lib"
  [[ -f "${lib_dir}/remote-entry.sh" ]] || return 1
  # shellcheck source=scripts/lib/remote-entry.sh
  source "${lib_dir}/remote-entry.sh"
  return 0
}

if _remote_entry_from_path "${BASH_SOURCE[0]:-}"; then
  remote_entry_main "$@"
  exit $?
fi

_raw="${REPO_RAW:-https://raw.githubusercontent.com/ylgeeker/vim/main}"
_tmp="$(mktemp)"
if ! curl -fsSL "${_raw}/scripts/lib/remote-entry.sh" -o "$_tmp"; then
  rm -f "$_tmp"
  echo "ERR: failed to load remote-entry.sh from ${_raw}" >&2
  echo "ERR: set REPO_RAW to your branch raw URL, or clone the repo and run ./install.sh" >&2
  exit 1
fi
# shellcheck source=/dev/null
source "$_tmp"
rm -f "$_tmp"
remote_entry_main "$@"
