{
  flake.modules.home."agents/dsh" =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.llm-agents.dsh
        pkgs.pnpm # needed for dsh plugin
      ];
    };
}
