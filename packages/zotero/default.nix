{
  stdenv,
  lib,
  undmg,
  fetchurl,
}:
stdenv.mkDerivation rec {
  pname = "zotero";
  version = "10.0.2";

  # Universal build: single DMG for both Apple Silicon and Intel.
  # version + sha256 from https://github.com/Homebrew/homebrew-cask (Casks/z/zotero.rb)
  src = fetchurl {
    name = "Zotero-${version}.dmg";
    url = "https://download.zotero.org/client/release/${version}/Zotero-${version}.dmg";
    hash = "sha256-mcLz0HMJDMfvKkNgnDpnjqvewTLvjIxEesq5/LIEza4=";
  };

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
