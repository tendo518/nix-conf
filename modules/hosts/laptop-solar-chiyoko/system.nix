{
  flake.modules.nixos."hosts/laptop-solar-chiyoko/system" =
    { config, pkgs, lib, ... }:
    {
      nix.settings = {
        cores = 4;
        max-jobs = 2;
      };

      # Plasma Login Manager (SDDM fork) — https://wiki.nixos.org/wiki/Plasma_Login_Manager
      # Only one display manager can be active, so disable SDDM from desktop/base.
      services.displayManager.plasma-login-manager.enable = true;
      services.displayManager.sddm.enable = lib.mkForce false;

      # Synaptics Prometheus fingerprint reader (USB 06cb:00fc, supported by
      # libfprint). enablePam would add fingerprint auth to every PAM service
      # (including sudo/sshd), so keep it off and opt in per client; see
      # https://github.com/NixOS/nixpkgs/issues/442117.
      services.fprintd = {
        enable = true;
        enablePam = false;
      };
      # Opt in sudo explicitly; its prompt can be triggered by a background
      # process, which is why enablePam stays off (see above).
      security.pam.services.sudo.fprintAuth = true;
      # Fingerprint at the Plasma Login Manager greeter. Not enabled via
      # `fprintAuth` (plasmalogin sets `useDefaultRules = false`), and
      # deliberately not on `login`: the noctalia lock screen authenticates
      # through it and would then wait for a finger even after a correct
      # password. Order the rule after `login`, so a typed password still wins
      # immediately and an empty submit starts the fingerprint check.
      security.pam.services.plasmalogin.rules.auth.fprintd = {
        order =
          config.security.pam.services.plasmalogin.rules.auth.login.order + 100;
        control = "sufficient";
        modulePath = "${config.services.fprintd.package}/lib/security/pam_fprintd.so";
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
        google-chrome
        llm-agents.herdr-app # desktop GUI, backed by herdr-core
        llm-agents.chatgpt

        darktable
        imagemagick
        moonlight-qt
        ghostty
      ];

    };
}
