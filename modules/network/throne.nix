{
  flake.modules.nixos."network/throne" = {
    programs.throne = {
      enable = true;
      tunMode.enable = true;
    };
  };
}
