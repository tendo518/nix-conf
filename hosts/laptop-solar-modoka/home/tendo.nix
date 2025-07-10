{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./file-associations.nix
  ];

  home.file."Library/Rime" = {
    source = inputs.rime-ice;
    recursive = true;
  };

  # for fcitx5-mac
  home.file.".local/share/fcitx5/rime" = {
    source = inputs.rime-ice;
    recursive = true;
  };

  xdg = {
    enable = true;
    cacheHome = "${config.home.homeDirectory}/.cache";
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";
  };
}
