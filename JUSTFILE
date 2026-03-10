# URL to pull flake for a given host
FLAKE_STUB := "git+ssh://git@github.com/GrimOutlook/nix-host-"
# Hosts directory
HOSTS := "hosts"

# List all `just` tasks
default:
  just --list

# Update the `flake.lock` of a host
update HOST:
  git -C {{HOSTS}} submodule update --recursive {{HOST}}
  nix flake update --flake ./{{HOSTS}}/{{HOST}}

# Verify a host's config is valid
check HOST:
  nix flake check ./{{HOSTS}}/{{HOST}}

# Deploy a host to it's hostname
[group('deploy')]
deploy HOST:
  nh os switch \
    --target-host root@{{HOST}} \
    --build-host root@{{HOST}} \
    ./{{HOSTS}}/{{HOST}} -H {{HOST}}

# Update a host and deploy it
[group('deploy')]
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

# Commit flake update for host
[group('git')]
commit-update HOST:
  git -C {{HOSTS}}/{{HOST}} commit -am "chore: Update flake.lock" && git push || true
  git -C {{HOSTS}} commit -am "chore: Update \`{{HOST}}\` flake.lock" && git push || true
