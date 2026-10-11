# SANRO CI Environment Contract

SANRO Local CI may need environment variables for test-only integration configuration. This capability is deliberately bounded so CI reports do not become a secret transport.

## Manifest fields

A command may declare literal non-secret test values with `environment` and required externally supplied values with `requiredEnvironment`:

```json
{
  "name": "integration test",
  "workingDirectory": "backend",
  "command": "node",
  "args": ["--test", "test/example.integration.test.js"],
  "environment": {
    "NODE_ENV": "test",
    "SANRO_INTEGRATION_DB": "1"
  },
  "requiredEnvironment": [
    "DB_HOST",
    "DB_PORT",
    "DB_NAME",
    "DB_USER",
    "DB_PASSWORD"
  ]
}
```

Use `environment` only for non-secret deterministic test configuration. Secret or environment-specific values must be supplied by the process/VPS environment and referenced only by name in `requiredEnvironment`.

For a multi-command stage, stage-level `workingDirectory`, `environment`, and `requiredEnvironment` are inherited by its commands. A command may override literal environment keys and may add more required environment names.

## Fail-closed behavior

- Invalid environment variable names block the command.
- Array/object environment values are rejected; literal values must be scalar.
- A missing or empty required environment variable returns `BLOCKED` with exit code `2`.
- CI does not invent defaults for missing database credentials or endpoints.
- Literal environment overrides exist only for child-command execution and are restored afterward.

## Reporting and redaction

Machine-readable command summaries expose only:

```text
environmentKeys
requiredEnvironment
```

They never include environment values.

All values sourced through `requiredEnvironment` are treated as sensitive and are removed from captured output before it is printed or persisted in `logTail`.

Literal `environment` values are expected to be non-secret. As defense in depth, values whose variable names are credential-shaped (for example `*_PASSWORD`, `*_TOKEN`, `*_SECRET`, `*_CREDENTIAL`, `*_API_KEY`, `*_PRIVATE_KEY`, or `*_CONTROL_PLANE_KEY`) are also replaced with `[REDACTED_ENV]` when captured in command output.

Common credential-shaped textual output such as `password=`, `token=`, `secret=`, `credential=`, and `api_key=` is additionally redacted.

This is defense in depth, not permission to print secrets from test code. Test commands should still avoid echoing credentials.

## Production boundary

Environment injection is a CI/test capability only. It does not authorize:

- `.env` mutation;
- production credential changes;
- production database access;
- migrations or DDL;
- deploy/restart/reconfiguration;
- any production mutation.

Project-specific migration/DDL policy continues to apply even if the target database is intended for testing. Where SANRO policy requires Rio approval, the CI stage must remain disabled until that approval exists.
