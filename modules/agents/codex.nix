{
  flake.modules.home."agents/codex" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      toml = pkgs.formats.toml { };

      codexConfig = toml.generate "codex-config.toml" {
        approval_policy = "on-request";
        approvals_reviewer = "auto_review";
        sandbox_mode = "workspace-write";
        check_for_update_on_startup = false;
        analytics.enabled = false;
        features.context_management.experimental_mode = true;
        tui = {
          status_line = [
            "model-with-reasoning"
            "project-name"
            "run-state"
            "context-used"
            "weekly-limit"
          ];
          status_line_use_colors = true;
          notifications = true;
        };
        projects.${config.home.homeDirectory}.trust_level = "trusted";
      };

      codex = pkgs.writeShellScriptBin "codex" ''
        export CODEX_HOME="${config.xdg.configHome}/codex"
        exec ${lib.getExe pkgs.llm-agents.codex} "$@"
      '';
    in
    {
      home.packages = [
        codex
      ]
      # Codex's Linux sandbox warns unless bwrap is on PATH, falling back
      # to the copy bundled in the Codex package.
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.bubblewrap ];

      home.activation.setupCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfgDir="${config.xdg.configHome}/codex"
        mkdir -p "$cfgDir"
        if [ -e "$HOME/.codex" ] && [ ! -L "$HOME/.codex" ]; then
          mv "$HOME/.codex" "$HOME/.codex.bak.$(date +%s)"
        fi
        ln -sfn "$cfgDir" "$HOME/.codex"
        rm -f "$cfgDir/config.toml" "$cfgDir"/codex-*.config.toml
        install -m 0644 ${codexConfig} "$cfgDir/config.toml"
      '';
    };
}
