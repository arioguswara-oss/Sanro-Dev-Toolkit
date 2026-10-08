# SANRO Dev Toolkit

Portable development, recovery, and cross-agent handoff toolkit for SANRO projects.

The toolkit is intentionally project-agnostic and AI-provider-independent. A project describes its own working directories, required tools, dependency install commands, test runner, and handoff/shared-memory paths in `sanro-dev.project.json`; the reusable scripts stay in this repository.

## Goals

- Recover a development machine quickly after device loss or replacement.
- Reuse the same safe workflow across SANRO Superadmin, POS, Stock, Ticket, WordPress/plugin/theme, and future projects.
- Make new SANRO repositories agent-ready from the first commit.
- Make ChatGPT <-> Codex or other-agent takeover cheap after reset/quota loss.
- Prefer focused search/test loops before broad scans or full regression.
- Keep credentials and production secrets out of Git and recovery archives.
- Run the same core workflow on Windows today and Ubuntu Server for the future SANRO Super Agent VPS.

## Windows quick start

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
.\sanro-dev.ps1 handoff   -ProjectRoot "C:\path\to\project"
.\sanro-dev.ps1 status    -ProjectRoot "C:\path\to\project"
.\sanro-dev.ps1 check     -ProjectRoot "C:\path\to\project"
.\sanro-dev.ps1 test      -ProjectRoot "C:\path\to\project"
```

## Ubuntu quick start

V1.3.0 adds an Ubuntu path for the future always-on SANRO agent environment while keeping the PowerShell Core logic shared with Windows.

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/arioguswara-oss/Sanro-Dev-Toolkit.git
cd Sanro-Dev-Toolkit
./bootstrap-ubuntu.sh --check
./bootstrap-ubuntu.sh --install
```

Then use the Linux launcher:

```bash
./sanro-dev.sh bootstrap -ProjectRoot /opt/sanro/projects/app -InstallMissing
./sanro-dev.sh handoff   -ProjectRoot /opt/sanro/projects/app
./sanro-dev.sh status    -ProjectRoot /opt/sanro/projects/app
./sanro-dev.sh context   -ProjectRoot /opt/sanro/projects/app -Query subscription
./sanro-dev.sh check     -ProjectRoot /opt/sanro/projects/app
./sanro-dev.sh test      -ProjectRoot /opt/sanro/projects/app -Filter subscription
```

`bootstrap-ubuntu.sh --install` explicitly changes the Ubuntu host by installing prerequisites and PowerShell. The normal toolkit safety rules still apply; Ubuntu support does not authorize production changes.

See `docs/UBUNTU.md` for the source/runtime validation boundary and VPS-oriented guidance.

## Start a new project

For a normal generic project on Windows:

```powershell
.\sanro-dev.ps1 init -ProjectRoot "C:\path\to\project" -Template node -ProjectName "My Project"
```

For a new SANRO Node project:

```powershell
.\sanro-dev.ps1 init -ProjectRoot "C:\path\to\project" -Template sanro-node -ProjectName "SANRO App"
```

Ubuntu uses the same templates:

```bash
./sanro-dev.sh init -ProjectRoot /opt/sanro/projects/app -Template sanro-node -ProjectName "SANRO App"
```

For a new SANRO WordPress/plugin/theme project, use template `sanro-wordpress`.

SANRO templates create `sanro-dev.project.json` and also create a default `AGENTS.md` when one does not already exist. Existing `AGENTS.md` is preserved.

Available templates:

`generic`, `node`, `wordpress`, `sanro-node`, `sanro-wordpress`.

## Commands

```text
sanro-dev.ps1 / sanro-dev.sh

init       Create sanro-dev.project.json from a template
bootstrap  Check/install supported tools and restore dependencies
status     Show repository/branch/working tree/platform/tool status
handoff    Show concise branch/HEAD/shared-memory/change/recent-commit context
context    Fast literal filename/content search with ripgrep
check      Diff hygiene + syntax checks for changed files
test       Focused or full configured tests
snapshot   Create an offline recovery ZIP of this toolkit
```

## Cross-platform command resolution

Project configuration should prefer canonical command names such as `npm`. On Windows the toolkit resolves `npm` and `npx` to their `.cmd` launchers. On Ubuntu/Linux it also accepts older SANRO configs that contain `npm.cmd` and resolves them back to `npm`.

Ubuntu's `fd-find` package exposes `fdfind`; the toolkit recognizes it as the Linux implementation of configured tool `fd`.

This allows existing project adapters to move between Windows and Ubuntu without duplicating project rules only for command-name differences.

## Cross-agent handoff

For long-running SANRO projects, add a `handoff` object to `sanro-dev.project.json`:

```json
{
  "handoff": {
    "agentsFile": "AGENTS.md",
    "workboard": "docs/WORKBOARD.md",
    "checkpoint": "docs/CHECKPOINT.md",
    "rules": ["SANRO_DEVELOPMENT_RULES.md"],
    "remoteIsSourceOfTruth": true,
    "recentCommitCount": 8
  }
}
```

Then run `handoff` using either launcher for the current OS.

The handoff command is read-only. It summarizes branch, HEAD, upstream presence, working-tree change count, configured shared-memory files, safe changed paths, and recent commit subjects. Sensitive-looking paths are redacted. It does not read file contents and does not prove hosting/production state.

This gives ChatGPT, Codex, a local LLM, or another compatible agent a compact re-entry point after reset without forcing a broad repository audit.

## Standard agent workflow

For SANRO repositories the default efficient loop is:

```text
handoff/status -> sync -> relevant context -> scoped work -> check -> focused test -> coherent commit -> full regression near batch end -> handoff
```

This is designed to reduce repeated broad scans, unnecessary full-test runs, and reset/quota recovery cost without weakening project-specific safety gates.

See `docs/SANRO_PROJECT_STANDARD.md` for the baseline expected in new SANRO repositories.

## Security boundary

Never store `.env`, database passwords, API/OAuth secrets, session secrets, hosting credentials, SSH private keys, collector credentials, or sensitive database dumps in this repository or generated recovery ZIPs. Restore secrets separately from an encrypted backup/secret manager.

The toolkit is not a production-approval mechanism. Production deploy, DB mutation/migration, credential changes, restart/reconfiguration, destructive Git operations, default-OFF activation, and LOCKED behavior changes remain subject to project-specific approval rules.

See `SECURITY.md` and `docs/RECOVERY.md`.

## Existing SANRO projects

Existing repositories can adopt the toolkit incrementally. Keep stricter existing `AGENTS.md` and production rules, add/review `sanro-dev.project.json`, configure `handoff` paths, then validate toolkit commands before treating the repository as ready.

The Superadmin, POS/Stock, and Ticket examples are under `examples/`; project-specific paths should be verified against each repository before adoption.

## Ubuntu validation status

V1.3.0 is a **source baseline** for Ubuntu. It must still be exercised on a real Ubuntu SANRO machine/VPS before anyone claims `UBUNTU RUNTIME VERIFIED`, `HOSTING VERIFIED`, or equivalent runtime evidence.

## Origin

The first toolkit scripts were proven in `arioguswara-oss/Sanro-SuperAdmin`. This standalone repository makes the recovery/tooling/handoff layer reusable without coupling it to one application repository or one AI provider.
