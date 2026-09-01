let
  systemModule =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        tectonic
        typst
        tinymist
        typstyle
        pandoc
        glow
      ];
    };
in
{
  flake.modules.nixos."development/typesetting" = systemModule;
  flake.modules.darwin."development/typesetting" = systemModule;
}
