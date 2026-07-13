# Custom overlays for the flake
{ inputs, ... }:
{
  flake.overlays = {
    # Custom font overlay
    retedo-mono = final: _prev: {
      retedo-mono = final.callPackage ../../packages/retedo-mono { };
    };

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

    # Clash Verge Rev overlay with macOS support (Pin version)
    clash-verge-rev = final: prev:
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
    # Upstream removed its `overlays` output, so expose packages directly.
    llm-agents = final: _prev: {
      llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};
    };

    # moonlight-qt: link with LLVM lld on Darwin to work around the classic
    # ld64 crash (SIGTRAP in the stubs pass when linking Obj-C). Same fix as
    # nixpkgs#540463 (starship). TODO: remove once #536365 reaches nixos-unstable.
    moonlight-qt = final: prev: {
      moonlight-qt = prev.moonlight-qt.overrideAttrs (old:
        final.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.llvmPackages.lld ];
          NIX_CFLAGS_LINK = "-fuse-ld=lld";
        }
      );
    };

    # stats: same ld64 crash (Swift/Obj-C link). stats uses __structuredAttrs,
    # so the flag must go through `env` rather than a top-level attribute.
    stats = final: prev: {
      stats = prev.stats.overrideAttrs (old:
        final.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.llvmPackages.lld ];
          env = (old.env or { }) // { NIX_CFLAGS_LINK = "-fuse-ld=lld"; };
        }
      );
    };

  };
}
