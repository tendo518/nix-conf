{ inputs, ... }:
{
  flake.overlays = {
    # Custom iosevka font overlay
    iosevka-lnxw = final: _prev: {
      iosevka-lnxw = final.callPackage ./iosevka-lnxw { };
    };

    # goldendict-ng overlay with Darwin support
    goldendict-ng = import ./goldendict-ng.nix;

    # TickTick overlay with macOS support
    ticktick = import ./ticktick.nix;
  };
}
