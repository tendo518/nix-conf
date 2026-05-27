{
  lib,
  ...
}:
{
  flake.modules.homeManager."apps/neovim" = {
    # Neovim - medium priority default editor (helix > neovim > vim)
    programs.neovim = {
      enable = true;
      vimAlias = true;
      viAlias = true;
      withPython3 = false;
      withRuby = false;
    };

    home.sessionVariables = {
      EDITOR = lib.mkOverride 900 "nvim";
      VISUAL = lib.mkOverride 900 "nvim";
    };
  };
}
