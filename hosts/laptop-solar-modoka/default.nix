{ config, ... }:
let
  profiles = import ../../profiles/default.nix;
in
{
  flake.modules.darwin."laptop-solar-modoka-system" = ./system/default.nix;
  flake.modules.homeManager."laptop-solar-modoka-home" = ./home/tendo.nix;

  flake.modules.darwin."darwinConfigurations/laptop-solar-modoka" = config.flake.lib.mkHost {
    systemType = "darwin";
    user = {
      name = "tendo";
      email = "pengwyuan@gmail.com";
      trusted = true;
      sshPubKey = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR"
      ];
      shell = "fish";
      homeStateVersion = "25.05";
    };
    stateVersion = 6;
    modules = profiles.darwin-laptop.modules ++ [
      "laptop-solar-modoka-system"
      "laptop-solar-modoka-home"
      "desktop/fonts"
      "apps/firefox-home"
      "apps/kitty"
      "apps/mpv"
      "apps/vscode"
      "networking/tailscale"
    ];
    inherit config;
  };
}
