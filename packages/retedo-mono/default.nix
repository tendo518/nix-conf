{ pkgs, lib, ... }:

(pkgs.iosevka.override {
  privateBuildPlan = builtins.readFile ./buildplan.toml;
  set = "RetedoMono";
}).overrideAttrs (final: prev: {
  version = "34.2.1";
  src = pkgs.fetchFromGitHub {
    owner = "be5invis";
    repo = "iosevka";
    rev = "v${final.version}";
    hash = "sha256-yj46lNYOzaopu5Mo68jwh+xf/q/bjMmQdprh6e56eeY=";
  };
  npmDepsHash = "sha256-it0YwPcoYCIMddktgywBuYvvx3Psghoii3pu0K3RDlI=";
})
