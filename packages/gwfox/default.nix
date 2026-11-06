{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
}:
stdenvNoCC.mkDerivation rec {
  pname = "gwfox";
  version = "unstable-2026-11-06";

  src = fetchFromGitHub {
    owner = "akkva";
    repo = "gwfox";
    rev = "b2f2b6e5299cc4898225f975ed82cb9adc591723";
    hash = "sha256-jC7U+0UGBaENczSiJD/nWCdj0V77L5/JqqhT3g+xJZY=";
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
