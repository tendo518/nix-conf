{
  flake.modules.nixos."system/getty" =
    { config, ... }:
    {
      services.getty.greetingLine = with config.system.nixos; ''
        NixOS ${release} (${codeName})
        \e{lightcyan}@ tendo/nix-conf
      '';
    };
}
