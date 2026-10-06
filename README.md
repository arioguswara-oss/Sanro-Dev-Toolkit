# SANRO Dev Toolkit

Portable development and recovery toolkit for SANRO projects.

The toolkit is intentionally project-agnostic. A project describes its own working directories, required tools, dependency install commands, and test runner in `sanro-dev.project.json`; the reusable PowerShell scripts stay in this repository.

## Goals

- Recover a development machine quickly after device loss or replacement.
- Reuse the same safe workflow across SANRO Superadmin, POS, Stock, Ticket, WordPress/plugin/theme, and future projects.
- Make new SANRO repositories Codex-ready from the first commit.
- Prefer focused search/test loops before broad scans or full regression.
- Keep credentials and production secrets out of Git and recovery archives.

## Quick start on a new Windows machine

Install Git first if necessary:

```powershell
winget install --id Git.Git -e
```

Clone this toolkit:

```powershell
git clone https://github.com/arioguswara-oss/Sanro-Dev-Toolkit.git
cd Sanro-Dev-Toolkit
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

For an existing SANRO project that already contains `sanro-dev.project.json`:

```powershell
.\sanro-dev.ps1 bootstrap -ProjectRoot "C:\path\to\project" -InstallMissing
.\sanro-dev.ps1 status    -ProjectRoot "C:\path\to\project"
.\sanro-dev.ps1 check     -ProjectRoot "C:\path\to\project"
.\sanro-dev.ps1 test      -ProjectRoot "C:\path\to\project"
```

## Start a new project

For a normal generic project:

```powershell
.\sanro-dev.ps1 init -ProjectRoot "C:\path\to\project" -Template node -ProjectName "My Project"
```

For a new SANRO Node project that should be Codex-ready from the start:

```powershell
.\sanro-dev.ps1 init -ProjectRoot "C:\path\to\project" -Template sanro-node -ProjectName "SANRO App"
```

For a new SANRO WordPress/plugin/theme project:

```powershell
.\sanro-dev.ps1 init -ProjectRoot "C:\path\to\project" -Template sanro-wordpress -ProjectName "SANRO Plugin"
```

SANRO templates create `sanro-dev.project.json` and also create a default `AGENTS.md` when one does not already exist. Existing `AGENTS.md` is preserved.

Available templates:

`generic`, `node`, `wordpress`, `sanro-node`, `sanro-wordpress`.

## Commands

```text
sanro-dev.ps1 init       Create sanro-dev.project.json from a template
sanro-dev.ps1 bootstrap  Check/install supported tools and restore dependencies
sanro-dev.ps1 status     Show repository/branch/working tree/tool status
sanro-dev.ps1 context    Fast literal filename/content search with ripgrep
sanro-dev.ps1 check      Diff hygiene + syntax checks for changed files
sanro-dev.ps1 test       Focused or full configured tests
sanro-dev.ps1 snapshot   Create an offline recovery ZIP of this toolkit
```

## Standard Codex workflow

For SANRO repositories the default efficient loop is:

```text
status -> sync -> relevant context -> scoped work -> check -> focused test -> coherent commit -> full regression near batch end -> handoff
```

This is designed to reduce repeated broad scans, unnecessary full-test runs, and reset/quota recovery cost without weakening project-specific safety gates.

See `docs/SANRO_PROJECT_STANDARD.md` for the baseline expected in new SANRO repositories.

## Security boundary

Never store `.env`, database passwords, API/OAuth secrets, session secrets, hosting credentials, SSH private keys, collector credentials, or sensitive database dumps in this repository or generated recovery ZIPs. Restore secrets separately from an encrypted backup/secret manager.

See `SECURITY.md` and `docs/RECOVERY.md`.

## Existing SANRO projects

Existing repositories can adopt the toolkit incrementally. Keep stricter existing `AGENTS.md` and production rules, add/review `sanro-dev.project.json`, then validate toolkit commands before treating the repository as ready.

The Superadmin example remains in `examples/sanro-superadmin.project.json`; additional project-specific examples can be added without changing the reusable core.

## Origin

The first toolkit scripts were proven in `arioguswara-oss/Sanro-SuperAdmin`. This standalone repository makes the recovery/tooling layer reusable without coupling it to one application repository.
