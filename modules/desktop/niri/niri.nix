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
        configPackages = [ pkgs.niri ];
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

        # niri Important Software recommendations
        polkit_gnome # authentication agent
        xwayland-satellite # X11 app support
        nautilus # file manager (used by xdg-desktop-portal-gnome for file chooser)
        adwaita-icon-theme # base icon theme for GTK apps
        gnome-themes-extra # additional icons (nautilus etc.)
      ];

      # Niri-specific MIME types
      xdg.mime.defaultApplications = {
        "application/pdf" = "org.pwmt.zathura.desktop";
        "application/x-pdf" = "org.pwmt.zathura.desktop";
        "inode/directory" = "org.gnome.Nautilus.desktop";
      };

      # niri is NixOS-only, set home-manager options directly instead of a homeManager module
      home-manager.users.${config.host.user.name} = {
        xdg.configFile."niri/config.kdl".source = ./config.kdl;
      };
    };
}
