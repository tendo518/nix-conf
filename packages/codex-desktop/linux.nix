{
  stdenv,
  lib,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  autoPatchelfHook,
  cairo,
  coreutils,
  cups,
  dbus,
  dpkg,
  expat,
  fetchurl,
  fontconfig,
  freetype,
  gcc,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libGL,
  libnotify,
  libpulseaudio,
  libsecret,
  libusb1,
  makeDesktopItem,
  makeWrapper,
  perl,
  pipewire,
  qt5,
  qt6,
  systemd,
  wayland,
  wrapGAppsHook3,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libxcb,
  nspr,
  nss,
  openssl,
  pango,
  xdg-utils,
}:

let
  isArm = stdenv.hostPlatform.isAarch64;
  arch = if isArm then "arm64" else "amd64";
  # Official OpenAI Linux .deb from persistent.oaistatic.com.
  # The latest artifact currently reports version 26.810.52044.
  amd64Hash = "sha256-cIoVobt24rt/DjduUUU5H6J3rTpkBXwdMlN73CobTm4=";
  arm64Hash = "sha256-br6mgbHklNIYoZn2OLS8iG6U4UWN1hB5seOQpvuY/dI=";
in
stdenv.mkDerivation rec {
  pname = "chatgpt";
  version = "26.810.52044";

  src = fetchurl {
    name = "chatgpt_${arch}.deb";
    # Upstream intentionally exposes only a mutable "latest" URL. Keep the
    # hash pinned for reproducible builds and refresh it with update_linux.sh.
    url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_${arch}.deb";
    hash = if isArm then arm64Hash else amd64Hash;
  };

  dontStrip = true;
  dontWrapGApps = true;

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
    perl
    wrapGAppsHook3
  ];

  # The upstream bundle contains optional Qt shims and musl/Android prebuilds
  # in addition to the glibc binaries used by this package. They are selected
  # at runtime only on systems that provide those alternate runtimes.
  autoPatchelfIgnoreMissingDeps = [
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
    "libc.musl-*.so.1"
    "liblog.so"
    "libc++_shared.so"
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gcc
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libGL
    libnotify
    libpulseaudio
    libsecret
    libusb1
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    libxcb
    nspr
    nss
    openssl
    pango
    pipewire
    systemd
    wayland
    xdg-utils
  ];

  # Electron loads these at runtime rather than linking them directly. Put
  # them on each ELF object's RPATH without leaking a broad LD_LIBRARY_PATH
  # into Electron's Node and Chromium children.
  runtimeDependencies = [
    libGL
    libgbm
    libsecret
    pipewire
    wayland
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -a ./* "$out/"
    mkdir -p "$out/bin"
    ln -s "$out/usr/bin/chatgpt" "$out/bin/chatgpt"

    # @parcel/watcher uses detect-libc in a named worker. Its process.report
    # fallback trips a CFI guard in the bundled Owl/Electron runtime on NixOS.
    # Keep the replacement the same length so the asar offsets remain valid;
    # detect-libc will use its ELF/filesystem/ldd fallbacks instead.
    appAsar="$out/usr/lib/chatgpt/resources/app.asar"
    grep -aFq "isLinux() && process.report" "$appAsar"
    sed -i 's/isLinux() \&\& process\.report/false \/\* nix:skip report \*\//' "$appAsar"
    ! grep -aFq "isLinux() && process.report" "$appAsar"
    grep -aFq "false /* nix:skip report */" "$appAsar"

    # The app materializes bundled plugins in ~/.codex and rewrites selected
    # manifests there. Node's fs.cp preserves the Nix store's read-only modes,
    # so copy with coreutils and make only the user-owned destination writable.
    # Keep the replacement byte-length-preserving so ASAR offsets stay valid.
    original='async function Mne(e,t){if(S.default.platform===`darwin`){await lne(`/usr/bin/ditto`,[`--noqtn`,e,t]);return}if(S.default.platform!==`win32`){await y.default.cp(e,t,{recursive:!0,verbatimSymlinks:!0});return}let{copyDirectoryAllowDecryptedDestinationOnEncryptionFailure:n}=await Promise.resolve().then(()=>require("./windows-file-copy-Bw9CB6bJ.js"));await n({copy:()=>y.default.cp(e,t,{recursive:!0,verbatimSymlinks:!0}),destination:t,source:e})}'
    replacement='async function Mne(e,t){let r=S.default.platform;if(r===`darwin`){await lne(`/usr/bin/ditto`,[`--noqtn`,e,t]);return}if(r!==`win32`){await lne(`cp`,[`-r`,e+`/.`,t]);await lne(`chmod`,[`-R`,`u+w`,t]);return}let{copyDirectoryAllowDecryptedDestinationOnEncryptionFailure:n}=await Promise.resolve().then(()=>require("./windows-file-copy-Bw9CB6bJ.js"));await n({copy:()=>y.default.cp(e,t,{recursive:!0,verbatimSymlinks:!0}),destination:t,source:e})}  '

    if [ "''${#original}" -ne "''${#replacement}" ]; then
      echo "ChatGPT bundled-plugin ASAR patch changed byte length" >&2
      exit 1
    fi

    grep -aFq "$original" "$appAsar"
    export original replacement
    perl -0pi -e 'BEGIN { $from = $ENV{original}; $to = $ENV{replacement} } s/\Q$from\E/$to/' "$appAsar"
    ! grep -aFq "$original" "$appAsar"
    grep -aFq 'await lne(`chmod`,[`-R`,`u+w`,t])' "$appAsar"

    runHook postInstall
  '';

  postFixup = ''
    # The Qt shims are optional and selected dynamically, so autoPatchelf
    # cannot resolve their runtimes. Add version-specific RPATHs manually.
    patchelf --add-rpath ${lib.makeLibraryPath [ qt5.qtbase ]} \
      "$out/usr/lib/chatgpt/libqt5_shim.so"
    patchelf --add-rpath ${lib.makeLibraryPath [ qt6.qtbase ]} \
      "$out/usr/lib/chatgpt/libqt6_shim.so"

    # wrapGAppsHook3 populates gappsWrapperArgs in preFixup, so wrap here
    # (postFixup) to actually apply GSettings/GIO/pixbuf env vars.
    wrapProgram "$out/usr/lib/chatgpt/ChatGPT" \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${lib.makeBinPath [
        coreutils
        xdg-utils
      ]}
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "chatgpt";
      desktopName = "ChatGPT";
      genericName = "AI assistant";
      comment = meta.description;
      exec = "chatgpt %U";
      categories = [ "Office" ];
      type = "Application";
    })
  ];

  passthru.updateScript = ./update_linux.sh;

  meta = {
    description = "ChatGPT desktop app by OpenAI";
    homepage = "https://developers.openai.com/codex/app";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "chatgpt";
  };
}
