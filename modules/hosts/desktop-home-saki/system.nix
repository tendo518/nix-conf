# System packages and services
{ inputs, lib, ... }:
{
  flake.modules.nixos."hosts/desktop-home-saki/system" =
    { pkgs, config, ... }:
    let
      luksCryptenroller = pkgs.writeTextFile {
        name = "luksCryptenroller";
        destination = "/bin/luksCryptenroller";
        executable = true;
        text =
          let
            luksDevice01 = "NIXLUKS";
          in
          ''
            sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0+7 /dev/disk/by-label/${luksDevice01}
          '';
      };
    in
    {
      environment.systemPackages = with pkgs; [
        luksCryptenroller
        sbctl
        tpm2-tss

        # Office & Productivity
        spotify
        obsidian
        yt-dlp # upstream deno build fail
        qq
        obs-studio
        libreoffice-qt6-fresh
        # calibre
        zathura
        moonlight-qt

        # Development & Browsing
        telegram-desktop
        chromium

        darktable
        gcc
        clang
        realesrgan-ncnn-vulkan
        qbittorrent
      ];

      # VSCode remote SSH workaround
      systemd.tmpfiles.settings."10-vscode-remote-ssh-workaround" = {
        "/usr/lib64/".d = { };
        "/usr/lib64/libstdc++.so.6"."L+" = {
          argument = "${lib.getLib pkgs.stdenv.cc.cc}/lib/libstdc++.so.6";
        };
      };

      # Network
      programs.clash-verge = {
        enable = true;
        tunMode = true;
        serviceMode = true;
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
          type = "nfs";
          mountConfig.Options = "noatime,nfsvers=4.1";
          what = "nas-home-coin.local:/Public";
          where = "/mnt/NAS/Public/";
        }
        {
          type = "nfs";
          mountConfig.Options = "noatime,nfsvers=4.1";
          what = "nas-home-coin.local:/Photography";
          where = "/mnt/NAS/Photography/";
        }
      ];

      systemd.automounts = [
        {
          wantedBy = [ "multi-user.target" ];
          automountConfig.TimeoutIdleSec = "600";
          where = "/mnt/NAS/Public/";
        }
        {
          wantedBy = [ "multi-user.target" ];
          automountConfig.TimeoutIdleSec = "600";
          where = "/mnt/NAS/Photography/";
        }
      ];
    };
}
