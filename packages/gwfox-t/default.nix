{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
}:
stdenvNoCC.mkDerivation rec {
  pname = "gwfox-t";
  version = "unstable-2026-11-06";

  src = fetchFromGitHub {
    owner = "akkva";
    repo = "GWfox-T";
    rev = "c3da624118e219df75f16ffcb029ed9a890dadf4";
    hash = "sha256-FnxaeijQt9O8AareEqZhBcOg14CWzRBPbk/6poQa214=";
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
