{ config, ... }:
{
  # Lab: persoonlijke werkplek van een UU-medewerker.
  flake.modules.nixos."hosts/uu-medewerker" = _: {
    imports = with config.flake.modules.nixos; [
      profiles-uu
      uu-lab
    ];
    networking.hostName = "uu-medewerker";
    uu.werkplek.type = "medewerker";

    # Lab-account; in productie komt de gebruiker uit de centrale identiteit (SSO).
    users.users.medewerker = {
      isNormalUser = true;
      description = "UU Medewerker";
      extraGroups = [ "networkmanager" ];
      initialHashedPassword = "$y$j9T$RtpoSVh.nh2H3jJk7qtHN/$bcWP3l00xteWJ8fZj2VgpQJYJfmZWJCZbMSrfhPR6A2"; # uu-lab
    };
  };
}
