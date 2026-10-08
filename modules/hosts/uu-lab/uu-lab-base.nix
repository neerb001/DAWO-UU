{ config, ... }:
{
  # Kaal "inspoel"-image: alleen de DAWO-beveiligingsbasis, SSH en de
  # deploy-gebruiker. Elke lab-werkplek start hiervan en krijgt daarna via
  # deploy-rs zijn echte configuratie.
  flake.modules.nixos."hosts/uu-lab-base" = _: {
    imports = with config.flake.modules.nixos; [
      boot-loader
      profiles-dawo-core
      users-basics
      users-dawo
      users-deploy
      nixos-nix-settings
      services-auto-update
      # Alleen voor de opties (dawo.desktop.*), waar de PAM-hardening naar kijkt;
      # er staat geen desktop aan.
      desktop-plasma
      desktop-gnome
      uu-lab
    ];
    system.stateVersion = "26.05";
  };
}
