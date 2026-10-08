# Ubuntu Runtime Validation — 2026-10-08

Status: **UBUNTU RUNTIME VERIFIED / V1.3.3**

This document records the first real Ubuntu runtime verification for SANRO Dev Toolkit V1.3.3 on the SANRO Super Agent pilot VPS.

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

A filename-level safety review was then run against the ZIP without extraction. The archive contained 32 files, and the sensitive-name scan returned no matches for `.env` / `.env.*`, common SSH private-key names, PEM/key files, credential/secret JSON names, token-like names, or password-like names. This verifies the intended filename-based exclusion behavior for the observed recovery archive. It does not claim semantic scanning of arbitrary file contents beyond the configured snapshot exclusion contract.

## Legacy `npm.cmd` compatibility evidence

The disposable project configuration was temporarily changed so the focused-test command used legacy Windows-style `npm.cmd` instead of canonical `npm`.

On Ubuntu, the toolkit resolved that configured command to Linux `npm` and executed the focused test successfully. The npm script invoked `node --test test/validation.test.js`, TAP reported `tests 1`, `pass 1`, `fail 0`, and the immediately observed shell exit value was `legacy_npmcmd_exit=0`.

This verifies the V1.3.x compatibility contract that existing SANRO project configs containing `npm.cmd` can run on Ubuntu without being rewritten only for platform naming differences.

## Real SANRO Superadmin context-recovery evidence

After Ubuntu runtime verification, the pilot VPS authenticated to GitHub using a dedicated machine SSH key and cloned the real `arioguswara-oss/Sanro-SuperAdmin` repository on the active development branch `codex/superadmin-v030-baseline-audit-20261004`.

The Superadmin project adapter was updated so its `handoff` configuration points at the authoritative shared-memory files: `AGENTS.md`, `docs/SUPERADMIN_WORKBOARD.md`, `docs/CHECKPOINT_V0_3_8_WIP.md`, `SANRO_DEVELOPMENT_RULES.md`, and `SUPERADMIN_PROJECT_OPERATING_RULES.md`.

On the VPS, `status` successfully reported the real Superadmin repository, branch/working tree, HEAD, and required tooling. `handoff` completed and emitted recent commit context plus the read-only next-action guidance. A scoped `context -Query "Proxy/TLS"` search then recovered current Proxy/TLS release-gate evidence from the real repository, including checkpoint/workboard/release-gate references and the fact that Proxy/TLS remains a separate hard deployment gate.

This is the first verified real-project demonstration that the SANRO Super Agent VPS can recover SANRO Superadmin context directly from GitHub/shared-memory files without reconstructing the project history from chat. This evidence is read-only and does not prove Hosting/production state or grant mutation authority.

## Security baseline observed before toolkit validation

The pilot VPS was prepared with a non-root `sanro` user using SSH public-key authentication and sudo. UFW is enabled with SSH allowed. Effective OpenSSH settings were verified to include:

- `PermitRootLogin no`
- `PasswordAuthentication no`
- `KbdInteractiveAuthentication no`
- `PubkeyAuthentication yes`
- `MaxAuthTries 3`

A new root SSH login attempt was rejected. Existing root setup sessions were closed after the non-root key path was proven.

## Verification conclusion

SANRO Dev Toolkit V1.3.3 is **UBUNTU RUNTIME VERIFIED** for the tested Ubuntu 26.04.1 LTS pilot-host baseline.

Verified scope includes host bootstrap/fallback, launcher, project bootstrap, `handoff`, `status`, `context`, `check`, focused `test`, snapshot creation, filename-level recovery exclusion review, legacy `npm.cmd` resolution on Linux, the cross-platform helper CI path, and real-project context recovery against SANRO Superadmin.

This verification does **not** grant production mutation permission and does not prove every Linux distribution or future package version. Production deploys, production database mutation/migration, credential changes, runtime restart/reconfiguration, default-OFF activation, destructive Git actions, and LOCKED behavior changes remain explicit Rio approval gates.
