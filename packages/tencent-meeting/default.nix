{
  stdenv,
  lib,
  fetchurl,
}:

let
  isArm = stdenv.hostPlatform.isAarch64;
  arch = if isArm then "arm64" else "x86_64";
  # build tokens + sha256 from https://formulae.brew.sh/cask/tencent-meeting
  version = "3.45.2.404";
  armToken = "5bd79d10ed54b140514f895501bd65f7";
  armHash = "sha256-fPZOinqGf4iyD7DK6AGr+QCs26tMcIQL+fpqdFUH+CU=";
  intelToken = "2625f283be0c386e65d173c5f0cee56b";
  intelHash = "sha256-sqRoboknCCD/DQMeuHAi+TaLHKmUzvx1nlEyXEEGCQY=";
  token = if isArm then armToken else intelToken;
in
stdenv.mkDerivation rec {
  pname = "tencent-meeting";
  inherit version;

  src = fetchurl {
    name = "TencentMeeting_${version}_${arch}.dmg";
    url = "https://updatecdn.meeting.qq.com/cos/${token}/TencentMeeting_0300000000_${version}.publish.${arch}.officialwebsite.dmg";
    hash = if isArm then armHash else intelHash;
  };

  # undmg (libdmg) silently drops files from this DMG, leaving a broken,
  # invalidly-signed bundle. Extract with macOS's native hdiutil instead,
  # which produces a byte-perfect copy that keeps its original signature.
  # dontFixup keeps the Tencent code signature intact (the darwin fixup phase
  # would otherwise re-sign all Mach-O binaries ad-hoc, breaking the app).
  dontFixup = true;

  unpackPhase = ''
    runHook preUnpack
    mkdir -p "$TMPDIR/tm-dmg"
    /usr/bin/hdiutil attach "$src" -nobrowse -readonly -mountpoint "$TMPDIR/tm-dmg"
    /usr/bin/ditto "$TMPDIR/tm-dmg/TencentMeeting.app" "$PWD/TencentMeeting.app"
    /usr/bin/hdiutil detach "$TMPDIR/tm-dmg"
    runHook postUnpack
  '';

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    /usr/bin/ditto TencentMeeting.app $out/Applications/TencentMeeting.app
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
