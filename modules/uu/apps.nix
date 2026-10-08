{ inputs, ... }:
{
  # UU-specifieke apps en instellingen: de "UU Werkplek"-app, snelkoppelingen
  # naar UU-diensten, Firefox-beleid en het werkplektype (medewerker/flexplek).
  flake.modules.nixos.uu-apps =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.uu.werkplek;

      dawoRelease =
        let
          headings = lib.filter (l: builtins.match "## [0-9]+\\.[0-9]+\\.[0-9]+ .*" l != null) (
            lib.splitString "\n" (builtins.readFile ../../CHANGELOG.md)
          );
        in
        if headings == [ ] then
          "onbekend"
        else
          builtins.head (builtins.match "## ([0-9]+\\.[0-9]+\\.[0-9]+) .*" (builtins.head headings));

      pyEnv = pkgs.python3.withPackages (ps: [ ps.pyqt6 ]);

      uu-werkplek = pkgs.stdenvNoCC.mkDerivation {
        pname = "uu-werkplek";
        version = "0.1.0";
        src = ../../uu/werkplek;
        nativeBuildInputs = [
          pkgs.qt6.wrapQtAppsHook
          pkgs.makeWrapper
        ];
        buildInputs = [
          pkgs.qt6.qtbase
          pkgs.qt6.qtwayland
        ];
        dontWrapQtApps = true;
        installPhase = ''
          install -Dm644 uu-werkplek.py $out/share/uu-werkplek/uu-werkplek.py
          install -Dm644 ${config.uu.branding.images.avatar} \
            $out/share/icons/hicolor/256x256/apps/uu-werkplek.png
          mkdir -p $out/bin
        '';
        postFixup = ''
          makeWrapper ${pyEnv}/bin/python3 $out/bin/uu-werkplek \
            "''${qtWrapperArgs[@]}" \
            --add-flags $out/share/uu-werkplek/uu-werkplek.py
        '';
      };

      desktopItems = [
        (pkgs.makeDesktopItem {
          name = "uu-werkplek";
          desktopName = "UU Werkplek";
          genericName = "Mijn werkplek";
          comment = "Status, controles en hulp voor je UU-werkplek";
          exec = "uu-werkplek";
          icon = "uu-werkplek";
          categories = [
            "System"
            "Settings"
          ];
        })
      ]
      ++ map (
        s:
        pkgs.makeDesktopItem {
          inherit (s) name desktopName;
          comment = "Opent ${s.url}";
          exec = "firefox --new-window ${s.url}";
          icon = "uu-werkplek";
          categories = [ "Network" ];
        }
      ) cfg.webLinks;

    in
    {
      options.uu.werkplek = {
        type = lib.mkOption {
          type = lib.types.enum [
            "medewerker"
            "flexplek"
          ];
          default = "medewerker";
          description = ''
            Soort werkplek. "medewerker": persoonlijke werkplek, de gebruiker
            houdt zijn bestanden en instellingen. "flexplek": gedeelde werkplek
            zonder blijvende gebruikersgegevens (zie hosts/uu-flexplek).
          '';
        };
        uitleg = lib.mkOption {
          type = lib.types.str;
          default =
            {
              medewerker = "Persoonlijke UU-werkplek. Instellingen en software worden centraal beheerd; je bestanden blijven bewaard.";
              flexplek = "Flexplek: na uitloggen wordt alles gewist. Sla je werk op in OneDrive, Teams of SURFdrive.";
            }
            .${cfg.type};
          description = "Uitleg voor de gebruiker, getoond in de UU Werkplek-app.";
        };
        autostart = lib.mkOption {
          type = lib.types.bool;
          default = cfg.type == "flexplek";
          description = "Start de UU Werkplek-app bij het inloggen.";
        };
        webLinks = lib.mkOption {
          type = lib.types.listOf (lib.types.attrsOf lib.types.str);
          default = [
            {
              name = "uu-website";
              desktopName = "Universiteit Utrecht";
              url = "https://www.uu.nl";
            }
            {
              name = "uu-intranet";
              desktopName = "UU Intranet";
              url = "https://intranet.uu.nl";
            }
            {
              name = "uu-outlook";
              desktopName = "Outlook (web)";
              url = "https://outlook.office.com";
            }
          ];
          description = "UU-webdiensten als app in het startmenu en als bladwijzer in Firefox.";
        };
      };

      config = lib.mkIf config.dawo.desktop.plasma.enable {
        environment.systemPackages = [ uu-werkplek ] ++ desktopItems;

        environment.etc."xdg/autostart/uu-werkplek.desktop" = lib.mkIf cfg.autostart {
          text = ''
            [Desktop Entry]
            Type=Application
            Name=UU Werkplek
            Exec=uu-werkplek
            Icon=uu-werkplek
            X-KDE-autostart-phase=2
          '';
        };

        # Gelezen door de UU Werkplek-app.
        environment.etc."dawo-uu/info.json".text = builtins.toJSON {
          werkplek = cfg.type;
          inherit (cfg) uitleg;
          revisie = inputs.self.shortRev or inputs.self.dirtyShortRev or "dirty";
          inherit dawoRelease;
        };

        programs.firefox.policies = {
          Homepage = {
            URL = "https://www.uu.nl";
            StartPage = "homepage";
          };
          ManagedBookmarks = [
            { toplevel_name = "Universiteit Utrecht"; }
          ]
          ++ map (s: {
            name = s.desktopName;
            inherit (s) url;
          }) cfg.webLinks;
        };
      };
    };
}
