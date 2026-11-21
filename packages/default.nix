# Aggregate all custom packages.
#
# This file exports all packages from the packages/ directory.
# Add new packages by creating a .nix file
# and adding it here. Platform-specific packages should return null
# on unsupported host platforms.
{ pkgs }:
let
  sources = import ./sources.nix { inherit pkgs; };
  gwfoxThemes = pkgs.callPackage ./gwfox.nix { inherit sources; };
in
{
  # Magpie release CLI binaries for Linux and Apple Silicon macOS.
  magpie =
    if
      builtins.elem pkgs.stdenv.hostPlatform.system [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ]
    then
      pkgs.callPackage ./magpie.nix { inherit sources; }
    else
      null;

  # gwfox Firefox theme (Linux)
  "gwfox" = gwfoxThemes.gwfox;

  # GWfox-T Firefox theme (macOS)
  "gwfox-t" = gwfoxThemes.gwfox-t;

  # fcitx5-macos: prebuilt Apple Silicon input method app bundle with Rime
  fcitx5-macos =
    if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64 then
      pkgs.callPackage ./fcitx5-macos.nix { inherit sources; }
    else
      null;

  # ticktick only available on darwin
  ticktick =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.callPackage ./ticktick.nix { inherit sources; }
    else
      null;

  # skimpdf only available on darwin
  skimpdf =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.callPackage ./skimpdf.nix { inherit sources; }
    else
      null;

  # deskflow only available on darwin
  deskflow =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.callPackage ./deskflow.nix { inherit sources; }
    else
      null;

  # flclash only available on darwin
  flclash =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.callPackage ./flclash.nix { inherit sources; }
    else
      null;

  # tencent-meeting only available on darwin
  tencent-meeting =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.callPackage ./tencent-meeting.nix { inherit sources; }
    else
      null;

  # keepingyouawake only available on darwin
  keepingyouawake =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.callPackage ./keepingyouawake.nix { inherit sources; }
    else
      null;

  # zotero: official universal DMG on darwin
  zotero =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.callPackage ./zotero.nix { inherit sources; }
    else
      null;

  # workbuddy-cn: Tencent WorkBuddy, arm64-only DMG on darwin
  workbuddy-cn =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.callPackage ./workbuddy-cn.nix { inherit sources; }
    else
      null;

  # deepseek-harness: DeepSeek desktop client, arm64-only zip on darwin
  deepseek-harness =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.callPackage ./deepseek-harness.nix { inherit sources; }
    else
      null;

  # coteditor: text editor DMG on darwin
  coteditor =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.callPackage ./coteditor.nix { inherit sources; }
    else
      null;
}
