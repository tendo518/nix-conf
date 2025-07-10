{
  flake.modules.nixos."core/nix" =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      # ================================================================
      # 2. Nix Daemon & Build Settings
      # ================================================================

      # Disable legacy channels, force Flakes
      nix.channel.enable = lib.mkDefault false;

      # Auto optimize Store
      nix.optimise.automatic = true;

      # ================================================================
      # 3. Core Nix Settings (nix.settings)
      # ================================================================
      nix.settings = {
        # --- Experimental Features ---
        experimental-features = [
          "nix-command"
          "flakes"
        ]; # ++ lib.optional pkgs.stdenv.isLinux "auto-allocate-uids" (moved to nixos module)

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

      # ================================================================
      # 4. Systemd (Linux Only)
      # ================================================================
      # 将 nix-daemon 放入独立的 systemd slice，并配置 OOM 策略
      systemd.slices."nix-daemon".sliceConfig = {
        # 允许 systemd-oomd 在内存压力过大时介入
        ManagedOOMMemoryPressure = "kill";
        # 达到 80% 内存压力时开始干预
        ManagedOOMMemoryPressureLimit = "80%";
      };

      systemd.services."nix-daemon" = {
        serviceConfig = {
          Slice = "nix-daemon.slice";
          # 开启 Delegation，使 OOM 只杀具体编译子进程，不杀守护进程本身
          Delegate = "yes";
          # 提高被 OOM Killer 选中的优先级（1000 为最高）。
          # 配合 Delegate=yes，内核会优先杀掉这个服务下的"叶子节点"（即吃内存的 cc1plus 等编译进程），而放过你的桌面和浏览器。
          OOMScoreAdjust = 1000;
        };
      };
    };

  flake.modules.darwin."core/nix" =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      # Disable legacy channels, force Flakes
      nix.channel.enable = lib.mkDefault false;

      # Auto optimize Store
      nix.optimise.automatic = true;

      nix.settings = {
        # --- Experimental Features ---
        experimental-features = [
          "nix-command"
          "flakes"
        ];

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
          lib.optional user.trusted user.name ++ [ "root" ] ++ [ "@admin" ];

        # --- Disk Space Management ---
        min-free = lib.mkDefault (5 * 1024 * 1024 * 1024);
        max-free = lib.mkDefault (25 * 1024 * 1024 * 1024);

        use-xdg-base-directories = true;
      };
    };
}
