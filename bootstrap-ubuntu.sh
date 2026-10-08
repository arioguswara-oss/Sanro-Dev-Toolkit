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

install_powershell_universal_deb() {
  local arch version tmp_dir deb_file deb_url
  arch="$(dpkg --print-architecture)"
  if [[ "$arch" != "amd64" ]]; then
    echo "[FAIL] Automatic universal PowerShell fallback currently supports amd64 only. Detected: $arch" >&2
    echo "Use Microsoft's supported manual installation instructions for this architecture." >&2
    return 1
  fi

  # Pinned supported LTS fallback. Override explicitly when required:
  # SANRO_POWERSHELL_VERSION=7.x.y ./bootstrap-ubuntu.sh --install
  version="${SANRO_POWERSHELL_VERSION:-7.6.6}"
  tmp_dir="$(mktemp -d)"
  deb_file="$tmp_dir/powershell.deb"
  deb_url="https://github.com/PowerShell/PowerShell/releases/download/v${version}/powershell_${version}-1.deb_amd64.deb"

  echo "[FALLBACK] apt repository does not currently expose package 'powershell'."
  echo "[INSTALL] Microsoft-supported universal PowerShell ${version} .deb"
  if ! curl --fail --location --proto '=https' --tlsv1.2 "$deb_url" --output "$deb_file"; then
    rm -rf "$tmp_dir"
    echo "[FAIL] Could not download the official PowerShell universal .deb for version ${version}." >&2
    echo "Review Microsoft's current Ubuntu installation instructions before retrying." >&2
    return 1
  fi

  if ! run_root dpkg -i "$deb_file"; then
    run_root apt-get install -f -y
    run_root dpkg -i "$deb_file"
  fi
  rm -rf "$tmp_dir"
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
echo "This action installs OS packages and PowerShell 7 using Microsoft-supported sources."

run_root apt-get update
run_root apt-get install -y ca-certificates curl git gnupg

if ! command -v pwsh >/dev/null 2>&1; then
  tmp_dir="$(mktemp -d)"
  repo_pkg="$tmp_dir/packages-microsoft-prod.deb"
  repo_url="https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb"

  echo "[INSTALL] PowerShell repository for Ubuntu ${VERSION_ID}"
  if curl --fail --location --proto '=https' --tlsv1.2 "$repo_url" --output "$repo_pkg"; then
    run_root dpkg -i "$repo_pkg"
    run_root apt-get update
    if apt-cache show powershell >/dev/null 2>&1; then
      run_root apt-get install -y powershell
    else
      install_powershell_universal_deb
    fi
  else
    echo "[WARN] Microsoft Ubuntu repository bootstrap is unavailable for Ubuntu ${VERSION_ID}."
    install_powershell_universal_deb
  fi
  rm -rf "$tmp_dir"
fi

show_state
if ! command -v pwsh >/dev/null 2>&1; then
  echo "[FAIL] pwsh is still unavailable after installation." >&2
  exit 1
fi

echo "UBUNTU HOST FOUNDATION READY"
echo "Next: ./sanro-dev.sh bootstrap -ProjectRoot /path/to/project -InstallMissing"
