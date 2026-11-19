{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
}:
stdenvNoCC.mkDerivation rec {
  pname = "gwfox";
  version = "unstable-2026-11-18";

  src = fetchFromGitHub {
    owner = "akkva";
    repo = "gwfox";
    rev = "208c243f6282298aa947dd823acb474894a271d5";
    hash = "sha256-HRrgvb0MjSexIXnNkDNn4+p+SoTG28eBQxUgT/Y5sl8=";
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
