{
  flake.modules.home."agents/magpie" =
    { pkgs, lib, ... }:
    {
      home.packages = [
        pkgs.magpie-cli
        pkgs.bun
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.magpie ];
    };

  flake.modules.homeNixOS."agents/magpie" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      systemd.user.services.magpie = {
        Unit = {
          Description = "Magpie AI agent gateway";
          Documentation = [ "https://usemagpie.ai" ];
          Wants = [ "network-online.target" ];
          After = [ "network-online.target" ];
        };
        Service = {
          ExecStart = "${lib.getExe pkgs.magpie-cli} serve";
          Restart = "on-failure";
          RestartSec = "5s";
          WorkingDirectory = config.home.homeDirectory;
          Environment = [
            "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
            "XDG_CONFIG_HOME=${config.xdg.configHome}"
            "XDG_CACHE_HOME=${config.xdg.cacheHome}"
            "XDG_DATA_HOME=${config.xdg.dataHome}"
            "XDG_STATE_HOME=${config.xdg.stateHome}"
          ];
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
