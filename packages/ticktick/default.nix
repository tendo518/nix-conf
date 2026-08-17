{
  stdenv,
  lib,
  fetchurl,
  makeWrapper,
  _7zz,
}:

let
  appname = "TickTick";
in
stdenv.mkDerivation {
  pname = "ticktick";
  version = "8.0.80";

  src = fetchurl {
    url = "https://download.ticktick.app/download/mac/TickTick_8.0.80_496.dmg";
    hash = "sha256-KBDbu4o+nwD9b4Iac9RtqYnrKsGlEygQS4DlRF2KMro=";
  };

  sourceRoot = "${appname}/${appname}.app";
  nativeBuildInputs = [
    makeWrapper
    _7zz
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{Applications/${appname}.app,bin}
    cp -R . $out/Applications/${appname}.app
    makeWrapper $out/Applications/${appname}.app/Contents/MacOS/${appname} $out/bin/ticktick
    runHook postInstall
  '';

  meta = {
    description = "Powerful to-do & task management app with seamless cloud synchronization across all your devices";
    homepage = "https://ticktick.com";
    license = lib.licenses.unfree;
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
