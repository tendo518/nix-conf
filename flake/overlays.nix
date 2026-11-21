# Custom overlays for the flake
{ inputs, ... }:
let
  sourcesFor = final: import ../packages/sources.nix { pkgs = final; };
in
{
  flake.overlays = {
    # gwfox Firefox theme (Linux)
    "gwfox" = final: _prev: {
      "gwfox" =
        (final.callPackage ../packages/gwfox.nix { sources = sourcesFor final; }).gwfox;
    };

    # GWfox-T Firefox theme (macOS)
    "gwfox-t" = final: _prev: {
      "gwfox-t" =
        (final.callPackage ../packages/gwfox.nix { sources = sourcesFor final; }).gwfox-t;
    };

    # Fcitx5 macOS input method with Rime (prebuilt Apple Silicon app bundle)
    fcitx5-macos =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin && prev.stdenv.hostPlatform.isAarch64 then
        { fcitx5-macos = final.callPackage ../packages/fcitx5-macos.nix { sources = sourcesFor final; }; }
      else
        { };

    # TickTick overlay with macOS support (Pin version)
    ticktick = final: prev: {
      ticktick =
        if prev.stdenv.hostPlatform.isDarwin then
          final.callPackage ../packages/ticktick.nix { sources = sourcesFor final; }
        else
          prev.ticktick;
    };

    # Skim PDF overlay with macOS support (Pin version)
    skimpdf = final: prev: {
      skimpdf =
        if prev.stdenv.hostPlatform.isDarwin then
          final.callPackage ../packages/skimpdf.nix { sources = sourcesFor final; }
        else
          prev.skimpdf;
    };

    # Deskflow overlay with macOS support (Pin version)
    deskflow = final: prev: {
      deskflow =
        if prev.stdenv.hostPlatform.isDarwin then
          final.callPackage ../packages/deskflow.nix { sources = sourcesFor final; }
        else
          prev.deskflow;
    };

    # FlClash overlay with macOS support (Pin version)
    flclash =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin then
        { flclash = final.callPackage ../packages/flclash.nix { sources = sourcesFor final; }; }
      else
        # FlClash is not packaged in nixpkgs.
        { };

    # CotEditor overlay with macOS support (Pin version)
    coteditor =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin then
        { coteditor = final.callPackage ../packages/coteditor.nix { sources = sourcesFor final; }; }
      else
        { };

    # Tencent Meeting overlay with macOS support (Pin version)
    tencent-meeting =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin then
        {
          tencent-meeting = final.callPackage ../packages/tencent-meeting.nix {
            sources = sourcesFor final;
          };
        }
      else
        { };

    # KeepingYouAwake overlay with macOS support (Pin version)
    keepingyouawake =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin then
        {
          keepingyouawake = final.callPackage ../packages/keepingyouawake.nix {
            sources = sourcesFor final;
          };
        }
      else
        { };

    # Zotero overlay: official universal DMG on macOS, upstream source build elsewhere
    zotero = final: prev: {
      zotero =
        if prev.stdenv.hostPlatform.isDarwin then
          final.callPackage ../packages/zotero.nix { sources = sourcesFor final; }
        else
          prev.zotero;
    };

    # Tencent WorkBuddy overlay with macOS (Apple Silicon) support (Pin version)
    workbuddy-cn =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin then
        {
          workbuddy-cn = final.callPackage ../packages/workbuddy-cn.nix {
            sources = sourcesFor final;
          };
        }
      else
        { };

    # DeepSeek Harness overlay with macOS (Apple Silicon) support (Pin version)
    deepseek-harness =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin then
        {
          deepseek-harness = final.callPackage ../packages/deepseek-harness.nix {
            sources = sourcesFor final;
          };
        }
      else
        { };

    # uutils-diffutils 0.6.0's tests look for Homebrew's `gpatch` on macOS.
    # Nixpkgs only provides GNU patch as `patch`, so the patch-validation tests
    # fail. Use Nixpkgs' GNU patch and ed, and point the tests at `patch`.
    # Upstream context: https://github.com/uutils/diffutils/issues/225
    uutils-diffutils =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin then
        {
          uutils-diffutils = prev.uutils-diffutils.overrideAttrs (old: {
            nativeCheckInputs = (old.nativeCheckInputs or [ ]) ++ [
              final.gnupatch
              final.ed
            ];
            postPatch = (old.postPatch or "") + ''
              substituteInPlace src/utils.rs --replace-fail '"gpatch"' '"patch"'
            '';
          });
        }
      else
        { };

    # LLM agents overlay (claude-code, opencode, gemini-cli, etc.)
    # https://github.com/numtide/llm-agents.nix
    llm-agents =
      final: _prev:
      {
        llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};
      };

  };
}
