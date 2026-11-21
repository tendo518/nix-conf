{
  stdenvNoCC,
  lib,
  _7zz,
  sources,
}:

let
  source = sources.coteditor;
in
stdenvNoCC.mkDerivation {
  pname = "coteditor";
  inherit (source) version src;

  # CotEditor's DMG uses APFS; undmg only supports HFS.
  nativeBuildInputs = [ _7zz ];

  unpackCmd = ''
    7zz x -snld "$curSrc"
  '';

  sourceRoot = ".";

  # Keep the app bundle byte-identical so its Developer ID signature stays valid.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications $out/bin
    cp -R "CotEditor.app" $out/Applications

    # 7zz exports HFS/APFS extended attributes as sibling "name:com.apple.*"
    # files; they are not part of the signed bundle.
    find $out/Applications/CotEditor.app -name '*:com.apple.*' -delete

    # Match the Homebrew cask's `binary` artifact.
    ln -s $out/Applications/CotEditor.app/Contents/SharedSupport/bin/cot $out/bin/cot
    runHook postInstall
  '';

  meta = {
    description = "Plain-text editor for web pages, program source codes and more";
    homepage = "https://coteditor.com/";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.darwin;
    mainProgram = "cot";
  };
}
