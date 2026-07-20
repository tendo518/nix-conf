# Flake library functions
#
# Exports mkHostConfigurations, the shared host builder. Module-name resolution
# (resolveModuleList) matches an exact key plus everything nested under it as a
# prefix: "core" loads all core/* submodules, "hosts/foo" loads hosts/foo and
# hosts/foo/*.
{
  config,
  lib,
  ...
}:
let
  inherit (lib) types mkOption;

  # Resolve a list of module names into modules, with optional exclusions.
  #
  # A name resolves to its exact key (if one exists) plus every key nested
  # under it: "core" -> core/*, "hosts/foo" -> hosts/foo + hosts/foo/*. This
  # lets a name be both a module and a namespace parent, so listing a host
  # loads the host module and its split submodules (hardware, system, ...).
  #
  # Results are deduplicated by first occurrence, so listing both a namespace
  # ("network") and one of its children ("network/tailscale") loads the child
  # once. Exclusions expand the same way: excluding a namespace drops its
  # whole subtree.
  resolveModuleList =
    label: registry: names: excludeModules:
    let
      allKeys = builtins.attrNames registry;

      resolveKeys =
        name:
        lib.optional (builtins.elem name allKeys) name
        ++ builtins.filter (k: lib.hasPrefix "${name}/" k) allKeys;

      includedKeys = lib.unique (builtins.concatMap resolveKeys names);
      excludedKeys = lib.unique (builtins.concatMap resolveKeys excludeModules);
      finalKeys = builtins.filter (k: !builtins.elem k excludedKeys) includedKeys;
    in
    builtins.map (k: registry.${k}) finalKeys;

  # flake-parts assigns _class based on the registry key name, but home-manager
  # expects _class = "homeManager". Override the class on resolved modules.
  withClass =
    class: modules:
    map (
      m:
      if builtins.isFunction m then
        args: (m args) // { _class = class; }
      else if builtins.isAttrs m then
        m // { _class = class; }
      else
        m
    ) modules;

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
                  ++ withClass "homeManager" (
                    resolveModuleList "hm" (config.flake.modules.home or { }) hostCfg.modules hostCfg.excludeModules
                  )
                  ++ lib.optionals (target == "nixos") (
                    withClass "homeManager" (
                      resolveModuleList "hm-nixos" (config.flake.modules.homeNixOS or { }
                      ) hostCfg.modules hostCfg.excludeModules
                    )
                  )
                  ++ lib.optionals (target == "darwin") (
                    withClass "homeManager" (
                      resolveModuleList "hm-darwin" (config.flake.modules.homeDarwin or { }
                      ) hostCfg.modules hostCfg.excludeModules
                    )
                  );
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
    inherit mkHostConfigurations;
  };
}
