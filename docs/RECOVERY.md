# Recovery Guide

This repository is the portable recovery source for SANRO development tooling.

## New Windows machine

1. Install Git if it is not available:

```powershell
winget install --id Git.Git -e
```

2. Clone the toolkit:

```powershell
git clone https://github.com/arioguswara-oss/Sanro-Dev-Toolkit.git
cd Sanro-Dev-Toolkit
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

3. Clone the SANRO application repository you need to work on.

4. Ensure that application repository contains a reviewed `sanro-dev.project.json`. If it does not, initialize one from a template:

```powershell
.\sanro-dev.ps1 init -ProjectRoot "C:\work\project" -Template node -ProjectName "SANRO Project"
```

5. Restore supported development tooling and project dependencies:

```powershell
.\sanro-dev.ps1 bootstrap -ProjectRoot "C:\work\project" -InstallMissing
```

6. Validate the recovered environment:

```powershell
.\sanro-dev.ps1 handoff -ProjectRoot "C:\work\project"
.\sanro-dev.ps1 status  -ProjectRoot "C:\work\project"
.\sanro-dev.ps1 check   -ProjectRoot "C:\work\project"
.\sanro-dev.ps1 test    -ProjectRoot "C:\work\project"
```

## New Ubuntu machine / future agent VPS

1. Install Git and clone the toolkit:

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/arioguswara-oss/Sanro-Dev-Toolkit.git
cd Sanro-Dev-Toolkit
```

2. Check the host foundation and explicitly install PowerShell/base prerequisites if needed:

```bash
./bootstrap-ubuntu.sh --check
./bootstrap-ubuntu.sh --install
```

3. Clone the SANRO application repository and ensure it contains a reviewed `sanro-dev.project.json`.

4. Restore supported project tools/dependencies and validate:

```bash
./sanro-dev.sh bootstrap -ProjectRoot /opt/sanro/projects/project -InstallMissing
./sanro-dev.sh handoff   -ProjectRoot /opt/sanro/projects/project
./sanro-dev.sh status    -ProjectRoot /opt/sanro/projects/project
./sanro-dev.sh check     -ProjectRoot /opt/sanro/projects/project
./sanro-dev.sh test      -ProjectRoot /opt/sanro/projects/project
```

Use `-SkipDependencies` during bootstrap when you only want to verify/install tools without running project dependency commands.

A source test PASS on either OS does not prove production/hosting state.

## Offline toolkit snapshot

Create a source-only ZIP:

Windows:

```powershell
.\sanro-dev.ps1 snapshot
```

Ubuntu:

```bash
./sanro-dev.sh snapshot
```

Default destination is the current user's home directory under `SANRO-Recovery`, for example:

```text
Windows: C:\Users\<user>\SANRO-Recovery\SANRO-Dev-Toolkit-Recovery-YYYYMMDD-HHMMSS.zip
Linux:   /home/<user>/SANRO-Recovery/SANRO-Dev-Toolkit-Recovery-YYYYMMDD-HHMMSS.zip
```

The ZIP intentionally excludes common secret/credential names and Git internals. Treat it as a tooling backup, not a secret backup.

## Credentials

SSH private keys, `.env`, tokens, database passwords, OAuth/API secrets, production credentials, and sensitive dumps must be recovered separately from encrypted storage. Do not add them to this repository just to make machine recovery easier.

## SANRO project configuration

Each application repository should own its own `sanro-dev.project.json`. That keeps this toolkit generic while allowing different dependency directories and test commands per project.

The cross-platform command resolver accepts legacy Windows-oriented `npm.cmd` configuration on Ubuntu, while new templates prefer canonical `npm`.

For SANRO Superadmin, use `examples/sanro-superadmin.project.json` as a reference and keep the authoritative copy in the Superadmin repository synchronized with its current development workflow.

## Runtime evidence boundary

Ubuntu source support is not the same as Ubuntu runtime verification. Validate the toolkit on a disposable/non-production Ubuntu project before relying on it for the future always-on SANRO agent environment.
