# SANRO Dev Toolkit

Portable development and recovery toolkit for SANRO projects.

The toolkit is intentionally project-agnostic. A project describes its own working directories, required tools, dependency install commands, and test runner in `sanro-dev.project.json`; the reusable PowerShell scripts stay in this repository.

## Goals

- Recover a development machine quickly after device loss or replacement.
- Reuse the same safe workflow across SANRO Superadmin, POS, Stock, Ticket, WordPress/plugin/theme, and future projects.
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

For a new project, create a configuration from a template first:

```powershell
.\sanro-dev.ps1 init -ProjectRoot "C:\path\to\project" -Template node -ProjectName "My Project"
```

Available templates: `generic`, `node`, and `wordpress`.

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

## Security boundary

Never store `.env`, database passwords, API/OAuth secrets, session secrets, hosting credentials, SSH private keys, collector credentials, or sensitive database dumps in this repository or generated recovery ZIPs. Restore secrets separately from an encrypted backup/secret manager.

See `SECURITY.md` and `docs/RECOVERY.md` after the baseline files are installed.

## Origin

The first toolkit scripts were proven in `arioguswara-oss/Sanro-SuperAdmin`. This standalone repository makes the recovery/tooling layer reusable without coupling it to one application repository.
