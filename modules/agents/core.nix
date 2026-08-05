{
  flake.modules.home."agents/core" =
    { pkgs, ... }:
    {
      home.packages = with pkgs.llm-agents; [
        antigravity-cli
        kilocode-cli
        qoder-cli
        opencode2
      ];
    };
}
