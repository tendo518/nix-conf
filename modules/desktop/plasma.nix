{
  flake.modules.nixos."desktop/plasma" =
    {
      config,
      pkgs,
      ...
    }:
    {
      environment.sessionVariables = {
        GTK_CSD = "0"; # disable csd for some gtk3 apps
      };
      environment.systemPackages = with pkgs; [
        papirus-icon-theme
        kdePackages.sddm-kcm
        qalculate-qt
      ];
      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        elisa # use mpv for audio
        discover
        kate
        khelpcenter
        konsole
      ];
      services.displayManager.sddm = {
        enable = true;
        enableHidpi = true;
        wayland.enable = true;
        wayland.compositor = "kwin";
      };
      services.desktopManager.plasma6 = {
        enable = true;
      };

      # Make Firefox use the KDE file picker.
      # Preferences source: https://wiki.archlinux.org/title/firefox#KDE_integration
      programs.firefox = {
        preferences = {
          "widget.use-xdg-desktop-portal.file-picker" = 1;
        };
      };

      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
        config.kde = {
          default = [
            "kde"
          ];
        };
      };

      # nm user
      users.users =
        let
          user = config.host.user.name;
        in
        {
          "${user}".extraGroups = [ "networkmanager" ];
        };

      # System-wide MIME defaults — Plasma is free to modify ~/.config/mimeapps.list
      xdg.mime.defaultApplications = {
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

        "application/pdf" = "okularApplication_pdf.desktop";
        "application/x-pdf" = "okularApplication_pdf.desktop";

        "text/plain" = "code.desktop";
        "text/css" = "code.desktop";
        "application/json" = "code.desktop";
        "application/x-shellscript" = "code.desktop";
        "application/x-python" = "code.desktop";

        "image/gif" = "org.kde.gwenview.desktop";
        "image/jpeg" = "org.kde.gwenview.desktop";
        "image/png" = "org.kde.gwenview.desktop";
        "image/webp" = "org.kde.gwenview.desktop";
        "image/svg+xml" = "org.kde.gwenview.desktop";

        "audio/*" = "mpv.desktop";
        "video/*" = "mpv.desktop";
        "audio/mp3" = "mpv.desktop";
        "audio/mp4" = "mpv.desktop";
        "video/mp4" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";

        "inode/directory" = "org.kde.dolphin.desktop";
        "application/x-terminal-emulator" = "kitty.desktop";
      };

      xdg.mime.removedAssociations = {
        "application/pdf" = "firefox.desktop";
        "text/plain" = "code.desktop";
      };
    };
  flake.modules.homeManager."desktop/plasma" =
    { config, pkgs, ... }:
    {
      # Terminal emulator setting
      xdg.terminal-exec = {
        enable = true;
        settings = {
          default = [ "kitty.desktop" ];
        };
      };
    };
}
