{
  flake.modules.home."agents/ccstatusline" =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.llm-agents.ccstatusline ];

      xdg.configFile."ccstatusline/settings.json".text = builtins.toJSON {
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
              color = "white";

            }
            {
              id = "think";
              type = "thinking-effort";
              color = "yellow";
            }
            {
              id = "sep2";
              type = "separator";
              color = "white";

            }
            {
              id = "cwd";
              type = "current-working-dir";
              color = "blue";
              metadata.fishStyle = "true";
            }
            {
              id = "sep3";
              type = "separator";
              color = "white";

            }
            {
              id = "branch";
              type = "git-branch";
              color = "magenta";
            }
            {
              id = "sep4";
              type = "separator";
              color = "white";

            }
            {
              id = "changes";
              type = "git-changes";
              color = "yellow";
            }
            {
              id = "sep5";
              type = "separator";
              color = "white";

            }
            {
              id = "ctx";
              type = "context-bar";
              color = "gradient:cristal";
              metadata.display = "slider";
            }
          ]
          [ ]
          [ ]
        ];
        flexMode = "full";
        compactThreshold = 60;
        colorLevel = 3;
        minimalistMode = true;
        inheritSeparatorColors = true;
        globalBold = false;
        defaultPadding = "";
      };
    };
}
