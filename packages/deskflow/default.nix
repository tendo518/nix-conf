{
  stdenv,
  lib,
  undmg,
  fetchurl,
}:

let
  isArm = stdenv.hostPlatform.isAarch64;
  arch = if isArm then "arm64" else "x86_64";
  # sha256 from https://github.com/deskflow/homebrew-tap (Casks/d/deskflow.rb)
  armHash = "sha256-uua+/CwxGd49dRwSAKqzCvPvpUlukdXKECnMOI7qacU=";
  intelHash = "sha256-tgvXjoKbmTfFgS5vwgi3KpI1w6W6g2YB1Q4aW+msSvI=";
in
stdenv.mkDerivation rec {
  pname = "deskflow";
  version = "1.26.0";

  src = fetchurl {
    name = "deskflow-${version}-macos-${arch}.dmg";
    url = "https://github.com/deskflow/deskflow/releases/download/v${version}/deskflow-${version}-macos-${arch}.dmg";
    hash = if isArm then armHash else intelHash;
  };

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
