# {{PROJECT_NAME}} — Codex / Agent Entry Rules

This file is generated from SANRO Dev Toolkit and should be adapted only where the project needs stricter rules.

## Source of truth

- Git remote HEAD is authoritative.
- Project-specific checkpoint/workboard/rules, when present, are shared memory.
- Never recreate, overwrite, or revert newer remote work because local context is stale.
- Unpushed local work is not permanent project memory.

## Normal continuation

When Rio says `lanjut`, do real scoped work instead of returning only a plan.

1. Run SANRO Dev Toolkit `status` for this project.
2. Sync/fetch the current project branch.
3. Read this `AGENTS.md` and only the relevant workboard/checkpoint/rules sections.
4. Use toolkit `context` before any broad repository scan.
5. Take only a non-conflicting lane/scope.
6. Make the smallest coherent change.
7. Run toolkit `check`.
8. Run focused tests first; run full regression only near the end of a coherent batch.
9. Commit/push important work so another agent can resume after reset/quota loss.
10. Update project handoff/workboard/checkpoint only when status, ownership, gate, decision, or progress materially changes.

## Codex efficiency

- Do not reread long unchanged documents on every turn.
- Prefer recent diffs, exact files, and literal context search.
- Do not rerun full suites after every small edit.
- Stop scope expansion once acceptance criteria are met.
- Preserve remote evidence frequently enough that reset/quota exhaustion does not lose meaningful work.

## Parallel work

- Check ownership before editing shared files.
- Do not edit an area owned by another active agent unless ownership is explicitly transferred.
- If one lane is blocked, continue another safe independent lane.
- After reset, sync remote HEAD before doing anything else.

## Safety

Never commit or expose `.env`, passwords, API/OAuth secrets, tokens, private keys, session secrets, production credentials, sensitive dumps, or unnecessary customer data.

Production mutation, deployment, migration, credential changes, service restart/reconfiguration, destructive data operations, or enabling default-OFF production behavior require the project owner's explicit approval unless the project rules state an even stricter gate.

CI/source tests are source evidence only. They do not by themselves prove production deployment, hosting verification, or user acceptance.

## Toolkit

Typical commands from the standalone toolkit repository:

```powershell
.\sanro-dev.ps1 status  -ProjectRoot "<project-path>"
.\sanro-dev.ps1 context -ProjectRoot "<project-path>" -Query "<keyword>"
.\sanro-dev.ps1 check   -ProjectRoot "<project-path>"
.\sanro-dev.ps1 test    -ProjectRoot "<project-path>" -Filter "<keyword>"
.\sanro-dev.ps1 test    -ProjectRoot "<project-path>"
```

Project-specific rules always override generic toolkit guidance when they are stricter.
