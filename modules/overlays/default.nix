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

    # LLM agents overlay (claude-code, opencode, gemini-cli, etc.)
    # https://github.com/numtide/llm-agents.nix
    llm-agents = inputs.llm-agents.overlays.default;

    # OpenLDAP: skip tests on i686
    openldap = _: prev: {
      openldap = prev.openldap.overrideAttrs {
        doCheck = !prev.stdenv.hostPlatform.isi686;
      };
    };

    # TODO: remove once https://github.com/NixOS/nixpkgs/pull/513081 lands in nixpkgs-unstable.
    # Workaround for direnv 2.37.1 testsuite hanging on aarch64-darwin (macOS Tahoe).
    direnv = _: prev: {
      direnv = prev.direnv.overrideAttrs {
        doCheck = !prev.stdenv.hostPlatform.isDarwin;
      };
    };
  };
}
