{
  flake.modules.nixos."system/appimage" = {
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };
}
