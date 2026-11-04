# Custom overlays for the flake
{ inputs, ... }:
{
  flake.overlays = {
    # vim-full 9.2.1164 fails on Darwin when built with GTK2 and the image
    # feature is enabled: image.c references gui.scale, but that field is
    # omitted for GTK2.  Backport NixOS/nixpkgs#576728 until the pinned
    # nixpkgs includes it: default Darwin's vim-full to GTK3 and make the
    # GTK wrapper hook use gtk3-x11.
    #   https://github.com/NixOS/nixpkgs/pull/576728
    vim = _final: prev: {
      vim-full =
        if prev.stdenv.hostPlatform.isDarwin then
          prev.vim-full.override {
            guiSupport = "gtk3";
            wrapGAppsHook3 = prev.wrapGAppsHook3.override { gtk3 = prev.gtk3-x11; };
          }
        else
          prev.vim-full;
    };

    # TickTick overlay with macOS support (Pin version)
    ticktick = final: prev: {
      ticktick =
        if prev.stdenv.hostPlatform.isDarwin then
          final.callPackage ../packages/ticktick { }
        else
          prev.ticktick;
    };

    # Skim PDF overlay with macOS support (Pin version)
    skimpdf = final: prev: {
      skimpdf =
        if prev.stdenv.hostPlatform.isDarwin then
          final.callPackage ../packages/skimpdf { }
        else
          prev.skimpdf;
    };

    # Deskflow overlay with macOS support (Pin version)
    deskflow = final: prev: {
      deskflow =
        if prev.stdenv.hostPlatform.isDarwin then
          final.callPackage ../packages/deskflow { }
        else
          prev.deskflow;
    };

    # FlClash overlay with macOS support (Pin version)
    flclash =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin then
        { flclash = final.callPackage ../packages/flclash { }; }
      else
        # FlClash is not packaged in nixpkgs.
        { };

    # CotEditor overlay with macOS support (Pin version)
    coteditor =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin then
        { coteditor = final.callPackage ../packages/coteditor { }; }
      else
        { };

    # Tencent Meeting overlay with macOS support (Pin version)
    tencent-meeting =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin then
        { tencent-meeting = final.callPackage ../packages/tencent-meeting { }; }
      else
        { };

    # KeepingYouAwake overlay with macOS support (Pin version)
    keepingyouawake =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin then
        { keepingyouawake = final.callPackage ../packages/keepingyouawake { }; }
      else
        { };

    # Zotero overlay: official universal DMG on macOS, upstream source build elsewhere
    zotero = final: prev: {
      zotero =
        if prev.stdenv.hostPlatform.isDarwin then final.callPackage ../packages/zotero { } else prev.zotero;
    };

    # Tencent WorkBuddy overlay with macOS (Apple Silicon) support (Pin version)
    workbuddy-cn =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin then
        { workbuddy-cn = final.callPackage ../packages/workbuddy-cn { }; }
      else
        { };

    # DeepSeek Harness overlay with macOS (Apple Silicon) support (Pin version)
    deepseek-harness =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin then
        { deepseek-harness = final.callPackage ../packages/deepseek-harness { }; }
      else
        { };

    # LLM agents overlay (claude-code, opencode, gemini-cli, etc.)
    # https://github.com/numtide/llm-agents.nix
    llm-agents =
      final: _prev:
      let
        packages = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};
      in
      {
        llm-agents = packages // {
          # llm-agents ships only the herdr-app executable. On macOS, wrap
          # it in Herdr.app so Finder, Spotlight and LSEnvironment work.
          herdr-app =
            if final.stdenv.hostPlatform.isDarwin then
              final.callPackage ../packages/herdr-app {
                inherit (packages) herdr-app herdr-core;
              }
            else
              packages.herdr-app;
        };
      };

  };
}
