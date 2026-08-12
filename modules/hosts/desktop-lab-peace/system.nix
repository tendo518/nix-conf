# System packages and services
{ inputs, lib, ... }:
{
  flake.modules.nixos."hosts/desktop-lab-peace/system" =
    { pkgs, config, ... }:
    {
      environment.systemPackages = with pkgs; [
        wechat
        # Office & Productivity
        spotify
        obsidian
        # yt-dlp  # upstream deno build fail
        qq
        deskflow
        codex-desktop
        obs-studio
        calibre
        zathura
        moonlight-qt

        # Development & Browsing
        telegram-desktop
        chromium

        darktable
        gcc
        clang
        realesrgan-ncnn-vulkan

        # Texlive for Chinese/English writing with IEEE templates
        texliveFull
        pdf2svg
        ghostscript
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

      # VSCode remote SSH workaround
      systemd.tmpfiles.settings."10-vscode-remote-ssh-workaround" = {
        "/usr/lib64/".d = { };
        "/usr/lib64/libstdc++.so.6"."L+" = {
          argument = "${lib.getLib pkgs.stdenv.cc.cc}/lib/libstdc++.so.6";
        };
      };

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

      # User management
      users.mutableUsers = false;
      services.userborn.enable = true;

      # This is needed for HQLAB NAS access
      users.groups.hqlab = {
        gid = 110000;
      };
      users.users.${config.host.user.name}.extraGroups = [ "hqlab" ];

      system = {
        # etc.overlay = {
        #   enable = true;
        #   mutable = true;
        # };
        # nixos-init.enable = true;
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
