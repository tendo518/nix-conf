{
  stdenvNoCC,
  lib,
  undmg,
  sources,
}:

let
  source = sources.skimpdf;
in
stdenvNoCC.mkDerivation {
  pname = "Skim";
  inherit (source) version src;

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  # Skim's SharedSupport scripts must stay as shipped: rewriting their shebangs
  # invalidates the bundle's Developer ID signature.
  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R Skim.app $out/Applications
    runHook postInstall
  '';

  meta = {
    description = "PDF reader and note-taker for macOS";
    homepage = "https://skim-app.sourceforge.io/";
    license = lib.licenses.bsd0;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "Skim.app";
    maintainers = with lib.maintainers; [ YvesStraten ];
    platforms = lib.platforms.darwin;
  };
}
