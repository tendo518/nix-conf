{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
}:
stdenvNoCC.mkDerivation rec {
  pname = "gwfox-t";
  version = "unstable-2026-11-18";

  src = fetchFromGitHub {
    owner = "akkva";
    repo = "GWfox-T";
    rev = "010266fac2c14c7de5800a81852c569a00c23b35";
    hash = "sha256-APUM+SYChQLrfIFr/tWc+JX90q3/1xyYAxd7uvHu/1A=";
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
