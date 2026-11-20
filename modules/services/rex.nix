{
  flake.modules.nixos."services/rex" =
    { hostContext, ... }:
    {
      users.users.${hostContext.user.name}.linger = true;
    };

  flake.modules.homeNixOS."services/rex" =
    { inputs, ... }:
    {
      imports = [ inputs.rex.homeManagerModules.default ];

      services.rex.enable = true;
    };
}
