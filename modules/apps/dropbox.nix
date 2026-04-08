{
  flake.modules.homeManager."apps/dropbox" =
    { pkgs, ... }:
    {
      # home.packages = with pkgs; [
      #   maestral
      #   maestral-gui
      # ];
      # services.dropbox = {
      #  enable = true;
      # };
    };
}
