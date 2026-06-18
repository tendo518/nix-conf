# Aggregate all custom packages
#
# This file exports all packages from the packages/ directory.
# Add new packages by creating a subdirectory with default.nix
# and adding it here.
{ pkgs }:
{
  retedo-mono = pkgs.callPackage ./retedo-mono { };

  # ticktick only available on darwin
  ticktick = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ./ticktick { } else null;

  # skimpdf only available on darwin
  skimpdf = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ./skimpdf { } else null;
}
