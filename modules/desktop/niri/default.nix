{
  flake.modules.nixos."desktop/niri" =
    {
      pkgs,
      hostContext,
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
        ghostty
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
      home-manager.users.${hostContext.user.name} = {
        xdg.configFile."niri/config.kdl".source = ./config.kdl;

        # niri sessions are systemd-managed, so the fcitx5 package's XDG
        # autostart entry becomes app-org.fcitx.Fcitx5@autostart.service in
        # addition to home-manager's fcitx5-daemon.service and the two race for
        # the DBus name ("Is there another fcitx already running?"). A
        # user-level autostart entry with the same name and Hidden=true
        # shadows the packaged one, leaving a single starter.
        xdg.configFile."autostart/org.fcitx.Fcitx5.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Fcitx 5
          Hidden=true
        '';
      };
    };
}
