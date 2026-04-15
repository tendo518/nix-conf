# Custom overlays for the flake
{ inputs, ... }:
let
  ticktick-overlay = final: prev: {
    ticktick =
      if prev.stdenv.hostPlatform.isDarwin then
        final.callPackage ../../packages/ticktick { }
      else
        prev.ticktick;
  };
in
{
  flake.overlays = {
    # Custom font overlay
    retedo-mono = final: _prev: {
      retedo-mono = final.callPackage ../../packages/retedo-mono { };
    };

    # TickTick overlay with macOS support
    ticktick = ticktick-overlay;
  };
}
