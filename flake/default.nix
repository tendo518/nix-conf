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
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      formatter = pkgs.nixfmt-tree;

      # Export all custom packages to flake outputs (filter out nulls from platform-conditionals)
      packages = pkgs.lib.filterAttrs (_: pkg: pkg != null) (import ../packages { inherit pkgs inputs; });
    };
}
