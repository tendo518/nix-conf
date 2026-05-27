# Desktop workstation at home
# Host configuration and module registrations
{ ... }:
{
  # Host definition
  hosts.nixos.desktop-home-saki = {
    modules = [
      "core"
      "system"
      "development"
      "apps"
      "network"
      "desktop"
      "hosts/desktop-home-saki"
      "hardware"
    ];
    excludeModules = [
      "desktop/niri"
      "hardware/lenovo-x13s"
    ];
    user = {
      name = "tendo";
      email = "pengwyuan@gmail.com";
      trusted = true;
      sshPubKey = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR"
      ];
      shell = "fish";
      homeStateVersion = "26.05";
      # extraGroups = [ "networkmanager" ];
      passwordSecret = "tendo-password.age";
    };
    hostPlatform = "x86_64-linux";
    stateVersion = "25.05";
  };

  # Home Manager configuration
  flake.modules.homeManager."hosts/desktop-home-saki" = { ... }: { };
}
