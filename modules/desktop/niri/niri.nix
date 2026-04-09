{
  flake.modules.nixos."desktop/niri" = {
    programs = {
      niri.enable = true;
      nm-applet.enable = true;
    };
  };
  flake.modules.homeManager."desktop/niri" =
    { pkgs, ... }:
    {
      programs.noctalia-shell = {
        enable = true;
        package = pkgs.noctalia-shell;
      };

      # qt = {
      #   enable = true;
      #   platformTheme.name = "qtct";
      # };

      home.file.".config/niri/config.kdl".source = ./config.kdl;
    };
}
