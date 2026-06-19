{
  flake.modules.nixos."hosts/laptop-solar-chiyoko/system" =
    { pkgs, ... }:
    {
      nix.settings = {
        cores = 4;
        max-jobs = 2;
      };

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

        darktable
        moonlight-qt
        ghostty
        retedo-mono
      ];

      # Network
      programs.clash-verge = {
        enable = true;
        tunMode = true;
        serviceMode = true;
      };

      # IDK but this cause failed to boot
      # fprintd — Synaptics Prometheus sensor (standard libfprint, not TOD)
      # services.fprintd.enable = true;
    };
}
