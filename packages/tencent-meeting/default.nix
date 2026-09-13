{
  stdenvNoCC,
  lib,
  fetchurl,
  _7zz,
}:

let
  isArm = stdenvNoCC.hostPlatform.isAarch64;
  arch = if isArm then "arm64" else "x86_64";
  # build tokens + sha256 from https://formulae.brew.sh/cask/tencent-meeting
  version = "3.46.0.442";
  armToken = "d33a84b584a220bd4772f72ca40653d9";
  armHash = "sha256-Bf8BJY3ie5QAJs5to5dBSP9iyIIHo0RFgGIh+ztndRU=";
  intelToken = "bf7b0890f1478972fb7361260f7ff2bc";
  intelHash = "sha256-LbSshJbxwOQ8HaWgebPLT/WUfeYvaRwwesaArXnhdu0=";
  token = if isArm then armToken else intelToken;
in
stdenvNoCC.mkDerivation rec {
  pname = "tencent-meeting";
  inherit version;

  src = fetchurl {
    name = "TencentMeeting_${version}_${arch}.dmg";
    url = "https://updatecdn.meeting.qq.com/cos/${token}/TencentMeeting_0300000000_${version}.publish.${arch}.officialwebsite.dmg";
    hash = if isArm then armHash else intelHash;
  };

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
