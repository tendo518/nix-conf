# Custom overlays for the flake
{ inputs, ... }:
{
  flake.overlays = {
    # TickTick overlay with macOS support (Pin version)
    ticktick = final: prev: {
      ticktick =
        if prev.stdenv.hostPlatform.isDarwin then
          final.callPackage ../../packages/ticktick { }
        else
          prev.ticktick;
    };

    # Skim PDF overlay with macOS support (Pin version)
    skimpdf = final: prev: {
      skimpdf =
        if prev.stdenv.hostPlatform.isDarwin then
          final.callPackage ../../packages/skimpdf { }
        else
          prev.skimpdf;
    };

    # Deskflow overlay with macOS support (Pin version)
    deskflow = final: prev: {
      deskflow =
        if prev.stdenv.hostPlatform.isDarwin then
          final.callPackage ../../packages/deskflow { }
        else
          prev.deskflow;
    };

    # Codex desktop overlay: official artifact on macOS; llm-agents' Linux-only
    # chatgpt package on Linux
    codex-desktop = final: prev: {
      codex-desktop =
        if prev.stdenv.hostPlatform.isDarwin then
          final.callPackage ../../packages/codex-desktop { }
        else if prev.stdenv.hostPlatform.isLinux then
          final.llm-agents.chatgpt
        else
          prev.codex-desktop or null;
    };

    # Clash Verge Rev overlay with macOS support (Pin version)
    clash-verge-rev =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin then
        { clash-verge-rev = final.callPackage ../../packages/clash-verge-rev { }; }
      else
        {
          # mihomo 1.19.27 is incompatible with clash-verge-rev 2.5.1 (nixpkgs#535128).
          # TODO: remove once a clash-verge-rev release with the fix lands in nixpkgs.
          mihomo_1_19_26 = prev.mihomo.overrideAttrs (old: rec {
            version = "1.19.26";
            src = final.fetchFromGitHub {
              owner = "MetaCubeX";
              repo = "mihomo";
              rev = "v${version}";
              hash = "sha256-As0MqIGHs1Gn+aUWpeFsC231n9v7lBNmGlQdAwVWcJs=";
            };
            vendorHash = "sha256-ySpBMR/djPPs1aTw7yiCrCFxDFsvRfTJEChg8v1C408=";
          });
          clash-verge-rev = prev.clash-verge-rev.override { mihomo = final.mihomo_1_19_26; };
        };

    # LLM agents overlay (claude-code, opencode, gemini-cli, etc.)
    # https://github.com/numtide/llm-agents.nix
    llm-agents = final: _prev: {
      llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};
    };

    # pr-tracker: nixpkgs#543825 target=nixos-unstable package=vscode
    # vscode 1.129 restored app.asar on Darwin, moving native node_modules back
    # into node_modules.asar.unpacked. generic.nix still resolves nodeModulesPath
    # to Contents/Resources/app/node_modules, so the `chmod +x ${vscodeRipgrep}`
    # in postPatch targets a path that no longer exists and the build fails.
    # Rewrite the interpolated path until the PR lands in the channel.
    vscode = final: prev: {
      vscode = prev.vscode.overrideAttrs (
        old:
        final.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
          postPatch =
            final.lib.replaceStrings
              [ "Contents/Resources/app/node_modules/@vscode/ripgrep-universal" ]
              [ "Contents/Resources/app/node_modules.asar.unpacked/@vscode/ripgrep-universal" ]
              (old.postPatch or "");
        }
      );
    };

    # pr-tracker: nixpkgs#548462 target=nixos-unstable package=obsidian
    # obsidian 1.13.4 moved Obsidian.app into an "Obsidian 1.13.4-universal/"
    # directory inside the DMG, so the hardcoded sourceRoot="Obsidian.app"
    # fails in unpackPhase. Drop sourceRoot and copy the app out during
    # installPhase instead, matching the upstream PR.
    obsidian = final: prev: {
      obsidian = prev.obsidian.overrideAttrs (
        old:
        final.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
          sourceRoot = null;
          installPhase = ''
            runHook preInstall
            mkdir -p $out/{Applications,bin}
            cp -R ${old.appname}.app $out/Applications
            makeWrapper $out/Applications/${old.appname}.app/Contents/MacOS/${old.appname} $out/bin/obsidian
            makeWrapper $out/Applications/${old.appname}.app/Contents/MacOS/obsidian-cli $out/bin/obsidian-cli
            runHook postInstall
          '';
        }
      );
    };

    # pr-tracker: nixpkgs#552075 target=nixos-unstable package=nanoemoji
    # nanoemoji 0.16.0's v0.16.0 tag was force-pushed after nixpkgs pinned its
    # src hash, so the fixed-output fetch fails with a hash mismatch. Mirror
    # nixpkgs#552075 (gM53wlQ... -> FysyKC0...) until it reaches the channel.
    nanoemoji =
      final: prev:
      let
        fixHash = _pself: pprev: {
          nanoemoji = pprev.nanoemoji.overrideAttrs (old: {
            src = final.fetchFromGitHub {
              owner = "googlefonts";
              repo = "nanoemoji";
              tag = "v${old.version}";
              hash = "sha256-FysyKC01XBnRiur5RR9fcsTxQqE8x0JJHSoe3q6JtKc=";
            };
          });
        };
      in
      {
        # jetbrains-mono pins its font build to python313Packages, so that set is
        # the one that actually needs the hash fix; cover python3Packages too in
        # case the pin moves back.
        python313Packages = prev.python313Packages.overrideScope fixHash;
        python3Packages = prev.python3Packages.overrideScope fixHash;
      };

    # pr-tracker: nixpkgs#552212 target=nixos-unstable package=moonlight-qt
    # moonlight-qt 6.1.0 uses AVVulkanDeviceContext::queue_family_decode_index /
    # nb_decode_queues, which ffmpeg 9 removed, so it no longer compiles against
    # the default ffmpeg. Pin to ffmpeg_8 (which still has the fields), matching
    # nixpkgs#552212 until it reaches the channel.
    moonlight-qt = final: prev: {
      moonlight-qt = prev.moonlight-qt.override { ffmpeg = final.ffmpeg_8; };
    };

  };
}
