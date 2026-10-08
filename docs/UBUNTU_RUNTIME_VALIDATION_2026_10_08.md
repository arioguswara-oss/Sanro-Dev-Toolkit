# Ubuntu Runtime Validation — 2026-10-08

Status: **IN_PROGRESS / HOST FOUNDATION VERIFIED / TOOLKIT LAUNCHER VERIFIED / FULL TOOLKIT RUNTIME PENDING**

This document records the first real Ubuntu runtime evidence for SANRO Dev Toolkit V1.3.x on the SANRO Super Agent pilot VPS.

## Environment observed

- Provider: Contabo
- OS: Ubuntu 26.04.1 LTS x86_64
- CPU: 4 vCPU AMD EPYC
- RAM: approximately 7.7 GiB usable
- Root filesystem: approximately 96 GiB
- Toolkit path: `/opt/sanro/toolkit`
- Toolkit version after the PowerShell fallback fix: `1.3.1`

No VPS IP address, password, SSH private key, token, or production credential is recorded here.

## Host foundation evidence

The following real-host observations passed:

1. Toolkit repository cloned cleanly from GitHub.
2. `VERSION` reported `1.3.1` after pulling the Ubuntu fallback fix.
3. `./bootstrap-ubuntu.sh --check` correctly detected Git and curl and initially reported PowerShell as missing.
4. The initial Ubuntu 26.04 Microsoft apt repository registration succeeded, but the `powershell` package was not yet available through apt on this host.
5. V1.3.1 universal Microsoft PowerShell `.deb` fallback was then exercised successfully on the real host.
6. A subsequent `./bootstrap-ubuntu.sh --check` reported Git, curl, and `pwsh` as available.
7. `pwsh --version` reported `PowerShell 7.6.6`.
8. `./sanro-dev.sh help` launched successfully through PowerShell 7 and displayed the expected cross-platform command/help output.

Observed tool versions included:

- Git `2.53.0`
- curl `8.18.0`
- PowerShell `7.6.6`

## Security baseline observed before toolkit validation

The pilot VPS was prepared with a non-root `sanro` user using SSH public-key authentication and sudo. UFW is enabled with SSH allowed. Effective OpenSSH settings were verified to include:

- `PermitRootLogin no`
- `PasswordAuthentication no`
- `KbdInteractiveAuthentication no`
- `PubkeyAuthentication yes`
- `MaxAuthTries 3`

A new root SSH login attempt was rejected. Existing root setup sessions were closed after the non-root key path was proven.

## Remaining validation gate

Do **not** label the whole toolkit `UBUNTU RUNTIME VERIFIED` yet. The following remain to be exercised on this real Ubuntu host:

1. `handoff`
2. `status`
3. `context`
4. `check`
5. focused `test`
6. `snapshot`
7. Linux compatibility for a project config that still contains legacy `npm.cmd`
8. recovery output review confirming that no secret/credential content is included

These should be tested against a disposable or non-production SANRO project/config before full Ubuntu runtime validation is claimed.
