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
    rev = "7a3ef63d54dd3c82f828fe5fb108f9aa40131e12";
    hash = "sha256-4Im7C9usMPc57XuE8nKHP2vNAEBoidvqpfiatS7VBZ8=";
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
