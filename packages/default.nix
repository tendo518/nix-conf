# Aggregate all custom packages.
#
# This file exports all packages from the packages/ directory.
# Add new packages by creating a subdirectory with default.nix
# and adding it here. Platform-specific packages should return null
# on unsupported host platforms.
{ pkgs, inputs }:
{
  # ticktick only available on darwin
  ticktick = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ./ticktick { } else null;

  # skimpdf only available on darwin
  skimpdf = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ./skimpdf { } else null;

  # deskflow only available on darwin
  deskflow = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ./deskflow { } else null;

  # ChatGPT desktop: official artifact on macOS; llm-agents' Linux-only chatgpt on Linux
  chatgpt-desktop =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.callPackage ./chatgpt-desktop { }
    else if pkgs.stdenv.hostPlatform.isLinux then
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.chatgpt
    else
      null;

  # clash-verge-rev only available on darwin
  clash-verge-rev =
    if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ./clash-verge-rev { } else null;

  # tencent-meeting only available on darwin
  tencent-meeting =
    if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ./tencent-meeting { } else null;

  # keepingyouawake only available on darwin
  keepingyouawake =
    if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ./keepingyouawake { } else null;

  # zotero: official universal DMG on darwin
  zotero = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ./zotero { } else null;
}
