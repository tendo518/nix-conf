{
  stdenv,
  lib,
  unzip,
  fetchurl,
}:

let
  isArm = stdenv.hostPlatform.isAarch64;
  arch = if isArm then "arm64" else "x64";
  # sha256 from https://github.com/Homebrew/homebrew-cask (Casks/c/chatgpt.rb)
  armHash = "sha256-23J+8j5WH70rR/BfsP7Off6Dn9saCB5aF9NKFqWg1sA=";
  intelHash = "sha256-Sl/Y1fXCb+PyiXG913aIf+PQ+2LyJe06l1jpYKEYYf0=";
in
stdenv.mkDerivation rec {
  pname = "chatgpt-desktop";
  version = "26.825.51511";

  src = fetchurl {
    name = "chatgpt-${version}-macos-${arch}.zip";
    url = "https://persistent.oaistatic.com/codex-app-prod/ChatGPT-darwin-${arch}-${version}.zip";
    hash = if isArm then armHash else intelHash;
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R ChatGPT.app $out/Applications
    runHook postInstall
  '';

  meta = {
    description = "ChatGPT desktop app with OpenAI Codex";
    homepage = "https://chatgpt.com/";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.darwin;
    mainProgram = "ChatGPT.app";
  };
}
