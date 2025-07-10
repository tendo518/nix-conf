{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];
  nix.settings = {
    cores = 4;
    # 限制同时构建的包数量
    max-jobs = 2;
  };

  # ===== Host-Specific Configuration =====
  environment.systemPackages = with pkgs; [
    wechat
    qq
    libreoffice
    zathura
    telegram-desktop
    chromium
    bitwarden-desktop
    darktable
    antigravity
    deskflow
    ghostty
    iosevka-lnxw
  ];

  boot.kernelPackages = pkgs.linuxPackages_zen;
  services.v2raya.enable = true;

  boot.loader.systemd-boot.edk2-uefi-shell.enable = true;
  boot.loader.systemd-boot.windows = {
    "win11" = {
      title = "Windows 11";
      efiDeviceHandle = "HD0d";
      sortKey = "z_windows";
    };
  };

  system.etc.overlay.enable = true;
  system.etc.overlay.mutable = false;
  services.userborn.enable = true;
  services.fwupd.enable = true;
}
