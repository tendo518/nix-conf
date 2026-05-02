# Desktop workstation at lab
# Host configuration and module registrations
{ ... }:
{
  # Host definition
  hosts.nixos.desktop-lab-peace = {
    modules = [
      "core"
      "system"
      "development"
      "apps"
      "network"
      "desktop"
      "hosts/desktop-lab-peace"
      "hardware/nvidia"
      "hardware/fwupd"
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
      homeStateVersion = "26.05";
      extraGroups = [ "networkmanager" ];
      passwordSecret = "tendo-password.age";
    };
    hostPlatform = "x86_64-linux";
    stateVersion = "26.05";
  };

  # Home Manager configuration
  flake.modules.homeManager."hosts/desktop-lab-peace" = { ... }: { };
}
