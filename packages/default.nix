# Aggregate all custom packages
#
# This file exports all packages from the packages/ directory.
# Add new packages by creating a subdirectory with default.nix
# and adding it here.
{ pkgs }:
{
  # ticktick only available on darwin
  ticktick = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ./ticktick { } else null;

  # skimpdf only available on darwin
  skimpdf = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ./skimpdf { } else null;

  # deskflow only available on darwin
  deskflow = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ./deskflow { } else null;

  # codex desktop only available on darwin
  codex-desktop =
    if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ./codex-desktop { } else null;

  # clash-verge-rev only available on darwin
  clash-verge-rev =
    if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ./clash-verge-rev { } else null;
}
