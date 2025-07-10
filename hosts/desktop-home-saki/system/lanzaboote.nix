{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  lanzaboote = inputs.lanzaboote;

  luksCryptenroller = pkgs.writeTextFile {
    name = "luksCryptenroller";
    destination = "/bin/luksCryptenroller";
    executable = true;

    # Note: You can hardcode additional LUKS devices like so:
    # text = let
    #   ...
    #   luksDevice02 = "BEEGLUKS01";
    #   luksDevice03 = "BEEGLUKS02";
    # in ''
    #   ...
    #   sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0+7 /dev/disk/by-label/${luksDevice02}
    #   sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0+7 /dev/disk/by-label/${luksDevice03}
    # '';

    text =
      let
        luksDevice01 = "NIXLUKS";
      in
      ''
        sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0+7 /dev/disk/by-label/${luksDevice01}
      '';
  };
in
{
  # How to enter setup mode - ASUS motherboard
  ## 1. enter BIOS via [Del] Key
  ## 2. <Advance mode> => <Settings> => <Security> => <Secure Boot>
  ## 3. enable <Secure Boot>
  ## 4. set <Secure Boot Mode> to <Custom>
  ## 5. enter <Key Management>
  ## 6. select <Delete All Secure Boot Variables>, and then select <No> for <Reboot Without Saving>
  ## 7. Press F10 to saving and reboot.
  imports = [
    lanzaboote.nixosModules.lanzaboote
  ];

  environment.systemPackages = [
    luksCryptenroller
    # For debugging and troubleshooting Secure Boot.
    pkgs.sbctl
    pkgs.tpm2-tss
  ];

  # Lanzaboote currently replaces the systemd-boot module.
  # This setting is usually set to true in configuration.nix
  # generated at installation time. So we force it to false
  # for now.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  # necessary for tpm2 auto dec
  boot.initrd.systemd.enable = true;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
}
