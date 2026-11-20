{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
}:
stdenvNoCC.mkDerivation rec {
  pname = "gwfox";
  version = "unstable-2026-11-19";

  src = fetchFromGitHub {
    owner = "akkva";
    repo = "gwfox";
    rev = "034bf8a9c27765499ec43a3467dba0c6a82f4731";
    hash = "sha256-5GVW2zw5IzzuV9cFWwojvcBPnwJLWd5INpzRrNGI0ME=";
  };

  installPhase = ''
    runHook preInstall
    install -Dm644 userChrome.css $out/share/gwfox/userChrome.css
    install -Dm644 userContent.css $out/share/gwfox/userContent.css
    install -Dm644 LICENSE $out/share/gwfox/LICENSE
    runHook postInstall
  '';

  meta = {
    description = "Firefox userChrome theme";
    homepage = "https://github.com/akkva/gwfox";
    license = lib.licenses.mpl20;
    platforms = lib.platforms.all;
  };
}
