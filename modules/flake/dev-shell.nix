# Development shell configuration
#
# Provides default dev shell with Nix tools: nixfmt, deadnix, statix,
# nixd (LSP), just, nh, nixos-anywhere, git, direnv, age.
{
  perSystem =
    { pkgs, ... }:
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
