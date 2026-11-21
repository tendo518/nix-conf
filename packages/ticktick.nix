{
  stdenvNoCC,
  lib,
  makeWrapper,
  _7zz,
  sources,
}:

let
  appname = "TickTick";
  source = sources.ticktick;
in
stdenvNoCC.mkDerivation {
  pname = "ticktick";
  inherit (source) version src;

  sourceRoot = "${appname}/${appname}.app";
  nativeBuildInputs = [
    makeWrapper
    _7zz
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{Applications/${appname}.app,bin}
    cp -R . $out/Applications/${appname}.app

    # 7zz exports HFS extended attributes as sibling "name:com.apple.*" files,
    # which are not part of the bundle Appest signed.
    find $out/Applications/${appname}.app -name '*:com.apple.*' -delete

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
