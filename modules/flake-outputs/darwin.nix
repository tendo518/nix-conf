# Build Darwin configurations from fleet.darwin options
{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.fleet.darwin;
  resolveModules = config.flake.lib.resolveModules;

  # Platform configuration
  platform = {
    builder = inputs.nix-darwin.lib.darwinSystem;
    agenixModule = inputs.agenix.darwinModules.default;
    hmModule = inputs.home-manager.darwinModules.home-manager;
    homeBase = "/Users";
  };
in
{
  config.flake.darwinConfigurations = builtins.mapAttrs (
    name: hostCfg:
    platform.builder {
      modules =
        [
          # Import Darwin modules
          {
            imports = builtins.concatMap (resolveModules config.flake.modules.darwin) hostCfg.modules;
          }
          # Set up host.user option
          {
            options.host = {
              user = lib.mkOption {
                type = lib.types.attrs;
                default = hostCfg.user;
                description = "User configuration for this host";
              };
              hostname = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "Hostname for this host";
              };
            };
          }
          # Import Home Manager
          (
            { lib, ... }:
            {
              imports = lib.optional hostCfg.useHomeManager platform.hmModule;

              config = lib.mkIf hostCfg.useHomeManager {
                home-manager = {
                  useUserPackages = true;
                  useGlobalPkgs = true;
                  backupFileExtension = "home-manager.backup";
                  extraSpecialArgs = { inherit inputs; };
                };

                home-manager.users.${hostCfg.user.name} = {
                  imports =
                    [
                      {
                        home.stateVersion = hostCfg.user.homeStateVersion;
                        home.username = hostCfg.user.name;
                        home.homeDirectory = "${platform.homeBase}/${hostCfg.user.name}";
                        _module.args.userVars = hostCfg.user;
                      }
                    ]
                    ++ [ inputs.agenix.homeManagerModules.default ]
                    ++ builtins.concatMap (resolveModules config.flake.modules.homeManager) hostCfg.modules;
                };
              };
            }
          )
          # System configuration
          {
            imports = [ platform.agenixModule ];
            networking.hostName = lib.mkDefault name;
            nixpkgs.hostPlatform = hostCfg.hostPlatform;
            system.stateVersion = hostCfg.stateVersion;
            programs.${hostCfg.user.shell}.enable = true;
          }
        ];
      specialArgs = { inherit inputs; };
    }
  ) cfg;
}