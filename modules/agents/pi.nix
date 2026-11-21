{
  flake.modules.home."agents/pi" =
    {
      pkgs,
      lib,
      ...
    }:
    let
      piPackages = [
        "npm:@ff-labs/pi-fff"
        "npm:@narumitw/pi-btw"
        "npm:@narumitw/pi-goal"
        "npm:@narumitw/pi-plan-mode"
        "npm:@narumitw/pi-statusline"
        "npm:@narumitw/pi-tool"
        "npm:@narumitw/pi-usage"
        "npm:pi-open-tui"
        "npm:pi-subagents"
        "npm:pi-web-access"
      ];

      settingsJson = builtins.toJSON {
        "$schema" = "https://pi.dev/schemas/settings.schema.json";
        packages = piPackages;
        quietStartup = true;
        enableInstallTelemetry = false;
        retry.provider.maxRetries = 0;
        theme = "dark";
        hideThinkingBlock = true;
        tuiMode = "fullscreen";
        fullscreenWheelScrollLines = "auto";
        terminal.showTerminalProgress = true;
      };

      piSettingsDefaults = pkgs.writeText "pi-settings.json" settingsJson;

      openTuiConfig = {
        enabled = true;
        inlineFooter = true;
        settingsLanguage = "en";
        cursorStyle = "block";
        icons.mode = "ascii";
        footerSegments = {
          cwd = true;
          hostname = true;
          sessionName = true;
          gitBranch = true;
          gitStatus = true;
          gitCommit = false;
          runtime = true;
          context = true;
          tokens = true;
          cost = true;
          extensionStatuses = true;
          capitalizeProviderName = true;
          nerdIconSpacing = false;
        };
        telemetry = {
          enabled = true;
          tps = true;
          ttft = true;
          duration = true;
          tokens = true;
          stalls = true;
          cost = true;
        };
        thinkingPeek.lines = 2;
      };

      openTuiDefaults = pkgs.writeText "pi-open-tui.json" (builtins.toJSON openTuiConfig);
    in
    {
      home.packages = [ pkgs.llm-agents.pi ];

      # Start Pi with the codemode tool enabled by default.
      home.shellAliases.pi-code = "pi --tools +codemode";

      # Keep editable settings writable. Provider and model files are owned by
      # Magpie and are deliberately not written here.
      home.activation.setupPiSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        piSettings="$HOME/.pi/agent/settings.json"
        openTui="$HOME/.pi/agent/open-tui.json"
        mkdir -p "$(dirname "$piSettings")"

        rm -f "$piSettings"
        install -m 600 ${piSettingsDefaults} "$piSettings"

        rm -f "$openTui"
        install -m 644 ${openTuiDefaults} "$openTui"
      '';
    };
}
