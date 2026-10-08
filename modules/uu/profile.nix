{ config, ... }:
{
  # De UU-organisatielaag (laag 2 in DAWO's model, zoals DAWO-NixOS-BZK en
  # DAWO-NixOS-VNG): de DAWO-kern plus de UU-keuzes. Een UU-apparaat importeert
  # dit profiel en kiest daarnaast alleen hardware en werkplektype.
  flake.modules.nixos.profiles-uu =
    { lib, ... }:
    {
      imports = with config.flake.modules.nixos; [
        profiles-dawo-generic
        maid-dawo-generic
        boot-loader
        uu-branding
        uu-apps
      ];

      dawo.desktop.plasma = {
        enable = true;
        socialClient = false;
      };

      dawo.apps = {
        office.enable = true;
        comms.enable = true;
        media.enable = true;
      };

      dawo.firefox.dictionaries = [
        "nl_NL"
        "en_GB"
        "en_US"
      ];

      # Echte UU-apparaten volgen deze fork; de DAWO-kern komt mee als basis.
      dawo.autoUpdate.options.repoUrl = lib.mkDefault "https://github.com/neerb001/DAWO-UU.git";
    };
}
