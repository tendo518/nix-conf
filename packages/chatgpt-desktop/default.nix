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
  armHash = "sha256-HL82HHIY2I8atK8wuSHmb8jmHIMshO9aXETU8SyGgGs=";
  intelHash = "sha256-L6+eghKSUdgfK4LutFUu7JED7SzoQfHdMOxJTBmAsc8=";
in
stdenv.mkDerivation rec {
  pname = "chatgpt-desktop";
  version = "26.908.40834";

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
