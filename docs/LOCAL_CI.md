# SANRO Local CI

SANRO Local CI is the deterministic CI path that runs on a SANRO-controlled development machine or VPS. It is intentionally independent from GitHub Actions availability.

GitHub remains the authoritative source repository and record for commits, branches, pull requests, tags, and releases. GitHub Actions may remain enabled as secondary verification, but a GitHub Actions outage, quota limit, runner shortage, or billing problem must not by itself block development when SANRO Local CI has produced valid evidence.

## Authority boundary

Default flow:

```text
Rio
  -> ChatGPT (orchestrator)
  -> SANRO AI Agent / Agent Bridge / Supervisor
  -> SANRO Dev Toolkit
  -> deterministic local CI
  -> concise JSON result/evidence
  -> Rio approval when production mutation is required
  -> deploy / health check / rollback according to project policy
  -> GitHub receives source-control and release records
```

The local CI runner never grants deployment approval. Its reports always mark `productionMutation=false`.

## Responsibility split

- **Rio**: final approver for production mutation, destructive actions, credential changes, release/deploy decisions that require approval.
- **ChatGPT**: primary orchestrator; selects the next safe task, interprets evidence, and requests production approval only when required.
- **SANRO AI Agent / Supervisor**: policy gate and worker router. It should invoke deterministic Toolkit operations before AI workers.
- **SANRO Dev Toolkit**: authoritative deterministic development checks such as syntax checks, lint, tests, build, verification, release checks, report generation, and artifact validation.
- **Worker LLM**: assists with bounded analysis or low-risk reasoning when deterministic tools are insufficient. It is not used for routine lint/test/build execution.
- **Codex CLI**: reserved for coding or engineering reasoning that genuinely needs it. Toolkit evidence should be prepared before Codex is invoked and re-validated afterward.
- **GitHub**: authoritative source-control/review/release record. GitHub Actions is optional/secondary CI.
- **Production server**: runtime target only. Local CI does not implicitly authorize changes there.

## Commands

Existing Toolkit commands remain compatible. Local CI adds:

```text
sanro-dev.ps1 lint
sanro-dev.ps1 build
sanro-dev.ps1 verify
sanro-dev.ps1 release-check
sanro-dev.ps1 ci
```

On Ubuntu use the existing `sanro-dev.sh` launcher.

Use `-Json` with CI commands when a machine-readable response is required:

```bash
./sanro-dev.sh ci -ProjectRoot /opt/sanro/projects/ticket -Json
```

The runner also persists reports in the project-configured report directory. The default is:

```text
.sanro-ci/latest.json
.sanro-ci/runs/<run-id>.json
```

`.sanro-ci/` should remain ignored by Git.

## Manifest contract

The existing `sanro-dev.project.json` schema remains version 1 for backward compatibility. Local CI is an optional `ci` block, so existing repositories do not break merely because the Toolkit is upgraded.

Example:

```json
{
  "schemaVersion": 1,
  "project": "SANRO Ticket",
  "projectType": "sanro-node",
  "ci": {
    "reportDirectory": ".sanro-ci",
    "failFast": false,
    "dependencyPolicy": {
      "installMode": "explicit-only",
      "allowCiInstall": false
    },
    "pipeline": ["check", "lint", "unit", "integration", "build", "verify"],
    "stages": {
      "check": {
        "enabled": true,
        "required": true,
        "builtin": "fast-check"
      },
      "lint": {
        "enabled": true,
        "required": true,
        "workingDirectory": ".",
        "command": "npm",
        "args": ["run", "lint"]
      },
      "unit": {
        "enabled": true,
        "required": true,
        "workingDirectory": ".",
        "command": "npm",
        "args": ["test"]
      },
      "integration": {
        "enabled": true,
        "required": true,
        "workingDirectory": ".",
        "command": "npm",
        "args": ["run", "test:integration"]
      },
      "build": {
        "enabled": true,
        "required": true,
        "workingDirectory": ".",
        "command": "npm",
        "args": ["run", "build"]
      },
      "verify": {
        "enabled": true,
        "required": true,
        "workingDirectory": ".",
        "command": "npm",
        "args": ["run", "verify"]
      }
    },
    "artifactOutputs": [
      { "path": "dist", "required": true }
    ],
    "releaseValidation": {
      "requireCleanWorkingTree": true,
      "requireArtifacts": true,
      "enforceProductionApproval": true
    },
    "healthCheck": {
      "mode": "project-defined",
      "command": null
    },
    "deploymentPolicy": {
      "productionApprovalRequired": true,
      "autoDeploy": false
    },
    "rollbackPolicy": {
      "approvalRequired": true,
      "mode": "project-defined",
      "command": null
    }
  }
}
```

A repository should only enable stages that it truly supports. A stage listed in `pipeline` but missing from `stages` is treated as `BLOCKED`, not silently successful.

## Dependency policy

`sanro ci` validates the existing workspace. It does not automatically install or upgrade dependencies. Dependency installation remains an explicit bootstrap/development action so deterministic CI cannot unexpectedly mutate a project environment.

This keeps CI evidence reproducible and avoids turning validation into a hidden package-management step.

## Report format

The JSON report contains at least:

- schema/tool/mode/run ID;
- project name/type/root;
- Git branch, commit, dirty state, changed-file count;
- start/end timestamps and duration;
- overall status and exit code;
- `productionMutation=false`;
- ordered pipeline stages;
- per-stage status, duration, exit code, command summary, and bounded log tail;
- artifact existence state;
- release validation results;
- dependency/deployment/rollback/health-check policy metadata;
- report file locations.

Primary CI statuses are `PASS`, `FAIL`, `BLOCKED`, and per-stage `SKIP` when explicitly disabled.

Exit codes:

```text
0 = PASS
1 = FAIL
2 = BLOCKED
```

The bounded `logTail` is intended for ChatGPT / Agent Bridge reporting without sending entire build logs through the AI path.

## Release check

`release-check` runs the configured local CI pipeline and then checks release policy. By default it requires a clean working tree, may require declared artifacts, and enforces SANRO production safety:

```text
productionApprovalRequired = true
autoDeploy = false
```

A release check is evidence for a release candidate; it is not deployment authorization.

## GitHub Actions

GitHub Actions can remain as:

- optional verification;
- compatibility matrix testing;
- secondary CI;
- pull-request signal;
- scheduled checks;
- or a GitHub self-hosted runner that invokes the same Toolkit commands.

The self-hosted runner is an integration adapter, not the SANRO CI control plane. The canonical command remains executable directly on the SANRO VPS without GitHub.

A minimal optional workflow should only delegate to the same command, for example:

```text
./sanro-dev.sh ci -ProjectRoot <workspace>
```

Do not put CI truth exclusively in workflow YAML.

## Migration plan

1. **Toolkit foundation** — add manifest-driven local CI and JSON evidence without changing existing project behavior.
2. **Pilot repository** — adopt one active SANRO repository with its real lint/test/build commands and run local CI on the VPS.
3. **Supervisor integration** — add a deterministic Agent Bridge/Supervisor task that invokes Toolkit CI and returns only the bounded JSON summary.
4. **Repository rollout** — add/validate `ci` blocks for Superadmin, POS, Ticket, Stock, Production + Retail, F&B, and future repositories one by one.
5. **GitHub Actions downgrade** — treat GitHub Actions as secondary verification; remove any development gate that exists only because a GitHub-hosted runner ran.
6. **Optional self-hosted runner** — connect GitHub to the same SANRO VPS CI only where useful, without making GitHub the control plane.
7. **Release/deploy integration** — keep release preparation deterministic, but preserve explicit Rio approval for production mutation.

This sequence is intentionally incremental so active projects keep working while each repository is migrated and verified.
