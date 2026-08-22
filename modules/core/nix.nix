let
  nixMirrors = import ./_nix-mirrors.nix;

  # Common nix settings shared between NixOS and Darwin
  commonSettings = {
    use-xdg-base-directories = true;

    # --- Network & Fetching ---
    connect-timeout = 5;
    fallback = true;
    builders-use-substitutes = true;

    # --- Disk Space Management ---
    min-free = (5 * 1024 * 1024 * 1024); # 5GB
    max-free = (25 * 1024 * 1024 * 1024); # 25GB
  }
  // nixMirrors;

  trustedUsers =
    lib: user: adminGroup:
    lib.optional user.trusted user.name ++ [ "root" ] ++ [ adminGroup ];

  # Common module settings
  commonModule =
    { pkgs, ... }:
    {
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
