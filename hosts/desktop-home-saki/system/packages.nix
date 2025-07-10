{ pkgs, lib, ... }:
{
  # this rebuild toooo many
  # nixpkgs.config.cudaSupport = true;

  services.v2raya.enable = true;

  environment.systemPackages = with pkgs; [
    # Office & Productivity
    spotify
    spotify-qt

    obsidian
    wechat
    qq
    protonplus
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

    # # GPU related
    # cudatoolkit

    # Fun
    # jhentai

    # some python may link to
    gcc
    clang

    antigravity

    cudaPackages.cudatoolkit
    realesrgan-ncnn-vulkan
  ];

  # make sure non-nix programs can find cuda
  environment.sessionVariables = {
    CUDA_HOME = pkgs.cudaPackages.cudatoolkit;
    CUDA_PATH = pkgs.cudaPackages.cudatoolkit;
  };

  programs.nix-ld.libraries =
    (with pkgs.cudaPackages; [
      cudatoolkit
      # cudnn
      # nccl
    ])
    ++ (with pkgs; [
      stdenv.cc.cc
    ]);
  # environment.sessionVariables = {
  #   LD_LIBRARY_PATH = lib.makeLibraryPath [
  #     pkgs.cudaPackages.cudatoolkit
  #     pkgs.zlib
  #   ];
  # };

  # override to use cuda or failed to start
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    package = pkgs.sunshine.override {
      cudaSupport = true;
    };
  };
}
