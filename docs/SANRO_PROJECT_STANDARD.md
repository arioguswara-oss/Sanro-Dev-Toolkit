# SANRO Project Development Standard

This document defines the default development bootstrap standard for new SANRO repositories that will be worked on by Rio, ChatGPT, Codex, local LLM workers, or other engineering agents.

## Required baseline for every new SANRO repository

Every new SANRO project should contain:

1. `sanro-dev.project.json` — project-specific toolkit configuration.
2. `AGENTS.md` — concise entry rules for agents.
3. `.gitignore` rules that exclude secrets, local credentials, generated dependency folders, build output, and recovery archives as applicable.
4. A clear active branch/release policy in project docs when the project has production impact.
5. Remote commits as the durable handoff state; important work must not live only in one computer/session.

Projects with multiple agents, production gates, or long-running development should also keep a small shared workboard/checkpoint so ownership, blockers, evidence, and next action survive resets.

## Standard workflow

Normal continuation should be:

`handoff/status -> sync -> relevant context -> scoped work -> check -> focused test -> coherent commit -> full regression near batch end -> handoff`

This ordering is intended to reduce token/quota use while keeping the work reproducible and safe.

## Cross-agent handoff contract

Long-running SANRO repositories should configure a `handoff` block in `sanro-dev.project.json`:

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

`workboard`, `checkpoint`, and `rules` may be empty when a small project does not use them. Do not invent paths: use files that actually exist in the target repository.

The toolkit `handoff` command is intentionally read-only. It reports repository identity/context, configured shared-memory file presence, bounded recent commits, and changed-path summaries without reading business data or secret contents.

When multiple agents are active, they should use separate lanes/file ownership and preferably separate Git worktrees. When one resets or loses quota, another resumes from remote HEAD and current workboard/checkpoint evidence rather than stale chat memory.

## Platform standard

The project adapter must be portable between supported developer environments whenever practical.

- Windows uses `sanro-dev.ps1`.
- Ubuntu uses PowerShell 7 through `sanro-dev.sh`.
- Project configs should prefer canonical executable names such as `npm`, not OS-specific wrappers.
- V1.3 still accepts legacy `npm.cmd` project configs on Ubuntu through platform-aware command resolution.
- Do not duplicate business rules merely because an agent moves from Windows to Ubuntu.

Ubuntu host/bootstrap details live in `docs/UBUNTU.md`.

## Agent-ready initialization

For a new Node-based SANRO project on Windows:

```powershell
.\sanro-dev.ps1 init -ProjectRoot "C:\work\My-SANRO-App" -Template sanro-node -ProjectName "My SANRO App"
```

On Ubuntu:

```bash
./sanro-dev.sh init -ProjectRoot /opt/sanro/projects/My-SANRO-App -Template sanro-node -ProjectName "My SANRO App"
```

For a new WordPress/plugin/theme SANRO project use template `sanro-wordpress` with the launcher for the current OS.

SANRO templates create `sanro-dev.project.json` and, when the project does not already have one, a default `AGENTS.md`. Existing `AGENTS.md` is preserved and is never silently overwritten.

After initialization, review the generated commands and paths, then run bootstrap, handoff, status, and check. Use focused tests before full regression.

## Efficiency rules

- Use `handoff` first after reset/quota loss to recover branch/HEAD/shared-memory pointers quickly.
- Use literal context search before broad repository scans.
- Read recent diffs and relevant files instead of full history.
- Run focused tests before full suites.
- Run the full suite once near completion of a coherent batch unless risk requires more.
- Commit coherent batches so a reset or quota limit does not lose progress.
- Do not create repeated status summaries when Git history/workboard already contains the state.
- Prefer script/deterministic checks over LLM calls for routine status, health, and housekeeping when possible.

## Safety boundary

The toolkit is not a production approval mechanism. It must never be used to bypass project gates.

Never place secrets in Git or recovery ZIPs, including `.env`, passwords, API/OAuth secrets, tokens, private keys, session secrets, production credentials, or sensitive database dumps.

Production deploys, migrations, credential changes, destructive operations, runtime reconfiguration, and default-OFF feature activation require the applicable project approval process.

## Existing projects

Existing SANRO repositories can adopt the standard incrementally:

1. Add or review `sanro-dev.project.json`.
2. Keep existing stricter `AGENTS.md`; do not replace project-specific rules with the generic template.
3. Configure only real `handoff` paths for AGENTS/workboard/checkpoint/rules.
4. Validate `handoff`, `status`, `context`, `check`, focused test, and full test commands on the intended OS.
5. Only then treat the repository as SANRO Dev Toolkit-ready for that runtime.

The standalone toolkit is reusable and AI-provider-independent; each application repository remains responsible for its own business rules, production gates, branch policy, lane ownership, and test commands.
