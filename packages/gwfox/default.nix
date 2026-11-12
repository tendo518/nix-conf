{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
}:
stdenvNoCC.mkDerivation rec {
  pname = "gwfox";
  version = "unstable-2026-11-12";

  src = fetchFromGitHub {
    owner = "akkva";
    repo = "gwfox";
    rev = "62c36553c5aa7269674947d59a25b92da10fdc0f";
    hash = "sha256-O8Htonzua6do+P4UFZMa7FEI9bY8lHsbKzVf8hZOuHg=";
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
