# Nix

A repo containing all of the main nix repos I use and change regularly.

## Anatomy

### Config

Contains all of the main modules that are pulled in by each host.

The format is based on `dendritics` and the original repo I based it on was
from @GaetanLepage. This layout is incredible for making configuration modular
and I give huge credit to those who came up with it.

### Homelab

Configuration pulled in by homelab hosts so the configuration can be updated
for all hosts at once.

This is mainly for enabling the alteration of port and host information so
port-forwarding and reverse-proxys can be set declaritively.

#### Homelab Hosts

These hosts are not stored in the [`nix-homelab`](https://github.com/GrimOutlook/nix-homelab) repo but are listed here for
organizational purposes. All hosts are stored in the [`nix-hosts`](https://github.com/GrimOutlook/nix-hosts) repo.

| Host | Summary |
| --- | --- |
| [dubai](https://github.com/GrimOutlook/nix-host-dubai) | Home Automation Host |
| [london](https://github.com/GrimOutlook/nix-host-london) | Media Organizer |
| [newyork](https://github.com/GrimOutlook/nix-host-newyork) | Software Router/Firewall |
| [pyongyang](https://github.com/GrimOutlook/nix-host-pyongyang) | Non-public Service Host |
| [washington](https://github.com/GrimOutlook/nix-host-washington) | Public Web Service Host |

### Hosts

Contains ***all*** of the repos for individual hosts, including homelab hosts.

#### Nix Hosts

| Host | Summary |
| --- | --- |
| [berlin](https://github.com/GrimOutlook/nix-host-berlin) | Desktop (Nix Boot)|
| [belfast](https://github.com/GrimOutlook/nix-host-belfast) | Desktop (Windows Boot) WSL |
| [paris](https://github.com/GrimOutlook/nix-host-paris) | Laptop (Nix Boot) |
| [taipei](https://github.com/GrimOutlook/nix-host-taipei) | Laptop (Windows Boot) WSL |

## Resources
- [NixOS Packages/Options](https://search.nixos.org/packages?channel=25.11)
- [HomeManager Options](https://home-manager-options.extranix.com/)
- [NixVim Options](https://nix-community.github.io/nixvim/25.11/index.html)
- [NixOS Virtual Machines](https://nix.dev/tutorials/nixos/nixos-configuration-on-vm)
