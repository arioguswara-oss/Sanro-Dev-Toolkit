# Ubuntu Support

Status: **V1.3.0 DONE_SOURCE / REAL UBUNTU RUNTIME VALIDATION PENDING**

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

`--check` is non-installing. `--install` is an explicit mutating action: it installs base OS packages and PowerShell 7 using Microsoft's Ubuntu package repository. If Microsoft's repository is not available for the Ubuntu release, the script stops and asks for a supported manual PowerShell installation instead of guessing.

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

V1.3.0 resolves configured commands per platform:

- Windows: canonical `npm`/`npx` resolve to `npm.cmd`/`npx.cmd`.
- Ubuntu/Linux: legacy project configs that still contain `npm.cmd` resolve to `npm`.
- Ubuntu's `fd-find` package exposes `fdfind`; the toolkit accepts it as the Linux implementation of configured tool `fd`.

New Node templates use canonical `npm`, but existing SANRO project configs do not need to be rewritten only for Linux compatibility.

## Ubuntu package behavior

`sanro-dev.sh bootstrap ... -InstallMissing` delegates to `tools/bootstrap-ubuntu.ps1`. It can install mapped project tools with `apt-get` (`git`, `nodejs`/`npm`, `ripgrep`, `fd-find`) and can install optional `ast-grep` through npm.

A project's `minimumNodeMajor` is still authoritative. If Ubuntu's repository provides a Node.js version below that minimum, bootstrap fails safely and asks for a supported Node.js LTS installation; it does not silently weaken the project requirement or execute an unreviewed third-party Node installer.

## Recovery snapshot

`./sanro-dev.sh snapshot` now chooses the current user's home directory on either Windows or Linux and writes to `SANRO-Recovery` unless `-OutputDirectory` is provided.

The archive remains source-only and excludes common secret/credential patterns.

## Safety boundary for the future SANRO Super Agent VPS

Ubuntu support does not grant permission to mutate production. The future VPS may automate source development, tests, Git/worktree operations, non-production builds, and authorized read-only monitoring. Production deploy, production DB mutation/migration, secret changes, runtime restart/reconfiguration, default-OFF activation, destructive Git actions, and LOCKED behavior changes remain Rio-approval gates.

## Validation gate

This source baseline was prepared in GitHub without a real SANRO Ubuntu VPS attached to this ChatGPT session. Do not label it `HOSTING VERIFIED` or `UBUNTU RUNTIME VERIFIED` yet.

First real Ubuntu validation should prove:

1. `bootstrap-ubuntu.sh --check` and explicit `--install` behavior on the selected Ubuntu LTS.
2. `./sanro-dev.sh help` launches through `pwsh`.
3. `handoff`, `status`, `context`, `check`, focused `test`, and `snapshot` work against a disposable/non-production SANRO repository.
4. Legacy `npm.cmd` project configuration works on Ubuntu through command resolution.
5. No secret is copied into toolkit Git history or recovery output.

Only after that evidence should the Ubuntu runtime be marked validated.
