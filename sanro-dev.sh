#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v pwsh >/dev/null 2>&1; then
  echo "[FAIL] PowerShell 7 (pwsh) is required."
  echo "Run: ./bootstrap-ubuntu.sh --install"
  exit 1
fi

exec pwsh -NoLogo -NoProfile -File "$SCRIPT_DIR/sanro-dev.ps1" "$@"
