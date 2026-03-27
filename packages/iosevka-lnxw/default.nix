{ pkgs, ... }:

let
  lockedPkgs = import (pkgs.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "2fc6539b481e1d2569f25f8799236694180c0993";
    hash = "sha256-0MAd+0mun3K/Ns8JATeHT1sX28faLII5hVLq0L3BdZU=";
  }) { inherit (pkgs.stdenv.hostPlatform) system; };
in
(lockedPkgs.iosevka.override {
  privateBuildPlan = builtins.readFile ./buildplan.toml;
  set = "lnxw";
})
