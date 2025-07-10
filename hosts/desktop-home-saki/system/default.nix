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
    ./lanzaboote.nix
    ./mnt-nas.nix
    ./packages.nix
  ]
  # Manual imports removed in favor of flake-parts modules
  ;

  # ===== Host-Specific Configuration =====
  boot.tmp.cleanOnBoot = true;
  boot.kernelPackages = pkgs.linuxPackages;
}
