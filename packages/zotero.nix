{
  stdenvNoCC,
  lib,
  undmg,
  sources,
}:

let
  source = sources.zotero;
in
stdenvNoCC.mkDerivation {
  pname = "zotero";
  inherit (source) version src;

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R "Zotero.app" $out/Applications
    runHook postInstall
  '';

  meta = {
    description = "Open-source reference management software";
    homepage = "https://www.zotero.org/";
    license = lib.licenses.agpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.darwin;
    mainProgram = "Zotero.app";
  };
}
