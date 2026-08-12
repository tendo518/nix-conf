{
  stdenv,
  lib,
  alsa-lib,
  at-spi2-atk,
  autoPatchelfHook,
  cairo,
  cups,
  dbus,
  dpkg,
  expat,
  fetchurl,
  gcc,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libnotify,
  libusb1,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
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
  # The latest artifact currently reports version 26.803.81509.
  amd64Hash = "sha256-qb+Ro2j598Tuo4CCqfuPtGuNAFtxmm13FdLloZgsOOs=";
  arm64Hash = "sha256-84/MGU7KmrAyfcEMkjQGgernfF11Fk33ADhM4q2sy8E=";
in
stdenv.mkDerivation rec {
  pname = "chatgpt";
  version = "26.803.81509";

  src = fetchurl {
    name = "chatgpt_${arch}.deb";
    url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_${arch}.deb";
    hash = if isArm then arm64Hash else amd64Hash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    cairo
    cups
    dbus
    expat
    gcc
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libnotify
    libusb1
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    openssl
    pango
    xdg-utils
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
    runHook postInstall
  '';

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
