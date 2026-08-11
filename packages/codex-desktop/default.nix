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
  armHash = "sha256-NMfmKWeK1dY6Y57GlKW4O4X04b18Ie4qvP77sEEJW5w=";
  intelHash = "sha256-ydWhSAPDE4p3vl6JGklEwE/0IWRRUAQ90+3dC/NO2pc=";
in
stdenv.mkDerivation rec {
  pname = "codex-desktop";
  version = "26.803.81509";

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
