{
  stdenvNoCC,
  lib,
  sources,
}:

let
  mkTheme =
    {
      pname,
      source,
      description,
      homepage,
    }:
    stdenvNoCC.mkDerivation {
      inherit pname;
      version = "unstable-${source.date}";
      src = source.src;

      installPhase = ''
        runHook preInstall
        install -Dm644 userChrome.css $out/share/${pname}/userChrome.css
        install -Dm644 userContent.css $out/share/${pname}/userContent.css
        install -Dm644 LICENSE $out/share/${pname}/LICENSE
        runHook postInstall
      '';

      meta = {
        inherit description homepage;
        license = lib.licenses.mpl20;
        platforms = lib.platforms.all;
      };
    };
in
{
  gwfox = mkTheme {
    pname = "gwfox";
    source = sources.gwfox;
    description = "Firefox userChrome theme";
    homepage = "https://github.com/akkva/gwfox";
  };

  gwfox-t = mkTheme {
    pname = "gwfox-t";
    source = sources.gwfox-t;
    description = "macOS 27 Golden Gate style Firefox theme";
    homepage = "https://github.com/akkva/GWfox-T";
  };
}
