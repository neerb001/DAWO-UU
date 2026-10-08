# DAWO-UU

A test environment for evaluating a NixOS-based digital workplace at Utrecht University.
DAWO-UU is a fork of [DAWO](https://codeberg.org/DAWO/DAWO-Core) (Digitaal Autonome
Werkomgeving Overheid), the open workplace that the Dutch government is building on NixOS,
extended with a Utrecht University layer and a local lab. Developed at Utrecht University as
part of the [Digital Autonomy programme](https://www.uu.nl/en/organisation/digital-autonomy).

> **Status in short:** an experiment, not a supported UU workplace. It exists to learn what
> a declarative, vendor-independent Linux workplace would mean for a university: what works,
> what it costs, and where the gaps are. Nothing here is an official UU service or endorsed
> configuration.

## About

Digital autonomy is not only about where data lives, but also about the workplace that
people use to reach it. DAWO shows that a public organisation can define its complete
workplace (operating system, security baseline, apps, desktop) as open source code, without
depending on a single vendor. This fork asks a narrower question:

**What would it take to run (part of) the UU workplace this way, and is NixOS the right
foundation for it?**

The lab in this repository makes that question tangible. A management VM builds and rolls
out workplaces; two UU workplaces (a personal staff workplace and a shared flex workplace)
receive the UU desktop, UU colours, a UU-specific app and UU settings. Every change is a
commit, and every workplace can show which commit it runs.

## NixOS: infrastructure as code, for the desktop

NixOS applies the infrastructure-as-code idea to the whole machine, desktop included. The
difference with configuration management tools is that NixOS does not *adjust* a running
system towards a desired state; it *builds* the complete system from the configuration and
switches to it atomically.

| | Traditional desktop management (Intune, SCCM, Ansible) | Image-based Linux (Fedora Atomic, bootc) | NixOS / DAWO |
|---|---|---|---|
| Source of truth | Policies + scripts + the device itself | Container image + mutable `/etc` | The git repository, completely |
| Drift | Possible, corrected periodically | Limited | Not possible: the system is built from code |
| Failed update | Can leave a half-updated device | Atomic, roll back at boot | Atomic, roll back at boot |
| Variants (department, hardware) | Policy assignments | One image per variant | Composable modules (DAWO's layer model) |
| Audit: "what runs on this device?" | Inventory agent | Image digest | One commit hash, reproducible build |
| Vendor dependence | High | Medium | None required |

The trade-offs are real: management tooling (MDM, compliance reporting) is less mature,
vendor software that ships as a Windows or generic Linux installer needs extra work, and
administrators need to learn Nix. DAWO exists largely to fill that tooling gap together.

## What this fork adds

DAWO is designed in three layers: a shared **core**, an **organisation layer** (for example
`DAWO-NixOS-BZK`, `DAWO-NixOS-VNG`) and a **device configuration**. DAWO-UU follows that model
and leaves the core untouched where possible, so upstream changes can be merged.

| Path | Layer | What it does |
|---|---|---|
| `modules/uu/profile.nix` | Organisation | `profiles-uu`: the DAWO core plus UU choices (KDE Plasma, app sets, dictionaries, update source) |
| `modules/uu/branding.nix` | Organisation | UU wallpaper, UU colour scheme (Breeze Dark with UU yellow), boot and login screen, avatar |
| `modules/uu/apps.nix` | Organisation | The **UU Werkplek** app, UU web services in the start menu and as Firefox bookmarks, workplace types |
| `modules/uu/lab.nix` | Lab only | Runs workplaces as QEMU VMs on Apple Silicon (aarch64) and rolls out via deploy-rs |
| `modules/hosts/uu-lab/` | Device | `uu-medewerker` (staff), `uu-flexplek` (shared, stateless home), `uu-lab-base` (bootstrap image) |
| `uu/` | Assets | Artwork (SVG), the UU Werkplek app source, lab SSH public keys, lab script |

The only change to the DAWO core is adding `aarch64-linux` to the flake systems, so the
workplaces and DAWO's own deploy shell also build on ARM.

### UU Werkplek app

A small Qt app in UU style that gives the user one place to see what kind of workplace this
is, which configuration it runs and whether it meets the security baseline. It wraps DAWO's
own tools: `dawo-verify` (security rules), `dawo-update-status` and `dawo-proof`.

### Workplace types

- **Staff workplace (`uu-medewerker`)**: personal; settings and software are managed
  centrally, the user's files stay.
- **Flex workplace (`uu-flexplek`)**: shared and stateless; the home directory lives in
  memory, so every logout or restart gives the next user a clean workplace.

## The lab

```
Mac (Apple Silicon)
├── management VM (NixOS)     builds the flake, rolls out with deploy-rs (DAWO's route)
├── uu-medewerker  (window)   UU staff workplace, KDE Plasma
└── uu-flexplek    (window)   UU flex workplace, stateless home
```

Workplaces start from a minimal bootstrap image (`uu-lab-base`: DAWO security baseline,
SSH, DAWO's `deploy` account) and receive their real configuration over SSH, the same way a
new laptop would be enrolled. See [`uu/lab/README.md`](uu/lab/README.md) for setup.

```bash
export UU_LAB_KEY=~/path/to/lab-ssh-key
uu/lab/uu-lab image      # build the bootstrap image (once)
uu/lab/uu-lab up         # start both workplaces, each in its own window
uu/lab/uu-lab deploy     # roll out the current commit
uu/lab/uu-lab status     # which commit runs where
```

### Test scenarios

| Scenario | How | What it shows |
|---|---|---|
| Central change | Change a UU setting (for example a web link in `modules/uu/apps.nix`), commit, `uu-lab deploy` | Every workplace changes from one commit, without touching a device |
| Failed update | Roll out a deliberately broken change, then pick the previous generation in the boot menu | The user recovers without the service desk |
| Lost laptop | `uu-lab destroy uu-medewerker && uu-lab up uu-medewerker && uu-lab deploy uu-medewerker` | A replacement device is identical, from the same commit |
| Shared workplace | Log in on `uu-flexplek`, create files, log out | Nothing is left for the next user |
| Compliance | **UU Werkplek** app, "Werkplek controleren" | Security rules checked on the device itself |
| Drift | Change something locally as admin, then `uu-lab deploy` | The configuration in git wins |

## Branding

The lab uses UU house colours (yellow `#FFCD00`, red `#C00A35`, black) and the university
name as text. The official UU logo is deliberately not included; add it under `uu/artwork/`
only if that use is approved.

## Keeping up with DAWO

```bash
git fetch upstream                 # https://codeberg.org/DAWO/DAWO-Core
git merge upstream/main
```

Upstream's own README, roadmap and architecture documentation remain in this repository:
see [`architecture.md`](architecture.md), [`docs/ROADMAP.md`](docs/ROADMAP.md) and the
original [DAWO README](https://codeberg.org/DAWO/DAWO-Core).

## License

GPL-3.0, inherited from DAWO. See [LICENSE.md](LICENSE.md) and [ATTRIBUTIONS.md](ATTRIBUTIONS.md).
All credit for the DAWO core goes to the DAWO community.

## Contact

- Tim van Neerbos, Lead Enterprise Architect, Utrecht University
- Email: t.m.vanneerbos@uu.nl
