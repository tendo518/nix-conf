{ pkgs, ... }:

(pkgs.iosevka.override {
  privateBuildPlan = builtins.readFile ./buildplan.toml;
  set = "RetedoMono";
})
