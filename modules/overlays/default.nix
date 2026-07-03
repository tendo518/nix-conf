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
    llm-agents = inputs.llm-agents.overlays.default;

  };
}
