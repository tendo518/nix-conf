{
  flake.modules.home."agents/claude-desktop" =
    {
      pkgs,
      lib,
      ...
    }:
    {
      # Provider and gateway configuration is injected by Magpie.
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        pkgs.llm-agents.claude-desktop
      ];
    };
}
