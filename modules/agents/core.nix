{
  flake.modules.home."agents/core" =
    { pkgs, ... }:
    {
      home.packages = with pkgs.llm-agents; [
        codex
        antigravity-cli
        kilocode-cli
        qoder-cli
      ];
    };
}
