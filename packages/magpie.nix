{
  lib,
  stdenvNoCC,
  sources,
}:

let
  source =
    {
      x86_64-linux = sources.magpie-x86_64-linux;
      aarch64-linux = sources.magpie-aarch64-linux;
      aarch64-darwin = sources.magpie-aarch64-darwin;
    }
    .${stdenvNoCC.hostPlatform.system}
      or (throw "magpie is not packaged for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "magpie";
  inherit (source) version src;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/magpie"
    runHook postInstall
  '';

  meta = {
    description = "Local model gateway and routing service for AI agents";
    homepage = "https://github.com/yetone/magpie";
    license = lib.licenses.mit;
    mainProgram = "magpie";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
