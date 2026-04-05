# System packages and services
{ ... }:
{
  flake.modules.nixos."hosts/desktop-home-saki/packages" =
    { pkgs, ... }:
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
        spotify-qt
        obsidian
        # wechat # whothefuck use webarchives as curl target
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

      programs.nix-ld.libraries =
        (with pkgs.cudaPackages; [
          cudatoolkit
        ])
        ++ (with pkgs; [
          stdenv.cc.cc
        ]);

      # network
      programs.clash-verge = {
        enable = true;
        tunMode = true;
        serviceMode = true;
      };

      services.sunshine = {
        enable = true;
        capSysAdmin = true;
        package = pkgs.sunshine.override {
          cudaSupport = true;
        };
      };
    };
}
