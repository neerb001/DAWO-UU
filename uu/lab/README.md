# DAWO-UU lab

Runs UU workplaces as virtual machines on a Mac with Apple Silicon, managed from a NixOS
management VM. Everything stays local.

## Requirements

- macOS on Apple Silicon, [QEMU](https://www.qemu.org) (`brew install qemu`)
- A NixOS **management VM** (aarch64) reachable over SSH on `127.0.0.1:2222`, with flakes
  enabled and about 25 GB free disk. It builds the configurations and runs deploy-rs.
  From inside that VM the Mac is `10.0.2.2` (QEMU user networking), which is how it reaches
  the workplaces.
- About 6 GB free memory for two workplaces (3 GB each) next to the management VM, and
  roughly 15 GB free disk on the Mac.

## Configuration

| Variable | Default | Meaning |
|---|---|---|
| `UU_LAB_KEY` | (required) | SSH private key that may log in to the management VM and as `deploy` on the workplaces |
| `UU_LAB_CONTROL` | `tim@127.0.0.1` | SSH user and host of the management VM |
| `UU_LAB_CONTROL_PORT` | `2222` | SSH port of the management VM |
| `UU_LAB_DIR` | `.lab/` in the repo | Where VM disks and logs live (git-ignored) |

The public keys that may deploy are in `uu/keys/` and are wired to DAWO's `deploy` account
in `modules/uu/lab.nix`. Replace them with your own.

## Accounts (lab only)

| Account | Password | Where | Purpose |
|---|---|---|---|
| `medewerker` | `uu-lab` | uu-medewerker | Staff user |
| `flexplek` | (auto login) | uu-flexplek | Shared user, home in memory |
| `dawo` | `uu-beheer` | both | DAWO's break-glass admin |

These passwords are public and only meant for this lab. A real UU deployment would take
users from central identity (SSO) and admins from agenix, as on DAWO's roadmap.

## Flow

1. `uu-lab image` builds `hosts/uu-lab-base` into a qcow2 image inside the management VM
   (emulated, takes several minutes) and copies it to the Mac.
2. `uu-lab up` creates a copy-on-write disk per workplace on top of that image and starts
   each one in its own window. The VM passes its name to the guest via SMBIOS.
3. `uu-lab deploy` syncs this repository to the management VM and runs
   `nix develop -c deploy` (deploy-rs, as described in `docs/deploy.md`) per workplace.
   The management VM builds once and copies the result to the workplace.
