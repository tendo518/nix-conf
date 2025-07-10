{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  imports = [
    ./brew-pkgs.nix
  ];

  networking.hostName = config.host.hostname;
  networking.computerName = config.host.hostname;
  system.defaults.smb.NetBIOSName = config.host.hostname; # ===== Host Meta Configuration =====
  nixpkgs.hostPlatform = "aarch64-darwin";
  # Applications installed via nixpkgs (reproducible)
  environment.systemPackages = with pkgs; [
    # Web Browsers
    google-chrome
    obsidian
    skimpdf
    spotify

    # Graphics & Media
    inkscape
    darktable

    # Productivity
    localsend
    # zotero  # wtf it trigger building firefox esr on darwin
    alt-tab-macos
    ticktick

    # Communication
    wechat
    telegram-desktop
    qq

    stats
    # Terminal
    ghostty-bin # use bin on darwin

    # Gaming
    moonlight-qt

    # Other
    antigravity
    bitwarden-desktop
  ];
}
