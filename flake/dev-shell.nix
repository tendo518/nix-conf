# Development shell configuration
#
# Provides default dev shell with Nix tools: nixfmt, deadnix, statix,
# nixd (LSP), just, nh, nixos-anywhere, git, direnv, age.
{ config, inputs, ... }:
let
  overlays = builtins.attrValues (config.flake.overlays or { });
in
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
    in
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          deadnix
          just
          nixd
          nixfmt
          statix
          nixos-anywhere
          git
          nh
          nixfmt-tree
          direnv
          nix-direnv
          age
        ];
      };
    };
}
