{
  lib,
  ...
}:
{
  flake.modules.home."core/editors" = {
    # Vim - lowest priority default editor (helix > neovim > vim)
    programs.vim = {
      enable = true;
    };

    # Priority chain:
    # 1. helix (mkForce in apps/helix.nix)
    # 2. neovim (mkDefault in apps/neovim.nix, overrides this one via module order)
    # 3. vim (mkDefault here, lowest priority)
    home.sessionVariables = {
      EDITOR = lib.mkDefault "vim";
      VISUAL = lib.mkDefault "vim";
    };
  };
}
