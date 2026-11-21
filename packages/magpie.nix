{
  stdenvNoCC,
  lib,
  _7zz,
  sources,
}:

let
  appSource =
    if stdenvNoCC.hostPlatform.isAarch64 then sources.magpie-arm64 else sources.magpie-amd64;
  cliSource =
    if stdenvNoCC.hostPlatform.isDarwin then
      if stdenvNoCC.hostPlatform.isAarch64 then sources.magpie-cli-arm64 else sources.magpie-cli-amd64
    else if stdenvNoCC.hostPlatform.isAarch64 then
      sources.magpie-cli-linux-arm64
    else
      sources.magpie-cli-linux-amd64;

  commonMeta = {
    homepage = "https://usemagpie.ai";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
in
{
  magpie = stdenvNoCC.mkDerivation {
    pname = "magpie";
    inherit (appSource) version src;

    # Magpie's DMG uses APFS; undmg only supports HFS.
    nativeBuildInputs = [ _7zz ];

    unpackCmd = ''
      7zz x -snld "$curSrc"
    '';

    sourceRoot = ".";

    # Leave the extracted bundle's files alone before ad-hoc signing.
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications
      cp -R magpie.app $out/Applications

      app=$out/Applications/magpie.app

      # The upstream Developer ID signature fails verification. Replace it with
      # an ad-hoc signature and validate the installed bundle in the build.
      rm -f "$app/Contents/CodeResources"
      chmod -R u+w "$app"
      /usr/bin/codesign --force --deep --sign - "$app"
      /usr/bin/codesign --verify --deep --strict "$app"

      runHook postInstall
    '';

    meta = commonMeta // {
      description = "One place to pick every AI agent's model";
      mainProgram = "magpie.app";
      platforms = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    };
  };

  magpie-cli = stdenvNoCC.mkDerivation {
    pname = "magpie-cli";
    inherit (cliSource) version src;

    dontUnpack = true;

    # Keep the signed release binary byte-identical.
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      install -m755 "$src" $out/bin/magpie
      runHook postInstall
    '';

    meta = commonMeta // {
      description = "Terminal build of Magpie for configuring AI agents";
      mainProgram = "magpie";
      platforms = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    };
  };
}
