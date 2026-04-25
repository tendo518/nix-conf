# Flake-parts entry point
#
# Initializes flake-parts framework, defines supported systems,
# sets default formatter, and registers custom packages.
{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.modules
  ];

  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
  ];

  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt-tree;

      # Export all custom packages to flake outputs
      packages = import ../../packages { inherit pkgs; };
    };
}
