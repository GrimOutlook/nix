# URL to pull flake for a given host
FLAKE_STUB := "git+ssh://git@github.com/GrimOutlook/nix-host-"
# Hosts directory
HOSTS := "hosts"

# List all `just` tasks
default:
  just --list

check HOST:
  nix flake check ./{{HOSTS}}/{{HOST}}

# Update the `flake.lock` of a host
[group('update')]
update HOST:
  git -C {{HOSTS}} submodule update --recursive {{HOST}}
  nix flake update --flake ./{{HOSTS}}/{{HOST}}

# Uodate all hosts in the hosts/ directory
[group('update')]
update-all:
  #!/usr/bin/env bash
  git -C {{HOSTS}} submodule update --recursive
  for host_dir in ./hosts/*/; do \
    host="$(basename $host_dir)"
    just update $host
    just commit-host-update $host
  done
  just commit-hosts-update
  just push-changes

# Verify a host's config is valid
# Deploy a host to it's hostname
[group('deploy')]
deploy HOST:
  nh os switch \
    --target-host root@{{HOST}} \
    --build-host root@{{HOST}} \
    ./{{HOSTS}}/{{HOST}} -H {{HOST}}

# Update a host and deploy it
[group('deploy')]
[group('update')]
deploy-update HOST:
  just update {{HOST}}
  just deploy {{HOST}}
  just commit-update {{HOST}}

# Deploy a host for the first time
[group('deploy')]
deploy-new HOST:
  nix run github:nix-community/nixos-anywhere -- \
  --flake ./{{HOSTS}}/{{HOST}}#{{HOST}} \
  root@{{HOST}}
  just clear-keys {{HOST}}

# Deploy homelab updates
[group('deploy')]
[group('update')]
deploy-homelab-update:
  # TODO: Make this search for `homelab.url` in `hosts/` and run
  # `deploy-update` for every host that has it
  #
  # just deploy-update newyork
  just deploy-update washington
  just deploy-update london


# Connect to a host
[group('ssh')]
connect HOST:
  ssh root@{{HOST}}

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
push-changes:
  git submodule foreach --recursive 'git send'
