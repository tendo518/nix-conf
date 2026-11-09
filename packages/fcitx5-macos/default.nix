{
  stdenvNoCC,
  lib,
  fetchurl,
  bzip2,
}:

# Upstream publishes the macOS host and its input engines separately. We bundle
# the Rime plugin into Fcitx5.app so the installed app is self-contained and no
# files need to be managed in ~/Library/fcitx5.
#
# The app deliberately keeps its absolute /Library/Input Methods rpath. It must
# be installed at that system path to run; keeping it only in the Nix store is
# not enough for macOS to load it as an input method.
let
  version = "0.4.2";

  rimeNative = fetchurl {
    name = "rime-arm64.tar.bz2";
    url = "https://github.com/fcitx-contrib/fcitx5-plugins/releases/download/macos-${version}/rime-arm64.tar.bz2";
    hash = "sha256-RG7Baarrkkxgrbm3XTvOcGYCAxc8SNfZKwNYKUBEm7I=";
  };

  rimeData = fetchurl {
    name = "rime-any.tar.bz2";
    url = "https://github.com/fcitx-contrib/fcitx5-plugins/releases/download/macos-${version}/rime-any.tar.bz2";
    hash = "sha256-5ngjF2NNYqkcvtrJ1qsW8czVloJU7wrifuvPwHvgVj4=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "fcitx5-macos";
  inherit version;

  src = fetchurl {
    name = "Fcitx5-arm64.tar.bz2";
    url = "https://github.com/fcitx/fcitx5-macos/releases/download/${version}/Fcitx5-arm64.tar.bz2";
    hash = "sha256-3yFFdYUxlk2CVepDs0CTjqNVVHGSF/8wZVcmMRrqdII=";
  };

  nativeBuildInputs = [ bzip2 ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;
  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall

    mkdir -p source rime-native rime-data
    tar xjf "$src" -C source
    tar xjf ${rimeNative} -C rime-native
    tar xjf ${rimeData} -C rime-data

    app="$out/Applications/Fcitx5.app"
    mkdir -p "$out/Applications"
    cp -R source/Fcitx5.app "$app"

    # Fcitx5 searches Contents/lib/fcitx5 and Contents/share before the
    # per-user plugin directory, so the Rime engine lives entirely in the app.
    cp -a rime-native/lib/fcitx5/librime.so "$app/Contents/lib/fcitx5/"
    cp -a rime-data/share/. "$app/Contents/share/"

    test -f "$app/Contents/lib/fcitx5/librime.so"
    test -f "$app/Contents/share/fcitx5/addon/rime.conf"
    test -f "$app/Contents/share/fcitx5/inputmethod/rime.conf"
    test -d "$app/Contents/share/rime-data"

    # Keep the bundle intact, then sign it as the upstream installer does.
    /usr/bin/codesign --force --deep --sign - "$app"

    runHook postInstall
  '';

  meta = {
    description = "Fcitx5 input method for macOS with the Rime engine bundled";
    homepage = "https://github.com/fcitx/fcitx5-macos";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
    mainProgram = "Fcitx5.app";
  };
}
