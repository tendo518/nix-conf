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
    {
      devShells.default =
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            inherit overlays;
          };
        in
        pkgs.mkShellNoCC {
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
