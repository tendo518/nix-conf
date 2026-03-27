# Build NixOS configurations from fleet.nixos options
{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.fleet.nixos;

  # Platform configuration
  platform = {
    builder = inputs.nixpkgs.lib.nixosSystem;
    agenixModule = inputs.agenix.nixosModules.default;
    hmModule = inputs.home-manager.nixosModules.home-manager;
    homeBase = "/home";
  };

  # Resolve module names (exact match or prefix match)
  resolveModules =
    registry: name:
    if registry ? ${name} then
      [ registry.${name} ]
    else
      let
        keys = builtins.filter (k: lib.hasPrefix "${name}/" k) (builtins.attrNames registry);
      in
      builtins.map (k: registry.${k}) keys;
in
{
  config.flake.nixosConfigurations = builtins.mapAttrs (
    name: hostCfg:
    platform.builder {
      modules =
        [
          # Import NixOS modules
          {
            imports = builtins.concatMap (resolveModules config.flake.modules.nixos) hostCfg.modules;
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
            system.stateVersion = hostCfg.stateVersion;
            programs.${hostCfg.user.shell}.enable = true;
          }
        ];
      specialArgs = { inherit inputs; };
    }
  ) cfg;
}