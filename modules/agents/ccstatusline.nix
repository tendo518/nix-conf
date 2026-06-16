{
  flake.modules.home."agents/ccstatusline" =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.llm-agents.ccstatusline ];

      xdg.configFile."ccstatusline/settings.json" = {
        text = builtins.toJSON {
          version = 3;
          lines = [
            [
              {
                id = "model";
                type = "model";
                color = "cyan";
              }
              {
                id = "sep1";
                type = "separator";
              }
              {
                id = "ctx";
                type = "context-length";
                color = "brightBlack";
              }
              {
                id = "sep2";
                type = "separator";
              }
              {
                id = "branch";
                type = "git-branch";
                color = "magenta";
              }
              {
                id = "sep3";
                type = "separator";
              }
              {
                id = "changes";
                type = "git-changes";
                color = "yellow";
              }
              {
                id = "sep4";
                type = "separator";
              }
              {
                id = "think";
                type = "thinking-effort";
                color = "yellow";
              }
              {
                id = "flex";
                type = "flex-separator";
              }
              {
                id = "cached";
                type = "tokens-cached";
              }
              {
                id = "sep5";
                type = "separator";
              }
              {
                id = "total";
                type = "tokens-total";
              }
              {
                id = "sep6";
                type = "separator";
              }
              {
                id = "speed";
                type = "output-speed";
              }
            ]
            [ ]
            [ ]
          ];
          flexMode = "full";
          compactThreshold = 60;
          colorLevel = 3;
          inheritSeparatorColors = true;
          globalBold = true;
          defaultPadding = "";
        };
      };
    };
}
