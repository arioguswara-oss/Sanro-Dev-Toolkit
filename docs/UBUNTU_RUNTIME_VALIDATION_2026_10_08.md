# Ubuntu Runtime Validation — 2026-10-08

Status: **IN_PROGRESS / HOST FOUNDATION VERIFIED / TOOLKIT LAUNCHER VERIFIED / PROJECT BOOTSTRAP VERIFIED / STATUS VERIFIED / FOCUSED TEST FIX PENDING RERUN / FULL TOOLKIT RUNTIME PENDING**

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

- `handoff`: completed and emitted the expected concise next-action guidance.
- `context`: PASS; the query `SANRO validation` found the expected source content.
- `check`: PASS; `git diff --check HEAD` and fast source checks completed with `FAST CHECK PASS`.
- `status`: V1.3.1 exposed `System.Object[]` instead of concrete tool versions. V1.3.2 corrected this. The real-host rerun displayed concrete values including `fdfind 10.3.0`, `git version 2.53.0`, `v22.22.1`, `9.2.0`, and `ripgrep 15.1.0`; status output is therefore verified.

### Focused-test diagnosis

The disposable project's direct command:

```bash
node --test test/validation.test.js
```

ran one test successfully and returned exit code `0`.

V1.3.2 corrected configured argument forwarding, but the toolkit invocation still printed only `SANRO TEST RUNNER - FOCUSED: validation` and returned exit code `0` without displaying the TAP summary. The corresponding V1.3.2 GitHub Actions run also failed its configured-command probe on both Ubuntu and Windows.

The defect was traced to `Invoke-SanroConfiguredCommand`: child stdout was emitted on the PowerShell success pipeline, so callers assigning the helper result captured both command output and the numeric exit code. V1.3.3 changes the helper to stream child stdout to the host and return only a scalar integer exit code. CI now asserts both argument forwarding and scalar exit-code isolation, including propagation of a non-zero exit code.

V1.3.3 is **DONE_SOURCE** for this defect, but focused test runtime remains pending until the real VPS pulls V1.3.3 and the toolkit test is rerun with visible TAP output.

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

1. Pull V1.3.3 on the real VPS and rerun the focused toolkit test; visible TAP output and exit `0` are required.
2. Confirm V1.3.3 GitHub Actions passes on Ubuntu and Windows.
3. Exercise `snapshot`.
4. Prove Linux compatibility for a project config that still contains legacy `npm.cmd`.
5. Review recovery output and confirm no secret/credential content is included.

All runtime validation remains confined to the disposable/non-production project.
