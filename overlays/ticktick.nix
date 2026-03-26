# TickTick overlay with macOS support
#
# Extends nixpkgs ticktick (Linux-only) to also support macOS
# using the official DMG download

final: prev: {
  ticktick =
    if prev.stdenv.hostPlatform.isDarwin then
      let
        pname = "ticktick";
        version = "8.0.30";
        appname = "TickTick";

        src = prev.fetchurl {
          url = "https://download.ticktick.app/download/mac/TickTick_8.0.30_464.dmg";
          hash = "sha256-vVq22iZHKxLWzAurtNYJjFbCZczYT5XSLvWM5weYHf4=";
        };
      in
      prev.stdenv.mkDerivation {
        inherit
          pname
          version
          src
          appname
          ;

        sourceRoot = "${appname}/${appname}.app";
        nativeBuildInputs = [
          prev.makeWrapper
          prev._7zz
        ];

        installPhase = ''
          runHook preInstall
          mkdir -p $out/{Applications/${appname}.app,bin}
          cp -R . $out/Applications/${appname}.app
          makeWrapper $out/Applications/${appname}.app/Contents/MacOS/${appname} $out/bin/${pname}
          runHook postInstall
        '';

        meta = {
          description = "Powerful to-do & task management app with seamless cloud synchronization across all your devices";
          homepage = "https://ticktick.com";
          license = prev.lib.licenses.unfree;
          platforms = prev.lib.platforms.linux ++ prev.lib.platforms.darwin;
          sourceProvenance = with prev.lib.sourceTypes; [ binaryNativeCode ];
        };
      }
    else
      prev.ticktick;
}
