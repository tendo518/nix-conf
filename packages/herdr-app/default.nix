{
  lib,
  stdenvNoCC,
  fetchurl,
  herdr-app,
  herdr-core,
}:

let
  icon = fetchurl {
    url = "https://raw.githubusercontent.com/herdrdev/herdr-app/v${herdr-app.version}/assets/icons/Herdr.icns";
    hash = "sha256-10K2d22Gy4ZzoEQUkp8HzbJZnRgQL06aLnIidlbUhfU=";
  };
in

# llm-agents installs the raw herdr-app binary. macOS needs a real app bundle
# for Finder/Spotlight and for LSEnvironment PATH setup, so turn the already
# built binary into Herdr.app without rebuilding the Rust application.
stdenvNoCC.mkDerivation {
  pname = "herdr-app";
  version = herdr-app.version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
        runHook preInstall

        app="$out/Applications/Herdr.app"
        mkdir -p "$out/bin" "$app/Contents/MacOS" "$app/Contents/Resources"

        # bin/herdr-app is makeWrapper's script; .herdr-app-wrapped is the
        # Mach-O binary. Keep the former for CLI use and put the latter in the
        # bundle with the core added through LSEnvironment.
        install -m755 "${herdr-app}/bin/herdr-app" "$out/bin/herdr-app"
        install -m755 "${herdr-app}/bin/.herdr-app-wrapped" "$app/Contents/MacOS/Herdr"

        install -m644 "${icon}" "$app/Contents/Resources/Herdr.icns"

        cat > "$app/Contents/Info.plist" <<PLIST
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0"><dict>
        <key>CFBundleExecutable</key><string>Herdr</string>
        <key>CFBundleIdentifier</key><string>dev.herdr.app</string>
        <key>CFBundleName</key><string>Herdr</string>
        <key>CFBundleDisplayName</key><string>Herdr</string>
        <key>CFBundleIconFile</key><string>Herdr</string>
        <key>CFBundlePackageType</key><string>APPL</string>
        <key>CFBundleShortVersionString</key><string>${herdr-app.version}</string>
        <key>CFBundleVersion</key><string>${herdr-app.version}</string>
        <key>NSPrincipalClass</key><string>NSApplication</string>
        <key>NSHighResolutionCapable</key><true/>
        <key>LSEnvironment</key><dict>
          <key>PATH</key>
          <string>${herdr-core}/bin:/run/current-system/sw/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        </dict>
    </dict></plist>
    PLIST

        # Nix's Mach-O fixup signs the executable itself; sign the surrounding
        # app bundle too so LaunchServices sees a valid ad-hoc application.
        /usr/bin/codesign --force --deep --sign - "$app"

        runHook postInstall
  '';

  meta = {
    description = "Herdr desktop app for terminals and coding agents";
    homepage = "https://github.com/herdrdev/herdr-app";
    license = lib.licenses.asl20;
    platforms = lib.platforms.darwin;
    mainProgram = "herdr-app";
  };
}
