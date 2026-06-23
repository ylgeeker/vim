#!/usr/bin/env bash
# Shared remote install: parse args, clone repo, exec install.sh
# Sourced by bootstrap.sh (local) or fetched via REPO_RAW when piped.

remote_entry_usage() {
  cat <<'EOF'
Usage: bootstrap.sh [OPTIONS] [-- INSTALL_OPTIONS]

Bootstrap / remote install options:
  --install-dir PATH  Clone destination (default: ~/.local/share/ylgeeker/vim)
  --repo-url URL      Git remote (default: https://github.com/ylgeeker/vim.git)
  -h, --help          Show this help

Remote install:
  curl -fsSL .../scripts/bootstrap.sh | bash -s -- [INSTALL_OPTIONS]

Environment (optional):
  REPO_RAW    Base URL to fetch this script when piped (default: GitHub main raw)
  REPO_URL    Git clone URL when --repo-url is not passed (CI/local checkout testing)

All options after "--" (or any install flag) are passed to install.sh.
Remote --dry-run detects OS only and does not clone.
EOF
}

_remote_entry_lib_dir() {
  local d
  d="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  [[ -f "${d}/parse-args.sh" ]] || return 1
  printf '%s' "$d"
}

_remote_fetch_lib_dir() {
  local raw dest f
  raw="${REPO_RAW:-https://raw.githubusercontent.com/ylgeeker/vim/main}"
  dest="$(mktemp -d)"
  for f in common.sh detect_os.sh parse-args.sh; do
    if ! curl -fsSL "${raw}/scripts/lib/${f}" -o "${dest}/${f}"; then
      rm -rf "$dest"
      return 1
    fi
  done
  printf '%s' "$dest"
}

_remote_resolve_lib_dir() {
  local install_dir="$1"
  local d=""

  if [[ -f "${install_dir}/vimrc" && -f "${install_dir}/scripts/lib/detect_os.sh" ]]; then
    printf '%s' "${install_dir}/scripts/lib"
    return 0
  fi
  if d="$(_remote_entry_lib_dir)"; then
    printf '%s' "$d"
    return 0
  fi
  if d="$(_remote_fetch_lib_dir)"; then
    printf '%s' "$d"
    return 0
  fi
  return 1
}

_remote_install_args_is_dry_run_only() {
  [[ $# -eq 1 && "$1" == "--dry-run" ]]
}

_remote_entry_dry_run() {
  local install_dir="$1"
  local lib_dir

  lib_dir="$(_remote_resolve_lib_dir "$install_dir")" || {
    echo "ERR: failed to load install libraries for --dry-run" >&2
    exit 1
  }

  # shellcheck source=scripts/lib/common.sh
  source "${lib_dir}/common.sh"
  # shellcheck source=scripts/lib/detect_os.sh
  source "${lib_dir}/detect_os.sh"
  ok "dry-run: detect_os OK"
}

_remote_require_vimrc() {
  local install_dir="$1"
  if [[ -f "${install_dir}/vimrc" ]]; then
    return 0
  fi
  echo "ERR: missing vimrc at ${install_dir}" >&2
  if [[ -d "${install_dir}/.git" ]]; then
    echo "ERR: remove the broken clone or pass --install-dir to use another path" >&2
  fi
  exit 1
}

_remote_validate_install_args() {
  local d

  if d="$(_remote_entry_lib_dir)"; then
    :
  elif d="$(_remote_fetch_lib_dir)"; then
    :
  else
    echo "ERR: failed to load parse-args.sh for option validation" >&2
    exit 1
  fi
  # shellcheck source=scripts/lib/parse-args.sh
  source "${d}/parse-args.sh"
  check_install_args_known "$@" || exit 1
}

remote_entry_main() {
  local install_dir="${HOME}/.local/share/ylgeeker/vim"
  local repo_url="${REPO_URL:-https://github.com/ylgeeker/vim.git}"
  local install_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --install-dir)
        [[ $# -ge 2 ]] || { echo "ERR: --install-dir requires a value" >&2; exit 1; }
        install_dir="$2"
        shift 2
        ;;
      --repo-url)
        [[ $# -ge 2 ]] || { echo "ERR: --repo-url requires a value" >&2; exit 1; }
        repo_url="$2"
        shift 2
        ;;
      -h|--help)
        remote_entry_usage
        exit 0
        ;;
      --)
        shift
        install_args=("$@")
        break
        ;;
      -*)
        install_args+=("$1")
        shift
        ;;
      *)
        install_args+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#install_args[@]} -eq 1 ]] && _remote_install_args_is_dry_run_only "${install_args[0]}"; then
    _remote_entry_dry_run "$install_dir"
    exit 0
  fi

  if [[ ${#install_args[@]} -gt 0 ]]; then
    _remote_validate_install_args "${install_args[@]}"
  fi

  command -v git &>/dev/null || { echo "ERR: git is required for remote install" >&2; exit 1; }

  if [[ -d "$install_dir/.git" ]]; then
    _remote_require_vimrc "$install_dir"
    echo "[INFO] Updating existing clone at $install_dir"
    if ! git -C "$install_dir" pull --ff-only; then
      echo "[WARN] git pull failed; using existing clone at $install_dir" >&2
      _remote_require_vimrc "$install_dir"
    fi
  else
    echo "[INFO] Cloning $repo_url -> $install_dir"
    mkdir -p "$(dirname "$install_dir")"
    git clone --depth 1 "$repo_url" "$install_dir"
  fi

  _remote_require_vimrc "$install_dir"

  if [[ ${#install_args[@]} -gt 0 ]]; then
    exec "$install_dir/install.sh" "${install_args[@]}"
  else
    exec "$install_dir/install.sh"
  fi
}
