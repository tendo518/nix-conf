# System packages and services
{ inputs, lib, ... }:
{
  flake.modules.nixos."hosts/desktop-lab-peace/system" =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        # Office & Productivity
        spotify
        obsidian
        # yt-dlp  # upstream deno build fail
        bottles
        qq
        obs-studio
        libreoffice
        calibre
        localsend
        zathura
        moonlight-qt

        # Development & Browsing
        telegram-desktop
        chromium
        bitwarden-desktop
        darktable
        gcc
        clang
        antigravity
        cudaPackages.cudatoolkit
        realesrgan-ncnn-vulkan
      ];

      environment.sessionVariables = {
        CUDA_HOME = pkgs.cudaPackages.cudatoolkit;
        CUDA_PATH = pkgs.cudaPackages.cudatoolkit;
      };

      # VSCode remote SSH workaround
      systemd.tmpfiles.settings."10-vscode-remote-ssh-workaround" = {
        "/usr/lib64/".d = { };
        "/usr/lib64/libstdc++.so.6"."L+" = {
          argument = "${lib.getLib pkgs.stdenv.cc.cc}/lib/libstdc++.so.6";
        };
      };

      programs.nix-ld.libraries =
        (with pkgs.cudaPackages; [ cudatoolkit ]) ++ (with pkgs; [ stdenv.cc.cc ]);

      # Network
      programs.clash-verge = {
        enable = true;
        tunMode = true;
        serviceMode = true;
      };

      # Game streaming
      services.sunshine = {
        enable = true;
        capSysAdmin = true;
        package = pkgs.sunshine.override { cudaSupport = true; };
      };

      # User management
      users.mutableUsers = true;

      # system = {
      #   etc.overlay = {
      #     enable = true;
      #     mutable = true;
      #   };
      #   nixos-init.enable = true;
      #   tools = {
      #     nixos-option.enable = true;
      #     nixos-version.enable = false;
      #     nixos-generate-config.enable = false;
      #   };
      # };

      # # NFS mounts for NAS
      # boot.supportedFilesystems = [ "nfs" ];
      # services.rpcbind.enable = true;

      # systemd.mounts = [
      #   {
      #     type = "nfs";
      #     mountConfig.Options = "noatime,nfsvers=4.1";
      #     what = "nas-home-coin.local:/Public";
      #     where = "/mnt/NAS/Public/";
      #   }
      #   {
      #     type = "nfs";
      #     mountConfig.Options = "noatime,nfsvers=4.1";
      #     what = "nas-home-coin.local:/Photography";
      #     where = "/mnt/NAS/Photography/";
      #   }
      # ];

      # systemd.automounts = [
      #   {
      #     wantedBy = [ "multi-user.target" ];
      #     automountConfig.TimeoutIdleSec = "600";
      #     where = "/mnt/NAS/Public/";
      #   }
      #   {
      #     wantedBy = [ "multi-user.target" ];
      #     automountConfig.TimeoutIdleSec = "600";
      #     where = "/mnt/NAS/Photography/";
      #   }
      # ];
    };
}
