# Ubuntu Runtime Validation — 2026-10-08

Status: **IN_PROGRESS / HOST FOUNDATION VERIFIED / TOOLKIT LAUNCHER VERIFIED / PROJECT BOOTSTRAP VERIFIED / CORE COMMANDS PARTIAL / FULL TOOLKIT RUNTIME PENDING**

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

## Disposable project bootstrap evidence

A disposable non-production project at `/opt/sanro/validation-app` was initialized from the `sanro-node` template. Its generated configuration used canonical `npm`, required Git/Node/npm/ripgrep, optional fd/ast-grep, minimum Node major 20, and the normal SANRO handoff/safety defaults.

The real Ubuntu project bootstrap command was then exercised with `-InstallMissing -SkipDependencies`. It completed successfully, installed/checked required tooling including ripgrep, intentionally skipped dependency restore, and ended with `RECOVERY BOOTSTRAP COMPLETE`. This verifies the Ubuntu project bootstrap path without touching any SANRO production repository or running application dependency installation.

The disposable project was then committed locally and verified with a clean working tree so subsequent toolkit commands had a valid HEAD.

## Core command evidence

The first real Ubuntu core-command pass produced the following evidence:

- `handoff`: command completed and emitted the expected concise next-action guidance.
- `status`: repository/platform state was read successfully, but tool version rendering displayed `System.Object[]` for several tools instead of a concrete version string. This is treated as a real runtime formatting defect, not a full PASS for status output quality.
- `context`: PASS; the literal query `SANRO validation` found the expected content in the disposable project.
- `check`: PASS; `git diff --check HEAD` and the fast source checks completed with `FAST CHECK PASS`.
- focused `test`: the toolkit printed `SANRO TEST RUNNER - FOCUSED: validation`, but no TAP/test summary was visible before returning to the shell. This is **not** yet counted as a focused-test PASS. A direct Node test plus exit-code comparison is required to determine whether arguments were dropped or output handling is defective.

Do not manually patch the VPS copy before the toolkit source defect is diagnosed and corrected in GitHub.

## Security baseline observed before toolkit validation

The pilot VPS was prepared with a non-root `sanro` user using SSH public-key authentication and sudo. UFW is enabled with SSH allowed. Effective OpenSSH settings were verified to include:

- `PermitRootLogin no`
- `PasswordAuthentication no`
- `KbdInteractiveAuthentication no`
- `PubkeyAuthentication yes`
- `MaxAuthTries 3`

A new root SSH login attempt was rejected. Existing root setup sessions were closed after the non-root key path was proven.

## Remaining validation gate

Do **not** label the whole toolkit `UBUNTU RUNTIME VERIFIED` yet. The following remain:

1. Diagnose and correct `status` tool-version rendering.
2. Prove focused test execution with direct Node output plus toolkit exit-code evidence, then correct the toolkit if needed.
3. `snapshot`.
4. Linux compatibility for a project config that still contains legacy `npm.cmd`.
5. Recovery output review confirming that no secret/credential content is included.
6. Rerun the affected core commands after any source fix and only then promote the Ubuntu runtime status.

All validation remains confined to the disposable/non-production project.
