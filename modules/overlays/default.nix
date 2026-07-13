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
    clash-verge-rev = final: prev: {
      clash-verge-rev =
        if prev.stdenv.hostPlatform.isDarwin then
          final.callPackage ../../packages/clash-verge-rev { }
        else
          prev.clash-verge-rev;
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
