# DAWO-UU

A test environment for evaluating a NixOS-based digital workplace at Utrecht University.
DAWO-UU is a fork of [DAWO](https://codeberg.org/DAWO/DAWO-Core) (Digitaal Autonome
Werkomgeving Overheid), the open workplace the Dutch government is building on NixOS,
extended with a Utrecht University layer and a local lab. Developed at Utrecht University as
part of the [Digital Autonomy programme](https://www.uu.nl/en/organisation/digital-autonomy).

> **Status in short:** an experiment, not a supported UU workplace. It exists to learn what
> a declarative, vendor-independent Linux workplace would mean for a university. Nothing here
> is an official UU service or endorsed configuration.

## What this fork adds

DAWO is built in three layers: a shared core, an organisation layer and a device
configuration. DAWO-UU adds a UU organisation layer and leaves the core untouched, so
upstream changes can be merged.

- `modules/uu/`: the UU layer
  - `profile.nix`: DAWO core plus UU choices (KDE Plasma, apps, update source)
  - `branding.nix`: UU colours, wallpaper, boot and login screen
  - `apps.nix`: the **UU Werkplek** app, UU web services, workplace types
  - `lab.nix`: lab only, runs workplaces as VMs on Apple Silicon
- `modules/hosts/uu-lab/`: `uu-medewerker` (staff), `uu-flexplek` (shared, stateless home)
  and `uu-lab-base` (bootstrap image)
- `uu/`: artwork, app source, lab script and SSH public keys

The only change to the DAWO core is adding `aarch64-linux` to the flake systems.

**UU Werkplek** is a small app in UU style that shows what kind of workplace this is, which
configuration it runs and whether it meets the security baseline, using DAWO's own tools
(`dawo-verify`, `dawo-update-status`, `dawo-proof`).

## The lab

A management VM builds the configuration and rolls it out with deploy-rs to two workplace
VMs, each in its own window. See [`uu/lab/README.md`](uu/lab/README.md) for setup.

```bash
export UU_LAB_KEY=~/path/to/lab-ssh-key
uu/lab/uu-lab image      # build the bootstrap image (once)
uu/lab/uu-lab up         # start the workplaces
uu/lab/uu-lab deploy     # roll out the current commit
uu/lab/uu-lab status     # which commit runs where
```

Things to try: change a setting and roll it out to all workplaces at once, recover from a
broken update via the boot menu, replace a "lost" workplace from the same commit, and log out
of the flex workplace to see nothing is left behind.

## Branding

The lab uses UU house colours (yellow `#FFCD00`, red `#C00A35`, black) and the university
name as text. The official UU logo is not included.

## Keeping up with DAWO

```bash
git fetch upstream    # https://codeberg.org/DAWO/DAWO-Core
git merge upstream/main
```

## License

GPL-3.0, inherited from DAWO. See [LICENSE.md](LICENSE.md). All credit for the DAWO core
goes to the DAWO community.

## Contact

- Tim van Neerbos, Lead Enterprise Architect, Utrecht University
- Email: t.m.vanneerbos@uu.nl
