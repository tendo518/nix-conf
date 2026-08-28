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
  armHash = "sha256-QkAvV+v8En8wegTI7MzCXbH59Yheh+Kh3G6+50gcN7c=";
  intelHash = "sha256-8LNfgN2/5Ab5Sj1WBg/p7bem1PfeX9k/Nh+bGTWk/eM=";
in
stdenv.mkDerivation rec {
  pname = "chatgpt-desktop";
  version = "26.820.80927";

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
