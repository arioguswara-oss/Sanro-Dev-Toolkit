# Ubuntu Runtime Validation — 2026-10-08

Status: **IN_PROGRESS / HOST FOUNDATION VERIFIED / TOOLKIT LAUNCHER VERIFIED / PROJECT BOOTSTRAP VERIFIED / CORE COMMANDS VERIFIED / SNAPSHOT VERIFIED / FULL TOOLKIT RUNTIME PENDING**

This document records the first real Ubuntu runtime evidence for SANRO Dev Toolkit V1.3.x on the SANRO Super Agent pilot VPS.

## Environment observed

- Provider: Contabo
- OS: Ubuntu 26.04.1 LTS x86_64
- CPU: 4 vCPU AMD EPYC
- RAM: approximately 7.7 GiB usable
- Root filesystem: approximately 96 GiB
- Toolkit path: `/opt/sanro/toolkit`
- PowerShell: 7.6.6
- Node.js observed in the disposable project: 22.22.1
- npm observed in the disposable project: 9.2.0

No VPS IP address, password, SSH private key, token, or production credential is recorded here.

## Host foundation evidence

The following real-host observations passed:

1. Toolkit repository cloned cleanly from GitHub.
2. `./bootstrap-ubuntu.sh --check` correctly detected Git and curl and initially reported PowerShell as missing.
3. The Ubuntu 26.04 Microsoft apt repository registration succeeded, but the `powershell` package was not available through apt on this host.
4. V1.3.1 universal Microsoft PowerShell `.deb` fallback was exercised successfully on the real host.
5. A subsequent `./bootstrap-ubuntu.sh --check` reported Git, curl, and `pwsh` as available.
6. `pwsh --version` reported PowerShell 7.6.6.
7. `./sanro-dev.sh help` launched successfully through PowerShell 7 and displayed the expected cross-platform help output.

## Disposable project bootstrap evidence

A disposable non-production project at `/opt/sanro/validation-app` was initialized from the `sanro-node` template. Its generated configuration used canonical `npm`, required Git/Node/npm/ripgrep, optional fd/ast-grep, minimum Node major 20, and the normal SANRO handoff/safety defaults.

The real Ubuntu project bootstrap command was exercised with `-InstallMissing -SkipDependencies`. It completed successfully, installed/checked required tooling including ripgrep, intentionally skipped dependency restore, and ended with `RECOVERY BOOTSTRAP COMPLETE`.

The disposable project was committed locally and verified with a clean working tree so toolkit commands had a valid HEAD.

## Core command evidence

Observed on the real Ubuntu VPS:

- `handoff`: PASS; completed and emitted the expected concise next-action guidance.
- `context`: PASS; the query `SANRO validation` found the expected source content.
- `check`: PASS; `git diff --check HEAD` and fast source checks completed with `FAST CHECK PASS`.
- `status`: PASS; after the V1.3.2 formatting fix, the real-host rerun displayed concrete tool versions including `fdfind 10.3.0`, `git version 2.53.0`, `v22.22.1`, `9.2.0`, and `ripgrep 15.1.0`.
- focused `test`: PASS on V1.3.3; the toolkit displayed the Node TAP summary with `tests 1`, `pass 1`, `fail 0`, and the immediately observed shell exit code was `0`.

## Focused-test defect resolution

The disposable project's direct `node --test test/validation.test.js` initially proved the test itself was healthy and returned exit code `0`.

V1.3.2 corrected configured argument forwarding but still allowed child stdout to flow into the PowerShell success pipeline, so callers could capture command output together with the numeric exit code. V1.3.3 changed `Invoke-SanroConfiguredCommand` to stream child stdout to the host while returning only a scalar integer exit code.

The real VPS rerun on V1.3.3 displayed the full TAP output and returned exit code `0`. GitHub Actions run #15 for the follow-up CI probe also completed successfully, covering both Ubuntu and Windows command-resolution/helper behavior.

## Recovery snapshot evidence

The real VPS executed `./sanro-dev.sh snapshot -OutputDirectory /opt/sanro/recovery-validation` successfully. The toolkit produced a recovery ZIP in the requested non-production validation directory, and `ls -lh` confirmed the archive existed with a non-zero size (approximately 40 KiB). This verifies snapshot creation on Ubuntu.

Archive-content safety review is still pending. The snapshot script source excludes `.git`, `node_modules`, build/dist/coverage output, existing recovery folders, ZIPs, `.env` files, PEM/key files, common SSH private-key names, and credential/secret JSON filename patterns before compression.

## Security baseline observed before toolkit validation

The pilot VPS was prepared with a non-root `sanro` user using SSH public-key authentication and sudo. UFW is enabled with SSH allowed. Effective OpenSSH settings were verified to include:

- `PermitRootLogin no`
- `PasswordAuthentication no`
- `KbdInteractiveAuthentication no`
- `PubkeyAuthentication yes`
- `MaxAuthTries 3`

A new root SSH login attempt was rejected. Existing root setup sessions were closed after the non-root key path was proven.

## Remaining validation gate

Do **not** label the whole toolkit `UBUNTU RUNTIME VERIFIED` yet. Remaining gates are:

1. Prove Linux compatibility for a project config that still contains legacy `npm.cmd`.
2. Review recovery archive contents and confirm no secret/credential content is included.

All runtime validation remains confined to the disposable/non-production project.
