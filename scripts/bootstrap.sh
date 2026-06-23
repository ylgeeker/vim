#!/usr/bin/env bash
# Remote bootstrap: shallow clone then run install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=scripts/lib/parse-args.sh
source "$SCRIPT_DIR/lib/parse-args.sh"
parse_bootstrap_args "$@"

if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "[INFO] Updating existing clone at $INSTALL_DIR"
  git -C "$INSTALL_DIR" pull --ff-only || true
else
  echo "[INFO] Cloning $REPO_URL -> $INSTALL_DIR"
  git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
fi

if [[ ${#INSTALL_ARGS[@]} -gt 0 ]]; then
  exec "$INSTALL_DIR/install.sh" "${INSTALL_ARGS[@]}"
else
  exec "$INSTALL_DIR/install.sh"
fi
