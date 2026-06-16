{
  flake.modules.home."development/git" =
    {
      lib,
      config,
      userVars,
      ...
    }:
    let
      username = config.home.username;
      useremail = userVars.email;
    in
    {
      # `programs.git` will generate the config file: ~/.config/git/config
      # to make git use this config file, `~/.gitconfig` should not exist!
      home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        rm -f ~/.gitconfig
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
