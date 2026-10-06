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
.\sanro-dev.ps1 status -ProjectRoot "C:\work\project"
.\sanro-dev.ps1 check  -ProjectRoot "C:\work\project"
.\sanro-dev.ps1 test   -ProjectRoot "C:\work\project"
```

A source test PASS does not prove production/hosting state.

## Offline toolkit snapshot

Create a source-only ZIP:

```powershell
.\sanro-dev.ps1 snapshot
```

Default destination:

```text
%USERPROFILE%\SANRO-Recovery\SANRO-Dev-Toolkit-Recovery-YYYYMMDD-HHMMSS.zip
```

The ZIP intentionally excludes common secret/credential names and Git internals. Treat it as a tooling backup, not a secret backup.

## Credentials

SSH private keys, `.env`, tokens, database passwords, OAuth/API secrets, production credentials, and sensitive dumps must be recovered separately from encrypted storage. Do not add them to this repository just to make machine recovery easier.

## SANRO project configuration

Each application repository should own its own `sanro-dev.project.json`. That keeps this toolkit generic while allowing different dependency directories and test commands per project.

For SANRO Superadmin, use `examples/sanro-superadmin.project.json` as a reference and keep the authoritative copy in the Superadmin repository synchronized with its current development workflow.
