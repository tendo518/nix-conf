{
  flake.modules.nixos."desktop/base" =
    {
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        libinput
        wayland-utils
        wl-clipboard
        libinput
        pavucontrol
        xlsclients
        libnotify # for notify-send command in path

        # GPU related
        libva-utils # vainfo
        vulkan-tools # vulkaninfo
      ];

      # Enable Wayland for electron apps packaged by Nix
      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      # Common desktop services and settings
      services.dbus.implementation = "broker";
      services.upower.enable = true;
      services.printing.enable = true;
      services.gnome.gnome-keyring.enable = true;
      programs.dconf.enable = true;

      # Keyboard layout
      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      # flatpak
      services.flatpak.enable = false;

      # improve desktop responsiveness when updating the system
      nix.daemonCPUSchedPolicy = "idle";

      # Display manager (login screen)
      services.displayManager.sddm = {
        enable = true;
        enableHidpi = true;
        wayland.enable = true;
      };

      # XDG desktop portal
      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
      };

      # Common MIME type associations
      xdg.mime.defaultApplications = {
        # Browser
        "text/html" = "firefox.desktop";
        "application/xhtml+xml" = "firefox.desktop";
        "application/xml" = "firefox.desktop";
        "application/xhtml_xml" = "firefox.desktop";
        "application/rdf+xml" = "firefox.desktop";
        "application/rss+xml" = "firefox.desktop";
        "text/xml" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/ftp" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";

        # Text / code editor
        "text/plain" = "code.desktop";
        "text/css" = "code.desktop";
        "application/json" = "code.desktop";
        "application/x-shellscript" = "code.desktop";
        "application/x-python" = "code.desktop";

        # Media player
        "audio/*" = "mpv.desktop";
        "video/*" = "mpv.desktop";
        "audio/mp3" = "mpv.desktop";
        "audio/mp4" = "mpv.desktop";
        "video/mp4" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";

        # Terminal
        "application/x-terminal-emulator" = "com.mitchellh.ghostty.desktop";
      };

      xdg.mime.removedAssociations = {
        "application/pdf" = "firefox.desktop";
      };
    };
  flake.modules.home."desktop/base" =

    {
      config,
      pkgs,
      inputs,
      ...
    }:
    {
      home.packages = with pkgs; [
        xdg-utils # provides cli tools such as `xdg-mime` `xdg-open`
        xdg-user-dirs
      ];

      # XDG base directory env vars are set in core/xdg
      xdg.userDirs = {
        enable = true;
        createDirectories = true;
        setSessionVariables = true;
        extraConfig = {
          SCREENSHOTS = "${config.xdg.userDirs.pictures}/Screenshots";
        };
      };

      # GTK / dconf defaults for non-GNOME/Plasma desktops
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          icon-theme = "Adwaita";
        };
      };

      # Default terminal emulator
      xdg.terminal-exec = {
        enable = true;
        settings = {
          default = [ "com.mitchellh.ghostty.desktop" ];
        };
      };

    };
}
