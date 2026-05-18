{
  flake.modules.nixos."desktop/niri" =
    {
      pkgs,
      config,
      ...
    }:
    {
      services.displayManager.sessionPackages = [ pkgs.niri ];

      xdg.portal = {
        config.niri = {
          default = [
            "gnome"
          ];
        };
        extraPortals = with pkgs; [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk
        ];
      };

      security.pam.services.swaylock = { };

      environment.systemPackages = with pkgs; [
        niri
        noctalia-shell
        brightnessctl
        playerctl
        kitty
        zathura
      ];

      # Niri-specific MIME types
      xdg.mime.defaultApplications = {
        "application/pdf" = "org.pwmt.zathura.desktop";
        "application/x-pdf" = "org.pwmt.zathura.desktop";
      };

      # niri is NixOS-only, set home-manager options directly instead of a homeManager module
      home-manager.users.${config.host.user.name} = {
        xdg.configFile."niri/config.kdl".source = ./config.kdl;
      };
    };
}
