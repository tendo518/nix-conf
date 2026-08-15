{
  flake.modules.home."agents/core" =
    { pkgs, ... }:
    {
      home.packages = with pkgs.llm-agents; [
        antigravity-cli
        dsh
        kilocode-cli
        qoder-cli
        opencode2
        herdr  # https://herdr.dev
      ];
    };
}
