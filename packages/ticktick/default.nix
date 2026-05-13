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
  version = "8.0.60";

  src = fetchurl {
    url = "https://download.ticktick.app/download/mac/TickTick_8.0.60_468.dmg";
    hash = "sha256-hamKP4FVsPNFX0+Zt0doo/72auryRkWCqAApVgpNLhg=";
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
