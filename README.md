# Nix

This wrapper holds two independent Git submodules and a shared `JUSTFILE`.
It is not itself a Nix flake.

| Path | Purpose |
| --- | --- |
| [`config/`](./config/) | Public NixOS/Home Manager modules and host profiles |
| [`homelab/`](./homelab/) | Private inventory, hardware, secrets, host composition, and the fleet lockfile |
| [`JUSTFILE`](./JUSTFILE) | Shared evaluation, build, update, deploy, SSH, and Git helpers |

Initialize the repositories with `git submodule update --init --recursive`.
The active fleet is defined in `homelab/flake.nix` and `homelab/fleet.nix`.
Public host profiles live in `config/hosts/`; private modules live in
`homelab/hosts/`.

## Fleet workflow

```sh
just --list                  # List wrapper recipes
just eval-host berlin        # Evaluate with adjacent unpublished config
just eval-fleet              # Evaluate the consolidated fleet
just build-host berlin       # Build with adjacent config, without activation
just update-all              # Update the consolidated fleet lockfile
just deploy newyork          # Deploy the published locked fleet as deploy
just deploy-new HOST [ADDR]  # Install from homelab's consolidated flake
just connect HOST            # Open an SSH session as grim
just pull                    # Pull main in the wrapper and submodules
```

`just update HOST` is a compatibility entry point that updates the shared fleet
lockfile. For a targeted input update, use
`just --justfile homelab/JUSTFILE update INPUT`.

Deployment uses the published locked config input; local evaluation/build uses
adjacent `config/` changes. Paris is rebuilt locally with
`sudo nixos-rebuild switch --flake ./homelab#paris`.

## Publishing changes

1. Commit and push changes in `config/`.
2. Run `just --justfile homelab/JUSTFILE update nix-config` and review the lockfile.
3. Commit and push changes in `homelab/`.
4. Commit the updated submodule pointers in this wrapper and push it.

Check each repository's status before staging changes. Consult
[`config/PUBLIC_PRIVATE_SPLIT.md`](./config/PUBLIC_PRIVATE_SPLIT.md) and
[`homelab/SITE_SPLIT.md`](./homelab/SITE_SPLIT.md) before publication or activation.
