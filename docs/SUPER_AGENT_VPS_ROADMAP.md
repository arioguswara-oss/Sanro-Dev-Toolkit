# SANRO Super Agent AI — VPS Roadmap

Status: FUTURE ROADMAP / NOT YET PROVISIONED
Owner / final approver: Rio

## Direction

SANRO Dev Toolkit is being validated first on Rio's Windows laptop as the pilot environment for ChatGPT <-> Codex handoff, scoped development, focused testing, remote evidence, and recovery after reset/quota loss.

The next infrastructure milestone, after the laptop workflow is proven stable, is to move the same operating model to an always-on Linux VPS that acts as a SANRO Super Agent AI execution environment.

The VPS is NOT intended to host SANRO production applications. Its role is an always-on AI engineering and operations workstation that can build/test applications, maintain isolated worktrees, interact with GitHub, run safe automation, and perform read-only monitoring/verification of hosting and applications.

## Current first VPS candidate

Provider: Contabo
Plan candidate: Cloud VPS 4
Region preference: Singapore
Target role: SANRO Super Agent AI pilot

Current sizing target:
- 4 vCPU
- 8 GB RAM
- approximately 100 GB storage
- Linux server OS

Exact commercial specifications, price, storage type, network limits, and availability MUST be rechecked on Contabo at purchase time because provider offers can change.

## Operating system

Preferred family: Ubuntu Server LTS x86_64.

Do not hard-lock an exact Ubuntu release years in advance. At provisioning time choose the current supported LTS version that is compatible with the required agent/runtime stack.

## Pilot-to-VPS gate

Do not provision the VPS merely because the roadmap exists. First prove on the Windows laptop that:

1. Codex can use SANRO Dev Toolkit in practice without unnecessary broad scans.
2. `handoff`, `status`, `context`, `check`, and focused tests work reliably.
3. ChatGPT can safely continue after Codex reset/quota loss using GitHub + AGENTS + workboard/checkpoint as shared state.
4. Codex can return later, sync remote HEAD, and continue without recreating/reverting newer work.
5. Parallel lanes/worktrees do not collide.
6. Important work leaves durable remote evidence.
7. The workflow materially reduces context-recovery and quota waste.

After these gates are demonstrated, migrate the same workflow to Linux rather than redesigning it from scratch.

## Intended VPS capabilities

The Super Agent environment should eventually support:
- SANRO Dev Toolkit cross-platform commands
- Git/GitHub operations
- isolated Git worktrees per agent/lane
- Node.js/npm and Python tooling
- Docker/container sandboxing where useful
- headless browser automation
- scheduled/continuous safe engineering tasks
- read-only SSH/API monitoring of hosting and applications
- health checks, logs, latency, SSL expiry, Node/runtime and MariaDB observations where authorized
- focused tests and end-of-batch regression
- commit/push evidence and handoff reports
- overnight/periodic engineering summaries

## Safety boundary

The Super Agent must default to least privilege.

Safe automation may include source development, tests, lint/checks, documentation, branch/worktree management, non-production builds, commit/push to authorized development branches, and read-only monitoring/verification.

The agent must STOP and require Rio approval before production deployment, production database mutation, production migration, secret/credential changes, production restart/reconfiguration, destructive Git operations, default-OFF production activation, or changes to LOCKED production behavior.

The VPS must not become an unrestricted production root account.

## Growth path

Start with one active builder/worker plus lightweight monitoring. Scale resources only when measured CPU/RAM/disk/I/O or parallel-agent demand justifies it.

Possible future evolution:

Laptop Windows pilot
-> Codex-practiced SANRO Dev Toolkit
-> reliable ChatGPT <-> Codex takeover
-> cross-platform/Linux toolkit support
-> Contabo Cloud VPS 4 Singapore pilot
-> one always-on SANRO agent
-> supervisor/task claiming/worktree isolation
-> multiple specialized agents when proven safe

This document records direction only. VPS purchase/provisioning, credentials, and any production access remain explicit future decisions requiring Rio approval.
