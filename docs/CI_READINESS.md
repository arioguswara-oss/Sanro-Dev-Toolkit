# SANRO Local CI Readiness Contract

Local CI readiness is a deterministic, read-only preflight. Its job is to answer whether the current SANRO-controlled development environment has the prerequisites needed to run a CI profile. It must not install packages, pull container images, switch branches, restart services, or mutate production.

## Manifest shape

Repositories may add a `ci.readiness` block to `sanro-dev.project.json`:

```json
{
  "ci": {
    "readiness": {
      "core": {
        "requiredCommands": ["git", "node", "npm", "rg", "pwsh", "bash"]
      },
      "integration": {
        "anyOfCommands": [["podman", "docker"]],
        "requiredContainerImages": ["mariadb:10.11"]
      }
    }
  }
}
```

The `core` profile is inherited by more specific profiles. `requiredCommands` requires every listed command. Each entry in `anyOfCommands` requires at least one command from that group. `requiredContainerImages` requires each image to already exist in the selected local Docker/Podman runtime.

## Read-only guarantees

The Supervisor readiness inspector may:

- test whether the Toolkit launcher and project manifest exist;
- parse the manifest;
- inspect PATH for declared commands without executing them;
- run `docker image inspect` or `podman image inspect` for declared images.

It must not:

- install a missing command;
- run package restoration;
- pull an image;
- start a container;
- switch or update a project branch;
- run migrations;
- deploy or restart runtime services;
- grant production mutation authority.

A missing prerequisite returns `BLOCKED`; readiness never silently repairs the environment.

## Profiles

`core` should contain only prerequisites needed by the repository's ordinary deterministic CI path.

Additional profiles such as `integration` may add heavier prerequisites without making them mandatory for normal lint/unit/build verification. For example, SANRO Ticket can require a locally cached MariaDB image only for integration readiness while ordinary unit CI remains independent from Docker/Podman.

## Agent routing

Questions such as `report SANRO local CI readiness` or `cek kesiapan CI integration MariaDB` are deterministic inspection tasks. They should route to the deterministic worker, not Local LLM or Codex.

Readiness is evidence only. `READY` means prerequisites are present; it does not mean tests passed, a release is approved, or production deployment is authorized.
