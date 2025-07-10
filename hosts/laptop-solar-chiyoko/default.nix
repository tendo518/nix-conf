{ config, ... }:
let
  profiles = import ../../profiles/default.nix;
in
{
  flake.modules.nixos."laptop-solar-chiyoko-system" = ./system/default.nix;
  flake.modules.homeManager."laptop-solar-chiyoko-home" = ./home/tendo.nix;

  flake.modules.nixos."nixosConfigurations/laptop-solar-chiyoko" = config.flake.lib.mkHost {
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
    stateVersion = "25.11";
    modules = profiles.desktop.modules ++ [
      "laptop-solar-chiyoko-system"
      "laptop-solar-chiyoko-home"
      "desktop-environments/plasma"
      "hardware/smartd"
      "hardware/disable-sleep"
    ];
    inherit config;
  };
}
