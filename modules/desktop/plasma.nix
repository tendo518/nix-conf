{
  flake.modules.nixos."desktop/plasma" =
    {
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
        config.common = {
          default = [
            "kde"
          ];
        };
      };
    };
  flake.modules.homeManager."desktop/plasma" =
    {
      config,
      pkgs,
      ...
    }:
    let
      # ========== Application Groups ==========
      # Each group is a list - first entry is primary, others are fallbacks

      # Web browsers
      browser = [ "firefox.desktop" ];

      # Text editors
      editor = [ "code.desktop" ];

      # PDF viewers
      pdfViewer = [ "okularApplication_pdf.desktop" ];

      # Image viewers
      imageView = [ "org.kde.gwenview.desktop" ];

      # Video/Audio players
      videoPlayer = [ "mpv.desktop" ];

      # File managers
      fileManager = [ "org.kde.dolphin.desktop" ];

      # Terminal emulator (for xdg-terminal-exec)
      terminal = [ "kitty.desktop" ];
    in
    {
      # Use KDE defaults for mimeapps
      xdg.mimeApps = {
        enable = true;

        defaultApplications = {
          # ========== Web / URL Handlers ==========
          "text/html" = browser;
          "application/xhtml+xml" = browser;
          "application/xml" = browser;
          "application/xhtml_xml" = browser;
          "application/rdf+xml" = browser;
          "application/rss+xml" = browser;
          "text/xml" = browser;

          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "x-scheme-handler/ftp" = browser;
          "x-scheme-handler/about" = browser;

          # ========== Document Handlers ==========
          "application/pdf" = pdfViewer;
          "application/x-pdf" = pdfViewer;

          # ========== Text / Code Handlers ==========
          "text/plain" = editor;
          "text/css" = editor;
          "application/json" = editor;
          "application/x-shellscript" = editor;
          "application/x-python" = editor;

          # ========== Image Handlers ==========
          "image/gif" = imageView;
          "image/jpeg" = imageView;
          "image/png" = imageView;
          "image/webp" = imageView;
          "image/svg+xml" = imageView;

          # ========== Media Handlers ==========
          "audio/*" = videoPlayer;
          "video/*" = videoPlayer;
          "audio/mp3" = videoPlayer;
          "audio/mp4" = videoPlayer;
          "video/mp4" = videoPlayer;
          "video/x-matroska" = videoPlayer;

          # ========== Directory Handler ==========
          "inode/directory" = fileManager;

          # ========== Terminal Handler ==========
          "application/x-terminal-emulator" = terminal;
        };

        # Remove unwanted associations - prevent apps from stealing handlers
        associations.removed = {
          # Prevent Firefox from handling PDFs
          "application/pdf" = [ "firefox.desktop" ];

          # Prevent VS Code from handling plain text files (keep it for code)
          "text/plain" = [ "code.desktop" ];
        };
      };

      # Terminal emulator setting (separate from mimeApps)
      xdg.terminal-exec = {
        enable = true;
        settings = {
          default = terminal;
        };
      };
    };
}
