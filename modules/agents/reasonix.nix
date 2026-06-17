{
  flake.modules.home."agents/reasonix" =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (config.age.secrets) deepseek-api-key;

      reasonixWrapped = pkgs.writeShellScriptBin "reasonix" ''
        if [ -r "${deepseek-api-key.path}" ]; then
          export DEEPSEEK_API_KEY="$(cat "${deepseek-api-key.path}")"
        fi
        exec ${lib.getExe pkgs.llm-agents.reasonix} "$@"
      '';
    in
    {
      home.packages = [
        pkgs.llm-agents.codegraph
        reasonixWrapped
      ];

      # reasonix may rewrite this file at runtime (e.g. updating settings),
      # so force overwrite to avoid backup-file collisions on re-activation.
      xdg.configFile."reasonix/config.toml".force = true;
      xdg.configFile."reasonix/config.toml".text = ''
        default_model = "deepseek"
        language = "zh"

        [ui]
        theme = "auto"   # auto|dark|light

        [notifications]
        enabled          = true   # system notifications for CLI chat/run; default off
        turn_done        = true
        approval_request = true
        ask_request      = true

        [[providers]]
        name           = "deepseek"
        kind           = "openai"
        base_url       = "https://api.deepseek.com"
        models         = ["deepseek-v4-flash", "deepseek-v4-pro"]
        default        = "deepseek-v4-pro"   # optional; defaults to models[0]
        api_key_env    = "DEEPSEEK_API_KEY"
        context_window = 1000000   # tokens; harness compacts older history near this limit (0 disables)
        effort         = "auto"    # DeepSeek thinking effort: high | max

        # not very usable subagent, seems planner are put into sandbox but still try to finish itself
        # the planner is not well prompted howto give instruction to executor
        # 所以回退到使用单模型
        # [agent]
        # max_steps          = 0     # executor tool-call rounds; 0 = no limit
        # planner_max_steps  = 0    # planner read-only tool-call rounds; 0 = no limit
        # planner_model      = "deepseek-v4-pro"
        # subagent_model = "deepseek-v4-pro"

        [codegraph]
        enabled      = true
        auto_install = false
      '';

      age.secrets = {
        deepseek-api-key.file = ../../secrets/deepseek-api-key.age;
      };
    };
}
