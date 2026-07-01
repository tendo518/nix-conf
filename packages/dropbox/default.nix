{
  stdenv,
  lib,
  undmg,
  fetchurl,
}:

let
  isArm = stdenv.hostPlatform.isAarch64;
  archSuffix = if isArm then ".arm64" else "";
  # sha256 from https://github.com/Homebrew/homebrew-cask (Casks/d/dropbox.rb)
  armHash = "sha256-6pbBLAoKfqNwcOWmnZLUFZRbxJC+r0PzSOMzhO/G8Os=";
  intelHash = "sha256-Fch7GG7NBFwy5AksNT4btWn+7lp8mnBdUgjg/um7DXo=";
in
stdenv.mkDerivation rec {
  pname = "dropbox";
  version = "258.4.3749";

  src = fetchurl {
    name = "Dropbox-${version}${archSuffix}.dmg";
    url = "https://edge.dropboxstatic.com/dbx-releng/client/Dropbox%20${version}${archSuffix}.dmg";
    hash = if isArm then armHash else intelHash;
  };

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R Dropbox.app $out/Applications
    runHook postInstall
  '';

  meta = {
    description = "Client for the Dropbox cloud storage service";
    homepage = "https://www.dropbox.com";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.darwin;
    mainProgram = "Dropbox.app";
  };
}
