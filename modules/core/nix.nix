let
  # Common nix settings shared between NixOS and Darwin
  commonSettings = {
    use-xdg-base-directories = true;

    # --- Network & Fetching ---
    connect-timeout = 5;
    fallback = true;
    builders-use-substitutes = true;

    # --- Disk Space Management ---
    min-free = 5 * 1024 * 1024 * 1024; # 5GB
    max-free = 25 * 1024 * 1024 * 1024; # 25GB
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirror.nju.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  trustedUsers =
    lib: user: adminGroup:
    lib.optional user.trusted user.name ++ [ "root" ] ++ [ adminGroup ];

  # Common module settings
  commonModule = _: {
    # Disable legacy channels, force Flakes
    nix.channel.enable = false;

    # Auto optimize Store
    nix.optimise.automatic = true;
  };
in
{
  flake.modules.nixos."core/nix" =
    { hostContext, lib, ... }:
    {
      imports = [ commonModule ];

      nix.settings = commonSettings // {
        # --- Experimental Features ---
        experimental-features = [
          "nix-command"
          "flakes"
          "auto-allocate-uids"
          "cgroups"
        ];
        auto-allocate-uids = true;
        use-cgroups = true;
        # --- Trusted Users ---
        trusted-users = trustedUsers lib hostContext.user "@wheel";
      };

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

  flake.modules.darwin."core/nix" =
    { hostContext, lib, ... }:
    {
      imports = [ commonModule ];

      nix.settings = commonSettings // {
        # --- Experimental Features ---
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        # --- Trusted Users ---
        trusted-users = trustedUsers lib hostContext.user "@admin";
      };

    };
}
