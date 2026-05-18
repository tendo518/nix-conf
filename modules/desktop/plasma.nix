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

      services.displayManager.sddm.wayland.compositor = "kwin";
      services.desktopManager.plasma6.enable = true;

      xdg.portal.config.kde = {
        default = [
          "kde"
        ];
      };

      # Plasma-specific MIME types
      xdg.mime.defaultApplications = {
        "application/pdf" = "okularApplication_pdf.desktop";
        "application/x-pdf" = "okularApplication_pdf.desktop";

        "image/gif" = "org.kde.gwenview.desktop";
        "image/jpeg" = "org.kde.gwenview.desktop";
        "image/png" = "org.kde.gwenview.desktop";
        "image/webp" = "org.kde.gwenview.desktop";
        "image/svg+xml" = "org.kde.gwenview.desktop";

        "inode/directory" = "org.kde.dolphin.desktop";
      };
    };
}
