{
  stdenvNoCC,
  lib,
  undmg,
  sources,
}:

let
  isArm = stdenvNoCC.hostPlatform.isAarch64;
  source = if isArm then sources.flclash-arm64 else sources.flclash-amd64;
in
stdenvNoCC.mkDerivation rec {
  pname = "flclash";
  inherit (source) version src;

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  # Keep the app bundle byte-identical so its ad-hoc signature stays valid.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R FlClash.app $out/Applications
    runHook postInstall
  '';

  meta = {
    description = "Multi-platform proxy client based on ClashMeta";
    homepage = "https://github.com/chen08209/FlClash";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.darwin;
    mainProgram = "FlClash.app";
  };
}
