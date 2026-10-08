{ config, ... }:
{
  # Lab: gedeelde flexplek. Automatisch ingelogd, en de thuismap staat in het
  # werkgeheugen (tmpfs): na uitloggen of herstarten is alles weg en begint de
  # volgende gebruiker schoon. Het systeem zelf komt uit de configuratie, dus
  # de werkplek is in zijn geheel stateless.
  flake.modules.nixos."hosts/uu-flexplek" =
    { lib, ... }:
    {
      imports = with config.flake.modules.nixos; [
        profiles-uu
        uu-lab
      ];
      networking.hostName = "uu-flexplek";
      uu.werkplek.type = "flexplek";

      users.users.flexplek = {
        isNormalUser = true;
        description = "UU Flexplek";
        uid = 1100;
        initialHashedPassword = "$y$j9T$RtpoSVh.nh2H3jJk7qtHN/$bcWP3l00xteWJ8fZj2VgpQJYJfmZWJCZbMSrfhPR6A2"; # uu-lab
      };
      fileSystems."/home/flexplek" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [
          "size=1G"
          "mode=0700"
          "uid=1100"
          "gid=100"
        ];
      };

      services.displayManager.autoLogin = {
        enable = lib.mkForce true;
        user = "flexplek";
      };
    };
}
