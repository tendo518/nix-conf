# Custom overlays for the flake
{ inputs, ... }:
{
  flake.overlays = {
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

    # ChatGPT desktop overlay: official artifact on macOS; llm-agents' Linux-only
    # chatgpt package on Linux
    chatgpt-desktop = final: prev: {
      chatgpt-desktop =
        if prev.stdenv.hostPlatform.isDarwin then
          final.callPackage ../packages/chatgpt-desktop { }
        else if prev.stdenv.hostPlatform.isLinux then
          final.llm-agents.chatgpt
        else
          prev.chatgpt-desktop or null;
    };

    # Clash Verge Rev overlay with macOS support (Pin version)
    clash-verge-rev =
      final: prev:
      if prev.stdenv.hostPlatform.isDarwin then
        { clash-verge-rev = final.callPackage ../packages/clash-verge-rev { }; }
      else
        # {
        #   # mihomo 1.19.27 is incompatible with clash-verge-rev 2.5.1 (nixpkgs#535128).
        #   # TODO: remove once a clash-verge-rev release with the fix lands in nixpkgs.
        #   mihomo_1_19_26 = prev.mihomo.overrideAttrs (old: rec {
        #     version = "1.19.26";
        #     src = final.fetchFromGitHub {
        #       owner = "MetaCubeX";
        #       repo = "mihomo";
        #       rev = "v${version}";
        #       hash = "sha256-As0MqIGHs1Gn+aUWpeFsC231n9v7lBNmGlQdAwVWcJs=";
        #     };
        #     vendorHash = "sha256-ySpBMR/djPPs1aTw7yiCrCFxDFsvRfTJEChg8v1C408=";
        #   });
        {
          inherit (prev) clash-verge-rev;
        };

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

    # LLM agents overlay (claude-code, opencode, gemini-cli, etc.)
    # https://github.com/numtide/llm-agents.nix
    llm-agents = final: _prev: {
      llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};
    };

  };
}
