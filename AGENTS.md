# AGENTS.md

Quick orientation for agents working in this repo. This top-level repo is just
a wrapper: it holds no Nix config of its own and exists to check out three
independent git submodules together and drive them with a shared `JUSTFILE`.

## Layout

```
.
├── config/    -> git@github.com:GrimOutlook/nix-config   (submodule, branch main)
├── hosts/     -> git@github.com:GrimOutlook/nix-hosts     (submodule, branch main)
├── homelab/   -> git@github.com:GrimOutlook/nix-homelab   (submodule, branch main)
├── JUSTFILE   -> top-level task runner (update/deploy/ssh/git helpers across all hosts)
└── README.md
```

Each submodule is its own repo with its own git history/remote — `cd` into it
and use git normally. Running `just pull` at the top level pulls all three and
checks out `main`; `just push` pushes all three (`git submodule foreach --recursive`).

### `config/` — nix-config

Shared NixOS/home-manager modules, structured "dendritic style" (based on
github.com/GaetanLepage/nix-config): every `default.nix` under a directory is
auto-imported via `import-tree`, so directory layout == module tree, no manual
import lists to maintain.

- `flake/` — flake-parts glue: `modules.nix` wires up `capabilities/` +
  `host-types/` into `nixosModules.default`; `host.nix` defines the `host.*`
  option namespace; `devshell.nix` defines `just`-like devshell commands
  (`update`, `switch`, `unlink-results`); `deploy-rs.nix` wires deploy-rs
  (currently broken — see FIXME in that file); `systems.nix` lists supported
  systems.
- `capabilities/` — reusable, composable feature modules grouped by domain:
  `core` (applies to every host: users, nix settings, ssh, networking, agenix,
  etc.), `dev`, `graphical`, `misc`, `network-diag`, `virtualization`. Each
  capability is toggled via `host.<capability>.enable`.
- `host-types/` — one module per machine class (`desktop`, `laptop`, `pi`,
  `server`, `vm`, `wsl`), each enabling a bundle of capabilities. Toggled via
  `host.type.<type>.enable`. Individual hosts set exactly one of these.

### `hosts/` — nix-hosts

Contains the actual flake for every physical/virtual machine, one directory
per hostname. Each host directory is normally its own flake pulling in
`nix-config` (and `nix-homelab` if it needs homelab service/network info) plus
host-specific hardware/service modules. See the host registry below.

`hosts/JUSTFILE` drives per-host lifecycle: `just update HOST`, `just deploy
HOST [ADDR]` (uses `nh os switch` over SSH), `just deploy-new HOST [ADDR]`
(first install via nixos-anywhere), `just deploy-update HOST`, `just
update-all`.

### `homelab/` — nix-homelab

Single source of truth for the home network: `hosts.nix` declares every
homelab-relevant host (IP/MAC, and the services it runs with port
numbers/subdomains/public-exposure flags), consumed by hosts via the
`homelab` flake input (e.g. `homelab.hosts.<name>.services.<svc>.ports.*`).
`modules/lib.nix` and `modules/helpers.nix` provide the IP/port
auto-assignment and lookup helpers; `modules/ssh_config.nix` generates SSH
host entries for home-manager.

`homelab/JUSTFILE` has per-host `mod` targets (berlin, dubai, dunkirk,
london, newyork, paris, washington) plus `update-homelab*` recipes that fan
out `deploy-update` across service/networking/client hosts.

**Note:** `homelab/hosts.nix` in this checkout can lag its own `origin/main`
(submodule pointers aren't always bumped promptly) — if a host's expected
`homelab.hosts.<name>` entry seems missing, check `git -C homelab log
HEAD..origin/main` before assuming it doesn't exist upstream.

## Host registry (as of this checkout)

| Host | Type | Purpose | Notes |
| --- | --- | --- | --- |
| amsterdam | server | Public web service host / hypervisor | |
| berlin | desktop | Personal desktop (Nix boot) | |
| belfast | wsl | Desktop (Windows boot) WSL | |
| dunkirk | server | Non-public service host (frigate cameras currently all disabled, paperless-ngx) | homelab entry currently commented out in `hosts.nix` |
| london | server | Media downloader (radarr/sonarr/prowlarr/transmission) | |
| macao | desktop | Living-room gaming PC / "Steam Machine" | uses its own `.just/` justfile modules |
| newyork | server | Router/firewall (dnsmasq, ddclient, glance, vnstat) | homelab gateway host |
| oslo | server | Local backups host | pulls shared config via `nix-backup-host` flake |
| paris | laptop | Personal laptop (Nix boot) | |
| pyongyang | server | Security NVR (frigate, active cameras: front-door, driveway, back-gate; Coral TPU; ZFS raidz3 pool) | `arm build` + `network-diag` enabled |
| svalbard | server | Remote backups host | pulls shared config via `nix-backup-host` flake |
| taipei | wsl | Laptop (Windows boot) WSL | |
| washington | server | Public web service host (plex, vaultwarden) | |
| dubai | (planned) | Home automation (home-assistant) | defined in `homelab/hosts.nix` upstream; no `hosts/dubai` directory yet |

## Conventions / gotchas

- Everything is driven by `just`. Check for a `JUSTFILE` before writing ad hoc
  shell commands — most host/update/deploy/git workflows already have a
  recipe (top-level, `hosts/`, `homelab/`, and per-host like `macao/.just/`).
- Capabilities and host-types are enabled through the `host.*` NixOS option
  namespace defined in `config/flake/host.nix` — grep for `host.type.*.enable`
  or `host.<capability>.enable` to see what a given host actually turns on,
  rather than inferring from file presence alone.
- Secrets are managed with `agenix` (see `*/secrets/*.age` + `secrets.nix`
  per host, e.g. `hosts/pyongyang/secrets/`).
- Per-host READMEs occasionally get copy-pasted from another host when
  scaffolding a new one and not updated — cross-check a host's README against
  its actual `modules/`/`services/` before trusting it.
