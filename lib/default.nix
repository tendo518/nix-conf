{ lib }:
let
  moduleMatches =
    allKeys: name: builtins.elem name allKeys || builtins.any (k: lib.hasPrefix "${name}/" k) allKeys;

  validateModuleNames =
    label: registries: names:
    let
      allKeys = builtins.concatLists (map builtins.attrNames registries);
      unknown = builtins.filter (name: !moduleMatches allKeys name) names;
    in
    if unknown != [ ] then
      throw "${label}: unknown module(s): ${lib.concatStringsSep ", " unknown}"
    else
      null;

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

  osModule = name: module: {
    flake.modules.nixos.${name} = module;
    flake.modules.darwin.${name} = module;
  };

  userModule =
    name:
    {
      nixos ? null,
      darwin ? null,
      homeManager ? null,
    }:
    {
      flake.modules.nixos = lib.optionalAttrs (nixos != null) {
        ${name} =
          { hostContext, ... }:
          {
            users.users.${hostContext.user.name} = nixos;
          };
      };

      flake.modules.darwin = lib.optionalAttrs (darwin != null) {
        ${name} =
          { hostContext, ... }:
          {
            users.users.${hostContext.user.name} = darwin;
          };
      };

      flake.modules.home = lib.optionalAttrs (homeManager != null) {
        ${name} = homeManager;
      };
    };

  mkHostConfigurations =
    { moduleRegistries, inputs }:
    {
      builder,
      agenixModule,
      hmModule,
      homeBase,
      backupFileExtension,
    }:
    cfg: target:
    let
      systemModules = moduleRegistries.${target} or { };
      homeModules = moduleRegistries.home or { };
      homeNixOSModules = moduleRegistries.homeNixOS or { };
      homeDarwinModules = moduleRegistries.homeDarwin or { };
      allSystemModules = [
        (moduleRegistries.nixos or { })
        (moduleRegistries.darwin or { })
      ];
    in
    builtins.mapAttrs (
      name: hostCfg:
      let
        hostContext = {
          hostname = name;
          user = hostCfg.user;
        };
        activeModuleValidation = validateModuleNames "host ${name}" [
          systemModules
          homeModules
          homeNixOSModules
          homeDarwinModules
        ] hostCfg.modules;
        exclusionValidation = validateModuleNames "host ${name}" (
          allSystemModules
          ++ [
            homeModules
            homeNixOSModules
            homeDarwinModules
          ]
        ) hostCfg.excludeModules;
        moduleValidation = builtins.seq activeModuleValidation exclusionValidation;
      in
      builtins.seq moduleValidation builder {
        modules = [
          {
            imports = resolveModuleList "system" systemModules hostCfg.modules hostCfg.excludeModules;
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
                  extraSpecialArgs = {
                    inherit inputs hostContext;
                    userContext = hostContext.user;
                  };
                };

                home-manager.users.${hostCfg.user.name} = {
                  imports = [
                    {
                      home.stateVersion = hostCfg.user.homeStateVersion;
                      home.username = hostCfg.user.name;
                      home.homeDirectory = "${homeBase}/${hostCfg.user.name}";
                    }
                  ]
                  ++ [ inputs.agenix.homeManagerModules.default ]
                  ++ withClass "homeManager" (
                    resolveModuleList "hm" homeModules hostCfg.modules hostCfg.excludeModules
                  )
                  ++ lib.optionals (target == "nixos") (
                    withClass "homeManager" (
                      resolveModuleList "hm-nixos" homeNixOSModules hostCfg.modules hostCfg.excludeModules
                    )
                  )
                  ++ lib.optionals (target == "darwin") (
                    withClass "homeManager" (
                      resolveModuleList "hm-darwin" homeDarwinModules hostCfg.modules hostCfg.excludeModules
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
        specialArgs = {
          inherit inputs hostContext;
        };
      }
    ) cfg;
in
{
  inherit
    osModule
    userModule
    mkHostConfigurations
    ;
}
