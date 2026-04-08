# Dev shell configuration
{ pkgs, ... }:
{
  perSystem =
    { config, pkgs, ... }:
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
