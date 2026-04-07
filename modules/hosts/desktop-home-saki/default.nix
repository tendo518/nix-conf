# Desktop workstation at home
# Fleet configuration and module registrations
{ ... }:
{
  # Fleet host definition
  fleet.nixos.desktop-home-saki = {
    modules = [
      "core"
      "system"
      "development"
      "apps"
      "network"
      "desktop"
      "hosts/desktop-home-saki"
      "desktop/plasma"
      "hardware/nvidia"
      "hardware/smartd"
      "hardware/disable-sleep"
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
      extraGroups = [ "networkmanager" ];
      passwordSecret = "tendo-password.age";
    };
    hostPlatform = "x86_64-linux";
    stateVersion = "25.05";
  };

  # NixOS modules are defined in separate files:
  # - hardware.nix: kernel, CPU, hardware detection
  # - filesystem.nix: LUKS, file systems, swap
  # - lanzaboote.nix: secure boot
  # - nfs.nix: NAS mounts
  # - packages.nix: system packages and services
  # - home.nix: home manager config
}