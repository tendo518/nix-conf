{
  lib,
  ...
}:
{
  flake.modules.homeManager."core/editors" = {
    # Vim - lowest priority default editor (helix > neovim > vim)
    programs.vim = {
      enable = true;
    };

    home.sessionVariables = {
      EDITOR = lib.mkDefault "vim";
      VISUAL = lib.mkDefault "vim";
    };
  };
}
