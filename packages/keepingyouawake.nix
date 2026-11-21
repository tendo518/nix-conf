{
  stdenvNoCC,
  lib,
  unzip,
  sources,
}:

let
  source = sources.keepingyouawake;
in
stdenvNoCC.mkDerivation {
  pname = "keepingyouawake";
  inherit (source) version src;

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R KeepingYouAwake.app $out/Applications
    runHook postInstall
  '';

  meta = {
    description = "Tool to prevent the system from going into sleep mode";
    homepage = "https://keepingyouawake.app/";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.darwin;
    mainProgram = "KeepingYouAwake.app";
  };
}
