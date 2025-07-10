{
  flake.modules.home."development/git" =
    {
      lib,
      config,
      userContext,
      ...
    }:
    let
      username = config.home.username;
      useremail = userContext.email;
    in
    {
      # Home Manager writes ~/.config/git/config when XDG is enabled. Preserve a
      # pre-existing legacy config instead of deleting user-owned data.
      home.activation.backupLegacyGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        if [ -e "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
          mv "$HOME/.gitconfig" "$HOME/.gitconfig.before-home-manager.$(date +%s)"
        fi
      '';

      programs.git = {
        enable = true;
        lfs.enable = true;

        settings = {
          user.name = username;
          user.email = useremail;
          init.defaultBranch = "main";
          push.autoSetupRemote = true;
          pull.rebase = true;

          alias = {
            # common aliases
            br = "branch";
            co = "checkout";
            st = "status";
            ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]\" --decorate";
            ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]\" --decorate --numstat";
            cm = "commit -m";
            ca = "commit -am";
            dc = "diff --cached";
            amend = "commit --amend -m";

            # aliases for submodule
            update = "submodule update --init --recursive";
            foreach = "submodule foreach";
          };
        };
      };

      # nice diff viewer
      programs.delta = {
        enable = true;
        options = {
          features = "side-by-side";
        };
      };

      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
      };

      programs.lazygit = {
        enable = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
      };
    };
}
