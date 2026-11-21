{
  stdenvNoCC,
  lib,
  unzip,
  sources,
}:

let
  source = sources."deepseek-harness";
in
stdenvNoCC.mkDerivation {
  pname = "deepseek-harness";
  inherit (source) version src;

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
