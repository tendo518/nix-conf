{
  flake.modules.home."agents/omp" =
    {
      pkgs,
      lib,
      ...
    }:
    let
      configYml = builtins.toJSON {
        setupVersion = 1;
        startup = {
          checkUpdate = false;
          setupWizard = false;
          quiet = true;
        };
        marketplace.autoUpdate = "off";
        model.loopGuard.enabled = true;
        retry.maxRetries = 5;
        tools.approvalMode = "yolo";
        bash.gitGuard = true;
        providers = {
          streamFirstEventTimeoutSeconds = 120;
          streamIdleTimeoutSeconds = 300;
        };
        compaction = {
          enabled = true;
          thresholdPercent = 80;
          midTurnEnabled = true;
          asyncEnabled = true;
          dropUseless = true;
          supersedeReads = true;
        };
        lsp = {
          diagnosticsOnEdit = true;
          requestTimeout = 20;
        };
        edit.autoRepair.enabled = true;
        task = {
          enableLsp = true;
          maxConcurrency = 8;
          isolation = {
            enabled = true;
            apply = true;
            merge = "patch";
          };
          maxRecursionDepth = 2;
          showResolvedModelBadge = true;
        };
        web_search.enabled = true;
        github.enabled = true;
        fetch.enabled = true;
        skills = {
          enableClaudeUser = true;
          enablePiUser = true;
        };
        commands.enableClaudeUser = true;
        memory.backend = "off";
        tui.imeSafeCursor = true;
        terminal.showProgress = true;
        composer.tokenRate = true;
        display = {
          showTokenUsage = true;
          showTurnTime = true;
          cacheMissMarker = true;
          subagentLivePreview = true;
        };
        error.notify = "on";
        symbolPreset = "nerd";
        statusLine = {
          preset = "default";
          transparent = true;
        };
        images.blockImages = true;
        secrets.enabled = true;
      };

      configDefaults = pkgs.writeText "omp-config.yml" configYml;
    in
    {
      home.packages = [ pkgs.llm-agents.omp ];

      # models.yml and modelRoles are injected by Magpie.
      home.activation.setupOmpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ompDir="$HOME/.omp/agent"
        mkdir -p "$ompDir"

        rm -f "$ompDir/config.yml"
        install -m 600 ${configDefaults} "$ompDir/config.yml"
      '';
    };
}
