{
  stdenvNoCC,
  lib,
  undmg,
  fetchurl,
}:

let
  isArm = stdenvNoCC.hostPlatform.isAarch64;
  arch = if isArm then "arm64" else "amd64";
  # sha256 from https://github.com/chen08209/FlClash/releases
  armHash = "sha256-mA6cw71H0gkIduXjwG93TjKokzDYOqZqw/hJDjmSTZs=";
  intelHash = "sha256-lzjuvsTI3QF767YI8tHowgnPWql8xPGBeDA2tm3TyUQ=";
in
stdenvNoCC.mkDerivation rec {
  pname = "flclash";
  version = "0.9.3";

  src = fetchurl {
    name = "FlClash-${version}-macos-${arch}.dmg";
    url = "https://github.com/chen08209/FlClash/releases/download/v${version}/FlClash-${version}-macos-${arch}.dmg";
    hash = if isArm then armHash else intelHash;
  };

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  # Keep the app bundle byte-identical so its ad-hoc signature stays valid.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R FlClash.app $out/Applications
    runHook postInstall
  '';

  meta = {
    description = "Multi-platform proxy client based on ClashMeta";
    homepage = "https://github.com/chen08209/FlClash";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.darwin;
    mainProgram = "FlClash.app";
  };
}
