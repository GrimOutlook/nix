# Nix

A repo containing all of the main nix repos I use and change regularly.

## Anatomy

### Config

Contains all of the main modules that are pulled in by each host.

The format is based on `dendritics` and the original repo I based it on was
from @GaetanLepage.

### Homelab

Configuration pulled in by homelab hosts so the configuration can be updated
for all hosts at once.

This is mainly for enabling the alteration of port and host information so
port-forwarding and reverse-proxys can be set declaritively.

### Hosts

Contains all of the repos for individual hosts.
