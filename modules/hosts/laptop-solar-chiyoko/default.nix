# Lenovo ThinkPad X13s (aarch64)
# Host configuration and module registrations
{ inputs, ... }:
{
  # Host definition
  hosts.nixos.laptop-solar-chiyoko = {
    modules = [
      "core"
      "system"
      "development"
      "apps"
      "network"
      "desktop"
      "hosts/laptop-solar-chiyoko"
      "network/tailscale"
      "hardware/lenovo-x13s"
      "hardware/fwupd"
      "hardware/smartd"
    ];
    user = {
      name = "tendo";
      email = "pengwyuan@gmail.com";
      trusted = true;
      sshPubKey = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR"
      ];
      shell = "fish";
      homeStateVersion = "25.11";
      extraGroups = [ ];
      passwordSecret = "tendo-password.age";
    };
    hostPlatform = "aarch64-linux";
    stateVersion = "25.11";
  };

  # NixOS system configuration
  flake.modules.nixos."hosts/laptop-solar-chiyoko" =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [
        inputs.nixpkgs.nixosModules.notDetected
      ];

      nix.settings = {
        cores = 4;
        max-jobs = 2;
      };

      environment.systemPackages = with pkgs; [
        libreoffice
        zathura
        telegram-desktop
        chromium
        bitwarden-desktop
        darktable
        antigravity
        ghostty
        retedo-mono
      ];

      boot.loader.systemd-boot.edk2-uefi-shell.enable = true;

      networking.useDHCP = lib.mkDefault true;

      services = {
        v2raya = {
          enable = true;
          openFirewall = true;
        };
        fwupd.enable = true;
      };

      users.mutableUsers = false;

      services.userborn.enable = true; # needed by nixos-init
      system = {
        etc.overlay = {
          enable = true;
          mutable = true;
        };
        nixos-init.enable = true;
        tools = {
          nixos-option.enable = true;
          nixos-version.enable = false;
          nixos-generate-config.enable = false;
        };
      };
    };

  flake.modules.homeManager."hosts/laptop-solar-chiyoko" =
    { ... }:
    {
      imports = [ ];
    };
}
