# Flake library functions
#
# Exports resolveModules: resolves module names from the registry.
# Supports exact match ("core/nix") or prefix expansion ("core" loads all submodules).
{
  config,
  lib,
  ...
}:
let
  inherit (lib) types mkOption;

  # Resolve module names (exact match or prefix match)
  resolveModules =
    label: registry: name:
    if builtins.elem name (builtins.attrNames registry) then
      [ registry.${name} ]
    else
      let
        keys = builtins.filter (k: lib.hasPrefix "${name}/" k) (builtins.attrNames registry);
      in
      if keys == [ ] then [ ] else builtins.map (k: registry.${k}) keys;

  # Resolve a list of module names, with optional exclusions (mirrors disabledModules).
  resolveModuleList =
    label: registry: names: excludeModules:
    let
      resolveKeys =
        name:
        if builtins.elem name (builtins.attrNames registry) then
          [ name ]
        else
          builtins.filter (k: lib.hasPrefix "${name}/" k) (builtins.attrNames registry);

      includedKeys = builtins.concatMap resolveKeys names;
      excludedKeys = builtins.concatMap resolveKeys excludeModules;
      finalKeys = builtins.filter (k: !builtins.elem k excludedKeys) includedKeys;
    in
    builtins.map (k: registry.${k}) finalKeys;

  # Build host configurations for a given platform.
  # Parameterized by platform-specific builder, agenix/home-manager modules,
  # home base path, and backup file extension.
  # target: "nixos" or "darwin" — used to look up config.flake.modules.<target>.
  mkHostConfigurations =
    inputs:
    {
      builder,
      agenixModule,
      hmModule,
      homeBase,
      backupFileExtension,
    }:
    cfg: target:
    let
      systemModules = config.flake.modules.${target};
    in
    builtins.mapAttrs (
      name: hostCfg:
      builder {
        modules = [
          {
            imports = resolveModuleList "system" systemModules hostCfg.modules hostCfg.excludeModules;
          }
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
          (
            { lib, ... }:
            {
              imports = lib.optional hostCfg.useHomeManager hmModule;

              config = lib.mkIf hostCfg.useHomeManager {
                home-manager = {
                  useUserPackages = true;
                  useGlobalPkgs = true;
                  inherit backupFileExtension;
                  extraSpecialArgs = { inherit inputs; };
                };

                home-manager.users.${hostCfg.user.name} = {
                  imports = [
                    {
                      home.stateVersion = hostCfg.user.homeStateVersion;
                      home.username = hostCfg.user.name;
                      home.homeDirectory = "${homeBase}/${hostCfg.user.name}";
                      _module.args.userVars = hostCfg.user;
                    }
                  ]
                  ++ [ inputs.agenix.homeManagerModules.default ]
                  ++ resolveModuleList "hm" config.flake.modules.homeManager hostCfg.modules hostCfg.excludeModules;
                };
              };
            }
          )
          {
            imports = [ agenixModule ];
            networking.hostName = lib.mkDefault name;
            nixpkgs.hostPlatform = hostCfg.hostPlatform;
            system.stateVersion = hostCfg.stateVersion;
            programs.${hostCfg.user.shell}.enable = true;
          }
        ];
        specialArgs = { inherit inputs; };
      }
    ) cfg;
in
{
  options.flake.lib = mkOption {
    type = types.lazyAttrsOf types.unspecified;
    default = { };
    description = "Library functions exported by the flake";
  };

  config.flake.lib = {
    resolveModules = resolveModules "";
    inherit mkHostConfigurations;
  };
}
