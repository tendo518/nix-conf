{
  stdenv,
  lib,
  undmg,
  fetchurl,
}:

let
  isArm = stdenv.hostPlatform.isAarch64;
  arch = if isArm then "aarch64" else "x64";
  # sha256 from https://github.com/Homebrew/homebrew-cask (Casks/c/clash-verge-rev.rb)
  armHash = "sha256-lNKUBZgLXR00Gd0d5IXbOiNNNc7wWPedzOWV4Btpchk=";
  intelHash = "sha256-yfzsJ9PktP/+MfMUNpqqQBfYDBKTyLHLZdhd4iPpy2w=";
in
stdenv.mkDerivation rec {
  pname = "clash-verge-rev";
  version = "2.5.2";

  src = fetchurl {
    name = "Clash.Verge-${version}-${arch}.dmg";
    url = "https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v${version}/Clash.Verge_${version}_${arch}.dmg";
    hash = if isArm then armHash else intelHash;
  };

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R "Clash Verge.app" $out/Applications
    runHook postInstall
  '';

  meta = {
    description = "Continuation of Clash Verge - A Clash Meta GUI based on Tauri";
    homepage = "https://clash-verge-rev.github.io/";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.darwin;
    mainProgram = "Clash Verge.app";
  };
}
