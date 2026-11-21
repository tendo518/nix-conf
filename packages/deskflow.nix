{
  stdenvNoCC,
  lib,
  undmg,
  sources,
}:

let
  isArm = stdenvNoCC.hostPlatform.isAarch64;
  source = if isArm then sources.deskflow-arm64 else sources.deskflow-amd64;
in
stdenvNoCC.mkDerivation {
  pname = "deskflow";
  inherit (source) version src;

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R Deskflow.app $out/Applications
    runHook postInstall
  '';

  meta = {
    description = "Mouse and keyboard sharing utility";
    homepage = "https://github.com/deskflow/deskflow";
    license = lib.licenses.gpl2Only;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.darwin;
    mainProgram = "Deskflow.app";
  };
}
