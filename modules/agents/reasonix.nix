{
  flake.modules.home."agents/reasonix" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      reasonixHome = "${config.home.homeDirectory}/.reasonix";

      reasonixWrapped = pkgs.writeShellScriptBin "reasonix" ''
        set -e
        export REASONIX_HOME="${reasonixHome}"
        exec ${lib.getExe pkgs.llm-agents.reasonix} "$@"
      '';

      reasonixConfig = (pkgs.formats.toml { }).generate "reasonix-config.toml" {
        config_version = 5;
        language = "zh";
        ui = {
          theme = "auto";
          show_reasoning = true;
        };
        notifications = {
          enabled = true;
          turn_done = true;
          approval_request = true;
          ask_request = true;
        };
        telemetry.cli_metrics = "off";
        desktop = {
          telemetry = false;
          metrics = false;
        };
        agent = {
          temperature = 0.0;
          auto_plan = "off";
          soft_compact_ratio = 0.5;
          compact_ratio = 0.8;
          compact_force_ratio = 0.9;
        };
        tools = {
          enabled = [ ];
          bash_timeout_seconds = 120;
        };
        serve = {
          auth_mode = "none";
          behind_proxy = false;
        };
        permissions.mode = "ask";
        sandbox = {
          workspace_root = "";
          allow_write = [ "/tmp" ];
          bash = "enforce";
          network = true;
        };
      };
    in
    {
      home.packages = [
        pkgs.llm-agents.codegraph
        reasonixWrapped
      ];

      # default_model, providers, and credentials are injected by Magpie.
      home.activation.setupReasonixConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg="$HOME/.reasonix/config.toml"
        mkdir -p "$(dirname "$cfg")"
        rm -f "$cfg"
        install -m 600 ${reasonixConfig} "$cfg"
      '';
    };
}
