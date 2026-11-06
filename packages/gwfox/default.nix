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
    rev = "d88ab34cc44189da5e652c701859cf671183ad5a";
    hash = "sha256-TLol6h78ma7dqi93iZ7yaMVmKbbxulBBNARIMT3aqZg=";
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
