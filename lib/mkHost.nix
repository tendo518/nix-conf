# mkHost helper and system configuration builders
{
  inputs,
  lib,
  platforms,
  resolveModules,
  validateModules,
  hostOptions,
}:
let
  # Build a single system configuration
  mkSystemConfig =
    {
      systemType,
      name,
      moduleValue,
    }:
    let
      p = platforms.${systemType};
      hostname = lib.removePrefix p.configPrefix name;
    in
    lib.nameValuePair hostname (
      p.systemBuilder {
        modules = [
          moduleValue
          {
            networking.hostName = hostname;
            host.hostname = hostname;
          }
        ];
        specialArgs = { inherit inputs; };
      }
    );
in
{
  # Build all system configurations for a given type
  mkSystemConfigs =
    config: systemType:
    let
      p = platforms.${systemType};
      modules = config.flake.modules.${systemType} or { };
    in
    lib.pipe modules [
      (lib.filterAttrs (name: _: lib.hasPrefix p.configPrefix name))
      (lib.mapAttrs' (
        name: _:
        mkSystemConfig {
          inherit systemType name;
          moduleValue = modules.${name};
        }
      ))
    ];

  # mkHost helper - build a host with user config, modules, and home-manager
  mkHost =
    {
      systemType,
      modules,
      user,
      stateVersion,
      config,
    }:
    let
      p = platforms.${systemType};
      sysRegistry = config.flake.modules.${systemType};
      hmRegistry = config.flake.modules.homeManager;
      # Platform-specific home-manager registry
      darwinHmRegistry = config.flake.modules.darwinHomeManager or { };
      nixosHmRegistry = config.flake.modules.nixosHomeManager or { };
      # Merge platform-specific registry based on system type
      platformHmRegistry =
        if systemType == "darwin" then hmRegistry // darwinHmRegistry else hmRegistry // nixosHmRegistry;
      username = user.name;
      validated = validateModules systemType sysRegistry platformHmRegistry modules;
      resolvedSys = builtins.concatMap (resolveModules sysRegistry) validated;
      resolvedHm = builtins.concatMap (resolveModules platformHmRegistry) validated;
    in
    assert builtins.isAttrs config;
    assert builtins.isList modules;
    assert builtins.isAttrs user;
    assert username != null;
    {
      imports = [
        hostOptions
      ]
      ++ resolvedSys
      ++ [
        {
          host.user = user;
          system.stateVersion = stateVersion;
          programs.${user.shell}.enable = true;
        }
        p.agenixModule
        {
          imports = [ p.hmModule ];
          home-manager.useGlobalPkgs = true;
          home-manager.backupFileExtension = "home-manager.backup";
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.${username} = {
            imports = [
              {
                home.stateVersion = user.homeStateVersion;
                home.username = username;
                home.homeDirectory = "${p.homeBase}/${username}";
                _module.args.userVars = user;
              }
            ]
            ++ [ inputs.agenix.homeManagerModules.default ]
            ++ resolvedHm;
          };
        }
      ];
    };
}
