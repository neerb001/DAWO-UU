{
  # Alleen voor het lab: UU-werkplekken als QEMU-VM's op een Mac met Apple
  # Silicon (aarch64), beheerd vanuit een beheer-VM. Echte apparaten gebruiken
  # in plaats hiervan een hardwareblok (hardware-*) en disko.
  flake.modules.nixos.uu-lab =
    {
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        "${modulesPath}/virtualisation/disk-image.nix"
        "${modulesPath}/profiles/qemu-guest.nix"
      ];

      nixpkgs.hostPlatform = "aarch64-linux";

      # Zelfde schijfindeling als het basis-image (ext4 + ESP), zodat een
      # uitrol over het basis-image heen gewoon opstart.
      image.format = "qcow2";
      boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
      boot.kernelParams = [ "console=ttyAMA0,115200" ];
      services.qemuGuest.enable = true;
      services.spice-vdagentd.enable = true; # klembord met de Mac

      # Leeg tot de eerste uitrol: de VM geeft zijn naam via SMBIOS mee.
      networking.hostName = lib.mkDefault "";

      # Uitrol vanuit de beheer-VM via DAWO's deploy-gebruiker (deploy-rs).
      # users-deploy maakt een systeemaccount zonder login-shell (nologin), waardoor
      # deploy-rs niet kan inloggen; geef het hier de standaard-shell.
      users.users.deploy.useDefaultShell = true;
      users.users.deploy.openssh.authorizedKeys.keyFiles = [
        ../../uu/keys/uu-beheer-vm.pub
        ../../uu/keys/lab-automation.pub
        ../../uu/keys/tim-mac.pub
      ];

      # Lab-wachtwoord voor het noodbeheeraccount "dawo": uu-beheer.
      dawo.bootstrapUser.initialHashedPassword = "$y$j9T$Vw2A.2wJFEuktkVOER4hV.$HL2YKoKSLLb/JIh/A3cx/PQNoMuYUNLEKO4WQ3n8.b3";

      # In het lab duwt de beheer-VM updates (deploy-rs). Op echte apparaten
      # halen ze die zelf op (comin, zie profiles-uu).
      dawo.autoUpdate.enable = lib.mkForce false;
    };
}
