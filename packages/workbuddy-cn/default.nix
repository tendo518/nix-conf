{
  stdenvNoCC,
  lib,
  fetchurl,
  _7zz,
}:

# WorkBuddy (腾讯 WorkBuddy) ships only as a macOS DMG from Tencent's CDN and
# currently only for Apple Silicon. The release metadata behind the version and
# URL below comes from https://www.codebuddy.cn/v2/update?platform=workbuddy-darwin-arm64
stdenvNoCC.mkDerivation rec {
  pname = "workbuddy-cn";
  version = "5.5.6.38337834";

  src = fetchurl {
    url = "https://download.codebuddy.cn/workbuddy/saas/darwin-arm64/WorkBuddy-darwin-arm64-5.5.6.38337834-5f969292.dmg";
    hash = "sha256-9UtwHaUcB56rUJf1i4386d84tD8qwdCNClHvukgfYFk=";
  };

  # Extract with 7zz like the nixpkgs wechat package: undmg silently drops
  # files from Tencent's DMGs.
  nativeBuildInputs = [ _7zz ];

  unpackCmd = ''
    7zz x -snld "$curSrc"
  '';

  sourceRoot = ".";

  # Leave the extracted bundle alone: its own scripts must keep their shebangs.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -a WorkBuddy*/WorkBuddy.app $out/Applications/

    app=$out/Applications/WorkBuddy.app

    # 7zz exports HFS extended attributes as sibling "name:com.apple.*" files,
    # which are not part of the bundle Tencent signed.
    find "$app" -name '*:com.apple.*' -delete

    # Sign ad-hoc, the same way llm-agents signs the ChatGPT desktop app.
    # With Tencent's Developer ID signature and stapled ticket macOS reports
    # this bundle as damaged and refuses to launch it; an ad-hoc signature has
    # no notarization identity left to validate. The ticket is meaningless for
    # an ad-hoc signature, so drop it.
    rm -f "$app/Contents/CodeResources"
    chmod -R u+w "$app"
    /usr/bin/codesign --force --deep --sign - "$app"
    /usr/bin/codesign --verify --deep --strict "$app"

    runHook postInstall
  '';

  meta = {
    description = "Tencent WorkBuddy AI agent office assistant (腾讯 WorkBuddy)";
    homepage = "https://www.codebuddy.cn/work/";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
    mainProgram = "WorkBuddy.app";
  };
}
