{
  flake.modules.nixos."desktop-environments/gnome" =
    {
      pkgs,
      ...
    }:
    {
      services.xserver = {
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };

      environment.gnome.excludePackages = with pkgs; [
        atomix # puzzle game
        # cheese # webcam tool
        # epiphany # web browser
        # evince # document viewer
        geary # email reader
        gedit # text editor
        gnome-characters
        gnome-music
        gnome-photos
        gnome-terminal
        gnome-tour
        hitori # sudoku game
        iagno # go game
        tali # poker game
        totem # video player
        decibels # audio player
        gnome-maps
        gnome-weather
        gnome-console
      ];

      # extension
      environment.systemPackages = with pkgs; [
        gnome-tweaks
        adw-gtk3 # libadwait theme for gtk3 app
        gnomeExtensions.kimpanel # input method panel for fcitx5
        gnomeExtensions.clipboard-indicator # clipboard manager
        gnomeExtensions.appindicator # appindicator extension
      ];
      services.udev.packages = [ pkgs.gnome-settings-daemon ]; # enable app indicator

      programs.dconf.profiles.user.databases = [
        {
          settings = {
            "org/gnome/mutter" = {
              experimental-features = [
                "scale-monitor-framebuffer" # Enables fractional scaling (125% 150% 175%)
                "variable-refresh-rate" # Enables Variable Refresh Rate (VRR) on compatible displays
                "xwayland-native-scaling" # Scales Xwayland applications to look crisp on HiDPI screens
              ];
            };
          };
        }
      ];

      qt = {
        enable = true;
        platformTheme = "gnome";
        style = "adwaita-dark";
      };
    };
}
