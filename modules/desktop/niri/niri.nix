{
  flake.modules.nixos."desktop/niri" =
    { pkgs, ... }:
    {
      # programs = {
      # niri.enable = true;
      # nm-applet.enable = true;
      # };
      # environment.systemPackages = [ pkgs.noctalia-shell ];
    };
  flake.modules.homeManager."desktop/niri" = {
    # qt = {
    #   enable = true;
    #   platformTheme.name = "qtct";
    # };

    # home.file.".config/niri/config.kdl".source = ./config.kdl;
  };
}
