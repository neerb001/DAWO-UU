{
  # UU-huisstijl voor de Plasma-werkplek: achtergrond, kleurenschema (UU-geel
  # als accent op Breeze Dark), opstart- en inlogscherm en de avatar.
  #
  # De DAWO-kern brandt de werkplek als BZK/Rijksoverheid (maid-dawo-generic,
  # desktop-sddm-bzk, boot-plymouth-bzk). Dit blok laat die kern ongemoeid en
  # zet er de UU-waarden overheen, zodat upstream-wijzigingen zonder conflict
  # binnenkomen. Het officiele UU-logo zit er bewust niet in: alleen de
  # huisstijlkleuren en de naam als tekst.
  flake.modules.nixos.uu-branding =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      fontsConf = pkgs.makeFontsConf { fontDirectories = [ pkgs.inter ]; };

      render =
        name: svg: width:
        pkgs.runCommand "uu-${name}.png"
          {
            nativeBuildInputs = [ pkgs.librsvg ];
            FONTCONFIG_FILE = fontsConf;
          }
          ''
            rsvg-convert -w ${toString width} ${svg} -o $out
          '';

      images = {
        wallpaper = render "wallpaper" ../../uu/artwork/wallpaper.svg 3840;
        bootLogo = render "boot-logo" ../../uu/artwork/boot-logo.svg 450;
        avatar = render "avatar" ../../uu/artwork/avatar.svg 256;
      };

      # Breeze Dark met UU-geel als accent- en selectiekleur, en zwart/geel in
      # de titelbalk. Wordt systeembreed de standaard (/etc/xdg/kdeglobals) en
      # is in Systeeminstellingen te kiezen als "UU".
      colorScheme =
        pkgs.runCommand "uu-color-scheme"
          {
            nativeBuildInputs = [ pkgs.python3 ];
          }
          ''
            python3 - ${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors $out <<'PY'
            import configparser, os, sys
            src, out = sys.argv[1], sys.argv[2]
            c = configparser.ConfigParser(interpolation=None, strict=False)
            c.optionxform = str
            c.read(src)
            geel, zwart = "255,205,0", "17,17,17"
            for s in c.sections():
                if s.startswith("Colors:"):
                    c[s]["DecorationFocus"] = geel
                    c[s]["DecorationHover"] = geel
            c["Colors:Selection"].update(
                BackgroundNormal=geel, BackgroundAlternate="255,215,64",
                ForegroundNormal=zwart, ForegroundActive=zwart, ForegroundLink=zwart)
            c["General"].update(ColorScheme="UU", Name="UU", AccentColor=geel)
            if not c.has_section("WM"):
                c.add_section("WM")
            c["WM"].update(activeBackground=zwart, activeForeground=geel,
                           inactiveBackground="34,34,34", inactiveForeground="160,160,160")
            os.makedirs(out + "/share/color-schemes")
            with open(out + "/share/color-schemes/UU.colors", "w") as f:
                c.write(f, space_around_delimiters=False)
            with open(out + "/kdeglobals", "w") as f:
                c.write(f, space_around_delimiters=False)
            PY
          '';
    in
    {
      options.uu.branding.images = lib.mkOption {
        type = lib.types.attrsOf lib.types.package;
        readOnly = true;
        default = images;
        description = "Gerenderde UU-afbeeldingen (achtergrond, opstartlogo, avatar) voor andere UU-blokken.";
      };

      config = lib.mkIf config.dawo.desktop.plasma.enable {
        # Opstartscherm: UU-tekstlogo in plaats van het Rijksoverheid-logo.
        boot.plymouth = {
          enable = true;
          theme = lib.mkDefault "bgrt";
          logo = images.bootLogo;
        };

        # Systeembrede KDE-standaarden. Gebruikersinstellingen gaan voor, maar
        # DAWO's userland zet geen kleuren, dus deze cascade wint in de praktijk.
        environment.etc."xdg/kdeglobals".source = "${colorScheme}/kdeglobals";

        environment.systemPackages = [
          colorScheme
          # Inlogscherm (SDDM/Breeze) met de UU-achtergrond; hiPrio wint van
          # het BZK-bestand op hetzelfde pad uit desktop-sddm-bzk.
          (lib.hiPrio (
            pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
              [General]
              background=${images.wallpaper}
            ''
          ))
        ];

        # Over DAWO's userland (maid-dawo-generic) heen: UU-achtergrond op elk
        # scherm en het vergrendelscherm, UU-avatar, donker thema met UU-accent.
        maid.sharedModules = [
          {
            file.home.".face".source = lib.mkForce images.avatar;
            file.home.".face.icon".source = lib.mkForce images.avatar;
            kconfig.settings = {
              kdeglobals = {
                General = {
                  ColorScheme = "UU";
                  AccentColor = "255,205,0";
                  accentColorFromWallpaper = false;
                };
                KDE.LookAndFeelPackage = lib.mkForce "org.kde.breezedark.desktop";
              };
              kscreenlockerrc.Greeter.Wallpaper."org.kde.image".General.Image =
                lib.mkForce "${images.wallpaper}";
              plasmarc.Wallpapers.usersWallpapers = lib.mkForce "${images.wallpaper}";
              "plasma-org.kde.plasma.desktop-appletsrc".Containments = lib.genAttrs [
                "1"
                "2"
                "3"
                "4"
                "5"
              ] (_: { Wallpaper."org.kde.image".General.Image = lib.mkForce "${images.wallpaper}"; });
            };
          }
        ];
      };
    };
}
