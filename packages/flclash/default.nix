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
  armHash = "sha256-IW9xdztwlBr+P20d9vId8FgQ4Qm7gHX0RWCgNJ5m4NI=";
  intelHash = "sha256-5UXFU5xjHAEW6dWKBLP7lc5YcwRhboVIm6FaVOjH63A=";
in
stdenvNoCC.mkDerivation rec {
  pname = "flclash";
  version = "0.9.2";

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
