{
  stdenvNoCC,
  lib,
  _7zz,
  sources,
}:

let
  isArm = stdenvNoCC.hostPlatform.isAarch64;
  source = if isArm then sources."tencent-meeting-arm64" else sources."tencent-meeting-amd64";
in
stdenvNoCC.mkDerivation rec {
  pname = "tencent-meeting";
  inherit (source) version src;

  # Extract with 7zz like the nixpkgs wechat package: undmg (libdmg) silently
  # drops files from this DMG, and hdiutil+ditto copies get flagged as damaged
  # by macOS at launch. stdenvNoCC keeps Tencent's original signature intact.
  nativeBuildInputs = [ _7zz ];

  unpackCmd = ''
    7zz x -snld "$curSrc"
  '';

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -a TencentMeeting_*/TencentMeeting.app $out/Applications/
    runHook postInstall
  '';

  meta = {
    description = "Cloud video conferencing (腾讯会议)";
    homepage = "https://meeting.tencent.com/";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.darwin;
    mainProgram = "TencentMeeting.app";
  };
}
