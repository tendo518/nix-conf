# Custom overlays for the flake
{ inputs, ... }:
let
  # PR: https://github.com/NixOS/nixpkgs/pull/506537
  # claude-code: 2.1.81 -> 2.1.92
  claude-code-overlay = final: prev: {
    claude-code = final.callPackage ../../packages/claude-code/source.nix { };
    claude-code-bin = final.callPackage ../../packages/claude-code/bin.nix { };
  };

  goldendict-ng-overlay = final: prev: {
    goldendict-ng = prev.goldendict-ng.overrideAttrs (oldAttrs: {
      # Override platform support to include Darwin
      meta = oldAttrs.meta // {
        platforms = prev.lib.platforms.linux ++ prev.lib.platforms.darwin;
      };

      # Filter out Linux-only dependencies (qtwayland, libxtst)
      buildInputs = builtins.filter (
        dep:
        let
          pname = dep.pname or "";
        in
        pname != "qtwayland" && pname != "libxtst"
      ) (oldAttrs.buildInputs or [ ]);

      # Add ICU libraries for macOS deployment
      propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or [ ]) ++ [ prev.icu ];

      # Fix macOS libc++ strict mode and brew paths
      postPatch = oldAttrs.postPatch or "" + ''
              # Fix missing <sstream> include for std::stringstream on macOS libc++
              sed -i '1i #include <sstream>' src/metadata.cc

              # Completely replace Deps_macOS.cmake to remove brew dependencies
              cat > cmake/Deps_macOS.cmake << 'EOF'
        target_include_directories(''${GOLDENDICT} PRIVATE $ENV{NIX_STORE}/include)

        find_library(CARBON_LIBRARY Carbon REQUIRED)
        target_link_libraries(''${GOLDENDICT} PRIVATE ''${CARBON_LIBRARY})

        find_package(PkgConfig REQUIRED)

        set(Optional_Pkgs "")
        if (USE_SYSTEM_TOML)
            list(APPEND Optional_Pkgs "tomlplusplus")
        endif ()
        if (WITH_ZIM)
            list(APPEND Optional_Pkgs "libzim")
        endif ()
        if (WITH_FFMPEG_PLAYER)
            list(APPEND Optional_Pkgs "libavcodec;libavformat;libavutil;libswresample")
            list(APPEND Optional_Pkgs "libsharpyuv;libwebp;libjxl_cms")
        endif ()

        # Use ICU from nix instead of brew
        if (WITH_ZIM)
            set(BREW_ICU_ADDITIONAL_DYLIBS "")
        endif ()

        pkg_check_modules(DEPS REQUIRED IMPORTED_TARGET
                hunspell
                liblzma
                lzo2
                opencc
                vorbis
                vorbisfile
                xapian-core
                zlib
                ''${Optional_Pkgs}
        )

        find_package(Iconv REQUIRED)
        find_package(BZip2 REQUIRED)
        find_package(fmt REQUIRED)
        target_link_libraries(''${GOLDENDICT} PRIVATE PkgConfig::DEPS BZip2::BZip2 Iconv::Iconv fmt::fmt)

        if (WITH_EPWING_SUPPORT)
            find_library(EB_LIBRARY eb REQUIRED)
            target_link_libraries(''${GOLDENDICT} PRIVATE ''${EB_LIBRARY})
        endif ()
        EOF

              # Fix opencc data path for Nix
              substituteInPlace cmake/Package_macOS.cmake \
                --replace-fail '"/opt/homebrew/share/opencc/"' "\"${prev.opencc}/share/opencc/\"" \
                --replace-fail '"/usr/local/share/opencc/"' "\"${prev.opencc}/share/opencc/\""
      '';
    });
  };

  ticktick-overlay = final: prev: {
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
  };
in
{
  flake.overlays = {
    # claude-code update (PR #506537)
    claude-code = claude-code-overlay;

    # Custom font overlay
    retedo-mono = final: _prev: {
      retedo-mono = final.callPackage ../../packages/retedo-mono { };
    };

    # goldendict-ng overlay with Darwin support
    goldendict-ng = goldendict-ng-overlay;

    # TickTick overlay with macOS support
    ticktick = ticktick-overlay;
  };
}