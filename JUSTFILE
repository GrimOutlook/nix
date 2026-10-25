# URL to pull flake for a given host
FLAKE_STUB := "git+ssh://git@github.com/GrimOutlook/nix-host-"
# Hosts directory
HOSTS := "hosts"

# List all `just` tasks
default:
  just --list

check HOST:
  just --justfile homelab/JUSTFILE eval-host {{HOST}}

eval-host HOST:
  just --justfile homelab/JUSTFILE eval-host {{HOST}}

eval-fleet:
  just --justfile homelab/JUSTFILE eval-fleet

build-host HOST:
  just --justfile homelab/JUSTFILE build-host {{HOST}}

# Compatibility entry point: update the consolidated fleet lockfile.
[group('update')]
update HOST:
  just --justfile homelab/JUSTFILE update

# Update the consolidated fleet's dependencies.
[group('update')]
update-all:
  just --justfile homelab/JUSTFILE update

# Deploy a host from the consolidated fleet to its hostname.
[group('deploy')]
deploy HOST ADDR=HOST:
  just --justfile homelab/JUSTFILE deploy {{HOST}} {{ADDR}}

# Update a host and deploy it
[group('deploy')]
[group('update')]
deploy-update HOST ADDR=HOST:
  just update {{HOST}}
  just deploy {{HOST}} {{ADDR}}

# Deploy a host for the first time
[group('deploy')]
deploy-new HOST ADDR=HOST:
  nix run github:nix-community/nixos-anywhere -- \
  --flake ./homelab#{{HOST}} \
  root@{{ADDR}}
  just clear-keys {{HOST}}

# Deploy homelab updates
[group('deploy')]
[group('update')]
deploy-homelab-update:
  just --justfile homelab/JUSTFILE update
  nix run ./homelab#deploy-fleet -- ./homelab

# Connect to a host
[group('ssh')]
connect HOST:
  ssh grim@{{HOST}}

# Clear `.known_hosts` entries for host
[group('ssh')]
clear-keys HOST:
  ssh-keygen -R {{HOST}}

# Commit flake update for single host
[group('git')]
commit-host-update HOST:
  git -C {{HOSTS}}/{{HOST}} commit -am "chore: Update flake.lock" && git push || true
  git -C {{HOSTS}} commit -am "chore: Update \`{{HOST}}\` flake.lock" && git push || true

# Commit flake update for host to the hosts repo
[group('git')]
commit-hosts-update:
  git -C {{HOSTS}} commit -am "chore: Update flake.lock for hosts" && git push || true
  git commit -am "chore: Update flake.lock for hosts" && git push || true

# Push changes for all contained repos
[group('git')]
push:
  git submodule foreach --recursive 'git send'

# Pull changes for all contained repos
[group('git')]
pull:
  git checkout main && git pull origin main && echo
  git submodule foreach --recursive 'git checkout main && git pull origin main && echo'
