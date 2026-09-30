{
  stdenvNoCC,
  lib,
  fetchurl,
  unzip,
}:

# DeepSeek Harness (dsh) desktop client. Upstream ships an Apple Silicon build
# only, and the download page hands out an unversioned "latest" DMG
# (dsh-latest-macos-arm64.dmg). The versioned .zip below is the same app from
# the same CDN; version + sha256 are tracked via the Homebrew cask
# (https://github.com/Homebrew/homebrew-cask, Casks/d/deepseek-harness.rb).
stdenvNoCC.mkDerivation rec {
  pname = "deepseek-harness";
  version = "0.2.0-rc.2";

  src = fetchurl {
    name = "deepseek-harness-${version}-mac-arm64.zip";
    url = "https://download.deepseek.com/dsh-desk/bin/mac-arm64/deepseek-harness-${version}-mac-arm64.zip";
    hash = "sha256-uD2vI+SC2WxMA5oqeG2vOnCC6GfqStk8UUaAIN76iio=";
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  # Keep the bundle byte-identical to upstream: nixpkgs' fixup rewrites
  # shebangs of the bundled runtime scripts (python/pnpm/dsh), which breaks the
  # Developer ID seal macOS validates at launch.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R "DeepSeek Harness.app" $out/Applications
    runHook postInstall
  '';

  meta = {
    description = "Plugin-based AI agent desktop application (DeepSeek Harness)";
    homepage = "https://www.deepseek.com/harness/";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
    mainProgram = "DeepSeek Harness.app";
  };
}
