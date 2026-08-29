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
  version = "3.45.3.405";
  armToken = "f782c3b4179fc3cd383e5f6fe9eae994";
  armHash = "sha256-9lCy8gepz9Z2TcPKJkiP6hE/XL6qP/kv7ktZentfivo=";
  intelToken = "3df5ddc2131065ad2a110498f69b3b21";
  intelHash = "sha256-yyzeIxyt0ZqCFgzM1586H/LFUgS9OpEMqhCo/LO0EZk=";
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
