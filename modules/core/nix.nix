{ lib, config, pkgs, ... }:

let
  # Common nix settings shared between NixOS and Darwin
  commonSettings = {
    use-xdg-base-directories = true;

    # --- Network & Fetching ---
    connect-timeout = lib.mkDefault 5;
    fallback = true;
    builders-use-substitutes = true;

    # --- Substituters ---
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];

    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];

    # --- Trusted Users ---
    trusted-users =
      let
        user = config.host.user;
      in
      lib.optional user.trusted user.name
      ++ [ "root" ]
      ++ (if pkgs.stdenv.isDarwin then [ "@admin" ] else [ "@wheel" ]);

    # --- Disk Space Management ---
    min-free = lib.mkDefault (5 * 1024 * 1024 * 1024);
    max-free = lib.mkDefault (25 * 1024 * 1024 * 1024);
  };

  # Common module settings
  commonModule = {
    # Disable legacy channels, force Flakes
    nix.channel.enable = lib.mkDefault false;

    # Auto optimize Store
    nix.optimise.automatic = true;
  };
in
{
  flake.modules.nixos."core/nix" = {
    imports = [ commonModule ];

    nix.settings = commonSettings // {
      # --- Experimental Features ---
      experimental-features = [
        "nix-command"
        "flakes"
        "auto-allocate-uids"
      ];
      auto-allocate-uids = true;
    };

    # ================================================================
    # Systemd (Linux Only)
    # ================================================================
    systemd.slices."nix-daemon".sliceConfig = {
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "80%";
    };

    systemd.services."nix-daemon" = {
      serviceConfig = {
        Slice = "nix-daemon.slice";
        Delegate = "yes";
        OOMScoreAdjust = 1000;
      };
    };
  };

  flake.modules.darwin."core/nix" = {
    imports = [ commonModule ];

    nix.settings = commonSettings // {
      # --- Experimental Features ---
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
