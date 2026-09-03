{
  flake.modules.home."agents/base" =
    { pkgs, ... }:
    {
      home.packages = with pkgs.llm-agents; [
        # antigravity-cli
        dsh
        # kilocode-cli
        # qoder-cli
        # opencode2
        herdr # https://herdr.dev
        hermes-agent
      ];
    };
}
