# Nix

This is an umbrella checkout for the NixOS configuration used across the
fleet. It is not itself a Nix flake. The actual flakes live in the three Git
submodules below, each with its own repository, history, lock file, and remote.

## Repository Layout

| Path | Repository | Purpose |
| --- | --- | --- |
| [`config/`](./config/) | [nix-config](https://github.com/GrimOutlook/nix-config) | Shared NixOS and Home Manager modules |
| [`hosts/`](./hosts/) | [nix-hosts](https://github.com/GrimOutlook/nix-hosts) | Host flakes and the deploy-rs fleet aggregator |
| [`homelab/`](./homelab/) | [nix-homelab](https://github.com/GrimOutlook/nix-homelab) | Shared homelab metadata consumed by host flakes |
| [`JUSTFILE`](./JUSTFILE) | This repository | Shared update, deploy, SSH, and Git helpers |

Initialize all nested repositories after cloning:

```sh
git submodule update --init --recursive
```

Each submodule is an independent Git repository. Changes must be committed and
pushed from the leaf repository first, then its parent submodule repository,
then this top-level repository.

## How It Works

### Shared Configuration

`config/` uses a dendritic module layout. `import-tree` automatically imports
the module tree, so directory structure is the module composition rather than
a manually maintained import list.

- `capabilities/` contains reusable features such as security, agenix,
  graphical support, development tools, virtualization, and monitoring.
- `host-types/` defines bundles for desktops, laptops, servers, VMs, Pis, and
  WSL systems.
- Hosts enable features through the `host.*` option namespace and normally set
  exactly one `host.type.*.enable` option.
- Shared modules configure both NixOS and Home Manager where appropriate.
- The default package set is Determinate's chilled NixOS 26.05 mirror. Packages
  that need the current upstream revision can opt into the matching realtime
  mirror with `host.nix.realtimePackages`.

### Host Flakes

Every directory under `hosts/` is normally its own flake. A host flake imports
`nix-config` and, where needed, `nix-homelab`, then adds hardware and
host-specific service modules. The host's own `flake.lock` pins those inputs.

The [`hosts/flake.nix`](./hosts/flake.nix) flake is a separate fleet
aggregator. It imports the individual host flakes and exposes their NixOS
systems through `deploy.nodes` for deploy-rs.

### Inputs and Locks

At build time, a host uses the `nix-config` and `nix-homelab` revisions in its
own lock file. The local `config/` and `homelab/` submodules are convenient
checkouts, but changing their parent pointers alone does not change a host
build.

When shared configuration changes:

1. Commit and push `config/` or `homelab/`.
2. Update the affected host lock files to the new input revision.
3. Update the corresponding inputs in `hosts/flake.lock` if deploying through
   the fleet aggregator.
4. Commit and push the host repositories, then the `hosts/` parent, then this
   repository.

Secrets are managed with agenix. Encrypted files live in host `secrets/`
directories and are decrypted only on systems that have the corresponding
identity.

## Host Registry

These are the host flakes currently present in `hosts/`:

| Host | Type | Purpose |
| --- | --- | --- |
| [amsterdam](./hosts/amsterdam/) | Server | Public services, Plex, and the MicroVM host for Vikunja and `london` |
| [berlin](./hosts/berlin/) | Desktop | Personal desktop, booted with NixOS |
| [dubai](./hosts/dubai/) | Raspberry Pi 5 | Home Assistant and homelab automation |
| [dunkirk](./hosts/dunkirk/) | Server | Frigate security NVR with Coral TPU and ZFS |
| [macao](./hosts/macao/) | Desktop | Living-room gaming PC / Steam Machine |
| [newyork](./hosts/newyork/) | Server | Homelab infrastructure host |
| [oslo](./hosts/oslo/) | Server | Local backup host |
| [paris](./hosts/paris/) | Laptop | Personal laptop, booted with NixOS |
| [svalbard](./hosts/svalbard/) | Server | Remote backup host |
| [washington](./hosts/washington/) | Server | Public web services, Plex, and Vaultwarden |

`london` is not a standalone host repository anymore. It is a MicroVM defined
under [`hosts/amsterdam/modules/vms/london/`](./hosts/amsterdam/modules/vms/london/).

## Common Workflows

List available recipes from the top-level checkout:

```sh
just --list
```

Common recipes are:

```sh
just pull                    # Pull main in the top-level repo and submodules
just check HOST              # Check one host flake
just update HOST             # Update one host's flake inputs
just deploy HOST [ADDR]      # Deploy with nh over SSH
just deploy-update HOST      # Update and deploy one host
just deploy-new HOST [ADDR]  # First install with nixos-anywhere
just connect HOST            # Open an SSH session as grim
```

The `just deploy` recipes are the older direct `nh os switch` path. For
rollback-protected fleet deployments, use the deploy-rs workflow below.

For homelab-wide input updates, run the recipes in `hosts/JUSTFILE`:

```sh
cd hosts
just --list
just update-homelab-flakes nix-config
```

Review generated lock-file changes before committing. Do not use a broad
recursive Git command to stage changes when another host or submodule has
unrelated work in progress.

## Deploying With deploy-rs

### Supported Entry Point

Use the fleet aggregator in `hosts/`. It defines a `system` profile running as
`root`, with deploy-rs magic rollback and automatic rollback enabled. SSH
connects as the restricted `deploy` user from private LAN/VPN addresses;
passwordless sudo-rs is limited to the deploy-rs activation and rollback
commands through a fixed validation bridge.

The deployment-client option is enabled by default, but the private key is
installed only on hosts with `host.dev.enable` (currently Berlin and Paris).
The first rollout must therefore use each host's existing root or console
access once; that generation creates the `deploy` account before root SSH is
disabled.

The deploy-rs executable should come from nixpkgs, where it is available from
the binary cache:

```sh
# On Berlin or Paris, after the host has received the agenix secret
ssh-add /run/agenix/nix-deploy-key

# From the top-level repository
nix run ./hosts -- .#newyork

# Equivalent, from inside the fleet aggregator
cd hosts
nix run . -- .#newyork
```

Do not invoke the deploy-rs binary directly for this checkout. The fleet
wrapper runs the cached nixpkgs deploy-rs executable with the `deploy` SSH
user; the encrypted key is unlocked once in `ssh-agent`.

### Nodes

The fleet aggregator currently exposes these deploy-rs nodes:

```text
amsterdam  berlin  dubai  dunkirk  macao  newyork  oslo  svalbard  washington
```

`paris` is intentionally not a deploy-rs node because it is the laptop from
which deployments are normally driven. Rebuild it locally instead:

```sh
run0 nixos-rebuild switch --flake ./hosts/paris#paris
```

The default build behavior is remote build on the target followed by remote
activation. `newyork` is the only exception: it sets `remoteBuild = false`
because the router is not powerful enough to be a useful build host. `dubai`
also builds remotely by default, which lets the aarch64 Pi build its own system
instead of requiring cross-compilation or emulation on the workstation.

### Safe Deployment Sequence

Before deploying a host repository change, refresh that host's input in the
aggregator. The aggregator has its own `flake.lock`, so it otherwise deploys
the host revision already pinned there:

```sh
cd hosts
nix flake update newyork
nix flake check --no-build --no-write-lock-file
nix run . -- --dry-activate .#newyork
nix run . -- .#newyork
```

Replace `newyork` with any supported node. Use `--targets` to deploy more than
one node in one invocation:

```sh
nix run . -- --targets .#newyork .#svalbard
```

Use `nix run . -- .` to deploy every enabled fleet node in one invocation.

`--dry-activate` builds and reports the activation without applying it.
deploy-rs also supports `--boot` when the next generation should be selected
on reboot without switching immediately.

### Rollback Behavior

- `magicRollback` waits for deploy-rs to reconnect after activation. If the
  host does not become reachable, it rolls back automatically.
- Confirmation timeout is 120 seconds for `newyork` and `svalbard`, and 30
  seconds for the other nodes.
- Verify configured SSH access to the target before deploying. The fleet uses
  `deploy` for SSH and `root` only for the NixOS system profile, so the deploy
  key must be loaded in `ssh-agent`.

If schema or check evaluation fails because a required package is not yet in
the local store, allow Nix to substitute or build it and rerun the checks. Use
`--skip-checks` only as an intentional emergency override; it bypasses the
pre-deployment validation.

The shared config also contains an incomplete per-host deploy-rs module. It is
not the supported fleet entry point; use `hosts/flake.nix` as described above.

## Publishing Changes

Because this checkout contains nested Git repositories, publish from the leaves
outward:

1. Commit and push the changed host repository or shared repository.
2. Commit and push the updated submodule pointer and lock file in `hosts/`.
3. Commit and push the updated `hosts/` pointer in this repository.

The same ordering applies to the `config/` and `homelab/` submodules. Check
each repository independently with `git status` before staging or committing.

## Resources

- [NixOS Packages and Options](https://search.nixos.org/packages?channel=26.05)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Options](https://home-manager-options.extranix.com/)
- [Nixvim Options](https://nix-community.github.io/nixvim/26.05/index.html)
- [deploy-rs](https://github.com/serokell/deploy-rs)
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
- [NixOS Virtual Machines](https://nix.dev/tutorials/nixos/nixos-configuration-on-vm)
