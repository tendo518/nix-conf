{ config, ... }:
let
  profiles = import ../../profiles/default.nix;
in
{
  flake.modules.nixos."desktop-home-saki-system" = ./system/default.nix;
  flake.modules.homeManager."desktop-home-saki-home" = ./home/tendo.nix;

  flake.modules.nixos."nixosConfigurations/desktop-home-saki" = config.flake.lib.mkHost {
    systemType = "nixos";
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
    stateVersion = "25.05";
    modules = profiles.desktop.modules ++ [
      "desktop-home-saki-system"
      "desktop-home-saki-home"
      "desktop-environments/plasma"
      "hardware/nvidia"
      "hardware/smartd"
      "hardware/disable-sleep"
    ];
    inherit config;
  };
}
