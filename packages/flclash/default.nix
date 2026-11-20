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
  armHash = "sha256-2weE5+Wmn8k9qFrM9NjYCBLn4BTyCCYJ2jlbphJBlcU=";
  intelHash = "sha256-SB90IRJXKmSIpexA3dBxKD3FnrTZHaHjmb4lrK956Os=";
in
stdenvNoCC.mkDerivation rec {
  pname = "flclash";
  version = "0.9.4";

  src = fetchurl {
    name = "FlClash-dev-${version}-macos-${arch}.dmg";
    url = "https://github.com/chen08209/FlClash/releases/download/v${version}/FlClash-dev-${version}-macos-${arch}.dmg";
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
