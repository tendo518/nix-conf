{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
}:
stdenvNoCC.mkDerivation rec {
  pname = "gwfox-t";
  version = "unstable-2026-11-12";

  src = fetchFromGitHub {
    owner = "akkva";
    repo = "GWfox-T";
    rev = "14eac64263633d128433ca3a645d51715a3afab4";
    hash = "sha256-5VN2ln8NE6j9S8nsjuFpkvRAXVbeDzXPUk7uNdcZ1G8=";
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
