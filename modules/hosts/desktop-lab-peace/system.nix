# System packages and services
{ inputs, lib, ... }:
{
  flake.modules.nixos."hosts/desktop-lab-peace/system" =
    { pkgs, config, ... }:
    {
      environment.systemPackages = with pkgs; [
        # Office & Productivity
        spotify
        obsidian
        # yt-dlp  # upstream deno build fail
        qq
        obs-studio
        libreoffice
        calibre
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

        # Texlive for Chinese/English writing with IEEE templates
        texlive.combined.scheme-full
        # (pkgs.texlive.combine {
        #   inherit (pkgs.texlive)
        #     scheme-medium
        #     collection-langchinese
        #     latexmk
        #     ieeetran
        #     biblatex
        #     biber
        #     ;
        # })
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

      # SDDM autologin
      services.displayManager.autoLogin = {
        enable = true;
        user = config.host.user.name;
      };

      # Network
      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };
      programs.clash-verge = {
        enable = true;
        tunMode = true;
        serviceMode = true;
      };

      # Game streaming
      services.sunshine = {
        enable = true;
        openFirewall = true;
        capSysAdmin = true;
        package = pkgs.sunshine.override { cudaSupport = true; };
      };
      # fix upsteam: https://github.com/NixOS/nixpkgs/issues/455737
      hardware.uinput.enable = true;
      users.groups.hqlab = {
        gid = 11000;
      };
      users.users =
        let
          user = config.host.user.name;
        in
        {
          "${user}".extraGroups = [ "wireshark" "hqlab" ];
        };

      # Local file sharing
      programs.localsend = {
        enable = true;
        openFirewall = true;
      };

      # User management
      users.mutableUsers = false;
      services.userborn.enable = true;

      system = {
        etc.overlay = {
          enable = true;
          mutable = true;
        };
        nixos-init.enable = true;
        tools = {
          nixos-option.enable = true;
          nixos-version.enable = false;
          nixos-generate-config.enable = false;
        };
      };

      # NFS mounts for NAS
      boot.supportedFilesystems = [ "nfs" ];
      services.rpcbind.enable = true;

      systemd.mounts = [
        {
          type = "nfs4";
          mountConfig.Options = "noatime";
          what = "172.18.36.179:/volume2/public_dataset_nas2";
          where = "/mnt/hqlab_nas2";
        }
        {
          type = "nfs4";
          mountConfig.Options = "noatime";
          what = "172.18.36.180:/volume1/Dataset";
          where = "/mnt/hqlab_nas3";
        }
        {
          type = "nfs4";
          mountConfig.Options = "noatime";
          what = "172.18.36.178:/volume1/public_dataset_nas";
          where = "/mnt/hqlab_nas1";
        }
      ];

      systemd.automounts = [
        {
          wantedBy = [ "multi-user.target" ];
          automountConfig.TimeoutIdleSec = "600";
          where = "/mnt/hqlab_nas2";
        }
        {
          wantedBy = [ "multi-user.target" ];
          automountConfig.TimeoutIdleSec = "600";
          where = "/mnt/hqlab_nas3";
        }
        {
          wantedBy = [ "multi-user.target" ];
          automountConfig.TimeoutIdleSec = "600";
          where = "/mnt/hqlab_nas1";
        }
      ];
    };
}
