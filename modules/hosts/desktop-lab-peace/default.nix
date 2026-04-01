# Lab workstation (Intel i7-14700K + RTX 4070 Ti SUPER)
# Fleet configuration and module registrations
{ ... }:
{
  # Fleet host definition
  fleet.nixos.desktop-lab-peace = {
    modules = [
      "core"
      "system"
      "development"
      "apps"
      "network"
      "desktop"
      "hosts/desktop-lab-peace"
      "desktop/plasma"
      "hardware/nvidia"
      "hardware/smartd"
      "hardware/disable-sleep"
    ];
    user = {
      name = "pengwy";
      email = "pengwyuan@gmail.com";
      trusted = true;
      sshPubKey = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR"
      ];
      shell = "fish";
      homeStateVersion = "25.11";
      extraGroups = [ "networkmanager" ];
      passwordSecret = "pengwy-password.age";
    };
    stateVersion = "25.05";
  };

  # NixOS modules are defined in separate files:
  # - hardware.nix: kernel, CPU, hardware detection
  # - disko.nix: disk partitioning, LUKS, btrfs subvolumes
  # - packages.nix: system packages and services
  # - home.nix: home manager config
}