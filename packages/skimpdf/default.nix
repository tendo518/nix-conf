{
  stdenvNoCC,
  lib,
  undmg,
  fetchurl,
}:
stdenvNoCC.mkDerivation rec {
  pname = "Skim";
  version = "1.7.16";

  src = fetchurl {
    name = "Skim-${version}.dmg";
    url = "mirror://sourceforge/project/skim-app/Skim/Skim-${version}/Skim-${version}.dmg";
    hash = "sha256-0VsLuNTFQZ88Y22gj0m5jhX+s+A/d5HNPWbImE++0Io=";
  };

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
