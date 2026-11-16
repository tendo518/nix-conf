{
  perSystem =
    { lib, pkgs, ... }:
    let
      failures = import ../modules/agents/_tests { inherit lib; };
    in
    {
      checks.agent-config =
        if failures == [ ] then
          pkgs.runCommand "agent-config-tests"
            {
              nativeBuildInputs = [ pkgs.python3 ];
              AGENT_MODELS_UPDATER = ../scripts/update-agent-models.py;
            }
            ''
              python3 ${../modules/agents/_tests/update_models.py}
              touch "$out"
            ''
        else
          throw "Agent configuration tests failed: ${builtins.toJSON failures}";
    };
}
