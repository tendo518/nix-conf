# Flake-parts entry point
#
# Initializes flake-parts framework, defines supported systems,
# sets default formatter, and registers custom packages.
{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.modules
  ];

  debug = true;

  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
  ];

  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt-tree;

      packages.retedo-mono = pkgs.callPackage ../../packages/retedo-mono { };
    };
}
