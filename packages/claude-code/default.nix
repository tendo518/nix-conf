{ pkgs, callPackage, ... }:
{
  claude-code = callPackage ./source.nix { };
  claude-code-bin = callPackage ./bin.nix { };
}
