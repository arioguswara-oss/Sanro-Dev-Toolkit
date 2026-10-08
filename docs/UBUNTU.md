# Ubuntu Support

Status: **V1.3.3 DONE_SOURCE / UBUNTU RUNTIME VERIFIED**

SANRO Dev Toolkit uses one PowerShell Core codebase on Windows and Ubuntu. Ubuntu uses PowerShell 7 (`pwsh`) plus the small `sanro-dev.sh` launcher. The goal is to keep the same handoff/status/context/check/test workflow when the SANRO agent moves from Rio's Windows laptop to an always-on Ubuntu VPS.

## Supported baseline

- Ubuntu Server x86_64
- PowerShell 7 (`pwsh`)
- Git
- Node.js/npm when required by the target project
- ripgrep (`rg`) for fast context search
- optional `fd`/`fdfind` and `ast-grep`

The Ubuntu bootstrap intentionally does not contain production credentials or hosting secrets.

## Fresh Ubuntu host

Install Git first if needed, clone the toolkit, then run the explicit host installer:

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/arioguswara-oss/Sanro-Dev-Toolkit.git
cd Sanro-Dev-Toolkit
./bootstrap-ubuntu.sh --check
./bootstrap-ubuntu.sh --install
```

`--check` is non-installing. `--install` is an explicit mutating action: it installs base OS packages and PowerShell 7 using Microsoft-supported sources.

The installer prefers Microsoft's Ubuntu package repository. If that repository is registered successfully but does not yet expose the `powershell` package for the current Ubuntu LTS, V1.3.x falls back to Microsoft's official universal PowerShell `.deb` published from the PowerShell GitHub release. The fallback defaults to the pinned release used by this toolkit and can be explicitly overridden with `SANRO_POWERSHELL_VERSION` when a reviewed update is required.

## Project bootstrap

After the application repository has a reviewed `sanro-dev.project.json`:

```bash
./sanro-dev.sh bootstrap -ProjectRoot /opt/sanro/projects/app -InstallMissing
./sanro-dev.sh handoff   -ProjectRoot /opt/sanro/projects/app
./sanro-dev.sh status    -ProjectRoot /opt/sanro/projects/app
./sanro-dev.sh context   -ProjectRoot /opt/sanro/projects/app -Query subscription
./sanro-dev.sh check     -ProjectRoot /opt/sanro/projects/app
./sanro-dev.sh test      -ProjectRoot /opt/sanro/projects/app -Filter subscription
```

Without `-InstallMissing`, the toolkit only checks required/optional tools before dependency restore. Use `-SkipDependencies` when you want a tool/environment check without running project dependency commands such as `npm ci`.

## Cross-platform command compatibility

V1.3.x resolves configured commands per platform:

- Windows: canonical `npm`/`npx` resolve to `npm.cmd`/`npx.cmd`.
- Ubuntu/Linux: legacy project configs that still contain `npm.cmd` resolve to `npm`.
- Ubuntu's `fd-find` package exposes `fdfind`; the toolkit accepts it as the Linux implementation of configured tool `fd`.

V1.3.2 corrected configured argument forwarding and tool-version rendering. V1.3.3 additionally isolates child command stdout from the helper return value: command output is streamed to the console while callers receive only the scalar exit code. This is required for focused test output and reliable failure propagation on both Windows and Ubuntu.

The legacy `npm.cmd` compatibility path was exercised successfully on the real Ubuntu 26.04.1 pilot VPS: the toolkit resolved `npm.cmd` to Linux `npm`, ran the disposable focused test, produced `tests 1 / pass 1 / fail 0`, and returned exit code `0`.

New Node templates use canonical `npm`, but existing SANRO project configs do not need to be rewritten only for Linux compatibility.

## Ubuntu package behavior

`sanro-dev.sh bootstrap ... -InstallMissing` delegates to `tools/bootstrap-ubuntu.ps1`. It can install mapped project tools with `apt-get` (`git`, `nodejs`/`npm`, `ripgrep`, `fd-find`) and can install optional `ast-grep` through npm.

A project's `minimumNodeMajor` is still authoritative. If Ubuntu's repository provides a Node.js version below that minimum, bootstrap fails safely and asks for a supported Node.js LTS installation; it does not silently weaken the project requirement or execute an unreviewed third-party Node installer.

## Recovery snapshot

`./sanro-dev.sh snapshot` chooses the current user's home directory on either Windows or Linux and writes to `SANRO-Recovery` unless `-OutputDirectory` is provided.

The archive remains source-only and excludes common secret/credential filename patterns. Real Ubuntu validation created a recovery ZIP successfully and a filename-level review of the observed archive found no `.env`, common SSH private-key, PEM/key, credential/secret JSON, token-like, or password-like names. This is filename-level exclusion evidence, not a semantic secret scanner for arbitrary file contents.

## Safety boundary for the SANRO Super Agent VPS

Ubuntu runtime verification does not grant permission to mutate production. The VPS may automate source development, tests, Git/worktree operations, non-production builds, and authorized read-only monitoring. Production deploy, production DB mutation/migration, secret changes, runtime restart/reconfiguration, default-OFF activation, destructive Git actions, and LOCKED behavior changes remain Rio-approval gates.

## Runtime verification

SANRO Dev Toolkit V1.3.3 is **UBUNTU RUNTIME VERIFIED** for the tested Ubuntu 26.04.1 LTS pilot-host baseline.

Verified evidence includes:

1. `bootstrap-ubuntu.sh --check` and explicit `--install`, including the supported universal PowerShell `.deb` fallback when the apt repository did not expose `powershell` on the pilot host.
2. `./sanro-dev.sh help` through `pwsh`.
3. `handoff`, `status`, `context`, `check`, focused `test`, and `snapshot` against a disposable/non-production SANRO repository.
4. Legacy `npm.cmd` project configuration resolving and running successfully on Ubuntu.
5. Filename-level recovery archive review with no observed sensitive-name matches.
6. GitHub Actions cross-platform helper validation on Ubuntu and Windows.

This verification applies to the observed baseline and should not be generalized to every Linux distribution or future package/runtime version without further evidence.
