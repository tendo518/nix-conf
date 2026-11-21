{
  flake.modules.home."agents/claude-code" =
    {
      pkgs,
      lib,
      ...
    }:
    let
      settings = pkgs.writeText "claude-settings.json" (
        builtins.toJSON {
          statusLine = {
            type = "command";
            command = "${pkgs.lib.getExe pkgs.llm-agents.ccstatusline}";
            padding = 0;
          };
          skipWebFetchPreflight = true;
          theme = "auto";
        }
      );
    in
    {
      home.packages = [
        pkgs.llm-agents.claude-code
      ];

      home.activation.setupClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.claude"
        rm -f "$HOME/.claude/settings.json"
        install -m 0644 ${settings} "$HOME/.claude/settings.json"
      '';
    };
}
