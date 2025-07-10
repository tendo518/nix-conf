{
  stdenv,
  lib,
  unzip,
  fetchurl,
}:
stdenv.mkDerivation rec {
  pname = "keepingyouawake";
  version = "1.6.8";

  src = fetchurl {
    name = "KeepingYouAwake-${version}.zip";
    url = "https://github.com/newmarcel/KeepingYouAwake/releases/download/${version}/KeepingYouAwake-${version}.zip";
    hash = "sha256-gAGhSbRJDACP2sGYmLzpkC1RbEqmQSp+sPmjdEOxXGs=";
  };

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
