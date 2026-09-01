{
  flake.modules.nixos."hosts/laptop-solar-chiyoko/system" =
    { pkgs, lib, ... }:
    {
      nix.settings = {
        cores = 4;
        max-jobs = 2;
      };

      # Plasma Login Manager (SDDM fork) — https://wiki.nixos.org/wiki/Plasma_Login_Manager
      # Only one display manager can be active, so disable SDDM from desktop/base.
      services.displayManager.plasma-login-manager.enable = true;
      services.displayManager.sddm.enable = lib.mkForce false;

      services.power-profiles-daemon.enable = false;
      services.tlp = {
        enable = true;
        pd.enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          # very slow and save no battery time
          # CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          # PCIE_ASPM_ON_BAT = "powersupersave";
        };
      };

      environment.systemPackages = with pkgs; [
        libcamera
        zathura
        telegram-desktop
        chromium
        chatgpt-desktop

        darktable
        imagemagick
        moonlight-qt
        ghostty
        maple-mono.NF-CN
      ];

    };
}
