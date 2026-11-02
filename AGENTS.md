# AGENTS.md

This repository is a wrapper for two independent Git submodules and a shared
`JUSTFILE`; it contains no Nix configuration of its own.

## Layout

- `config/` — `GrimOutlook/nix-config`: public NixOS/Home Manager modules and
  host profiles. The dendritic module tree uses `import-tree`; features are
  enabled through `host.<capability>.enable` and `host.type.<type>.enable`.
- `homelab/` — `GrimOutlook/nix-homelab`: private inventory, hardware, secrets,
  host composition, and a single fleet lockfile. The active fleet is defined in
  `homelab/flake.nix` and `homelab/fleet.nix`.
- `JUSTFILE` — shared evaluation, build, update, deploy, SSH, and Git helpers.

Public profiles live in `config/hosts/`; private hardware/site modules live in
`homelab/hosts/`. The legacy top-level `hosts/` submodule has been removed.

## Workflow

- Check existing just recipes before writing ad hoc lifecycle commands.
- Use top-level `just eval-host HOST`, `just eval-fleet`, `just build-host HOST`,
  and `just deploy HOST [ADDR]` for the consolidated fleet.
- Local evaluation/build overrides the config input with adjacent `config/`.
  Deployment uses homelab's published, locked config input.
- Publish config first, run `just --justfile homelab/JUSTFILE update nix-config`,
  review the lockfile, then publish homelab before deployment. Consult
  `config/PUBLIC_PRIVATE_SPLIT.md` before publication or activation.
- Each submodule has its own history and remote. Commit/push changed submodules
  before recording their pointers in this wrapper. Preserve unrelated work.
- Secrets are managed with agenix. Inspect applicable recipient rules and host
  modules when changing secrets.
- SSH root login is disabled. Deployment uses the restricted `deploy` account
  and limited NOPASSWD sudo-rs for activation. Bootstrap via existing root/admin
  access. Newyork's sshd listens on port 49999.
- Paris is a local rebuild: `sudo nixos-rebuild switch --flake ./homelab#paris`.
- Dubai is maintained externally and excluded from the managed fleet.

Managed systems: amsterdam, berlin, dunkirk, macao, newyork, oslo, paris,
svalbard, and washington. London is a MicroVM on Amsterdam.

Verify host services and settings against current profiles, private modules,
and inventory rather than historical descriptions.
