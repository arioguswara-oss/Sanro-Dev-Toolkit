#!/usr/bin/env bash
set -euo pipefail

MODE="check"
if [[ "${1:-}" == "--install" ]]; then
  MODE="install"
elif [[ -n "${1:-}" && "${1:-}" != "--check" ]]; then
  echo "Usage: $0 [--check|--install]" >&2
  exit 2
fi

if [[ ! -r /etc/os-release ]]; then
  echo "[FAIL] /etc/os-release not found; Ubuntu could not be verified." >&2
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "[FAIL] This bootstrap supports Ubuntu only. Detected: ${ID:-unknown}" >&2
  exit 1
fi

run_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    if ! command -v sudo >/dev/null 2>&1; then
      echo "[FAIL] sudo is required when not running as root." >&2
      exit 1
    fi
    sudo "$@"
  fi
}

show_state() {
  echo "SANRO DEV TOOLKIT - UBUNTU HOST CHECK"
  echo "Ubuntu: ${PRETTY_NAME:-${VERSION_ID:-unknown}}"
  for cmd in git curl pwsh; do
    if command -v "$cmd" >/dev/null 2>&1; then
      case "$cmd" in
        git)  version="$(git --version 2>/dev/null || true)" ;;
        curl) version="$(curl --version 2>/dev/null | head -n 1 || true)" ;;
        pwsh) version="$(pwsh --version 2>/dev/null || true)" ;;
      esac
      echo "[OK] $cmd: $version"
    else
      echo "[MISSING] $cmd"
    fi
  done
}

if [[ "$MODE" == "check" ]]; then
  show_state
  if command -v git >/dev/null 2>&1 && command -v curl >/dev/null 2>&1 && command -v pwsh >/dev/null 2>&1; then
    exit 0
  fi
  echo "Run '$0 --install' to install the supported host prerequisites."
  exit 1
fi

echo "SANRO DEV TOOLKIT - UBUNTU HOST INSTALL"
echo "Target: ${PRETTY_NAME:-${VERSION_ID:-unknown}}"
echo "This action installs OS packages and the Microsoft PowerShell package repository."

run_root apt-get update
run_root apt-get install -y ca-certificates curl git gnupg

if ! command -v pwsh >/dev/null 2>&1; then
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT
  repo_pkg="$tmp_dir/packages-microsoft-prod.deb"
  repo_url="https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb"

  echo "[INSTALL] PowerShell repository for Ubuntu ${VERSION_ID}"
  if ! curl --fail --location --proto '=https' --tlsv1.2 "$repo_url" --output "$repo_pkg"; then
    echo "[FAIL] Microsoft package repository is unavailable for Ubuntu ${VERSION_ID}." >&2
    echo "Install PowerShell 7 using Microsoft's supported instructions, then rerun --check." >&2
    exit 1
  fi

  run_root dpkg -i "$repo_pkg"
  run_root apt-get update
  run_root apt-get install -y powershell
fi

show_state
if ! command -v pwsh >/dev/null 2>&1; then
  echo "[FAIL] pwsh is still unavailable after installation." >&2
  exit 1
fi

echo "UBUNTU HOST FOUNDATION READY"
echo "Next: ./sanro-dev.sh bootstrap -ProjectRoot /path/to/project -InstallMissing"
