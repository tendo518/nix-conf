{ pkgs, lib, ... }:

let
  iosevka = pkgs.callPackage ./iosevka.nix {
    privateBuildPlan = builtins.readFile ./buildplan.toml;
    set = "RetedoMono";
  };
in
iosevka
