{
  flake.modules.homeManager."apps/wine" =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        wineWow64Packages.wayland
        winetricks
      ];
    };
}
