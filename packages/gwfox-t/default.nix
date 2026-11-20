{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
}:
stdenvNoCC.mkDerivation rec {
  pname = "gwfox-t";
  version = "unstable-2026-11-19";

  src = fetchFromGitHub {
    owner = "akkva";
    repo = "GWfox-T";
    rev = "d8600bc2d69b44074e02381aa6dd27938f0ec850";
    hash = "sha256-Ag5spEaIeikTLLucE1If1fVufXeR9PGb2H5tjcXLqTo=";
  };

  installPhase = ''
    runHook preInstall
    install -Dm644 userChrome.css $out/share/gwfox-t/userChrome.css
    install -Dm644 userContent.css $out/share/gwfox-t/userContent.css
    install -Dm644 LICENSE $out/share/gwfox-t/LICENSE
    runHook postInstall
  '';

  meta = {
    description = "macOS 27 Golden Gate style Firefox theme";
    homepage = "https://github.com/akkva/GWfox-T";
    license = lib.licenses.mpl20;
    platforms = lib.platforms.all;
  };
}
