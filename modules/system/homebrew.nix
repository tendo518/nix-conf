{
  flake.modules.darwin."system/homebrew" =
    { lib, ... }:
    let
      # Homebrew Mirror
      homebrew_mirror_env = {
        HOMEBREW_API_DOMAIN = "https://mirrors.bfsu.edu.cn/homebrew-bottles/api";
        HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.bfsu.edu.cn/homebrew-bottles";
        HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.bfsu.edu.cn/git/homebrew/brew.git";
        HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.bfsu.edu.cn/git/homebrew/homebrew-core.git";
        HOMEBREW_PIP_INDEX_URL = "https://mirrors.bfsu.edu.cn/pypi/web/simple";
      };
    in
    {
      # Set variables for you to manually install homebrew packages.
      environment.variables = homebrew_mirror_env;
      # fix https://github.com/nix-darwin/nix-darwin/issues/1787
      homebrew.onActivation.extraFlags = [
        "--force-cleanup"
      ];

      # Set environment variables for nix-darwin before run `brew bundle`.
      system.activationScripts.homebrew.text =
        let
          env_script = lib.attrsets.foldlAttrs (
            acc: name: value:
            acc + "
    export ${name}=${value}"
          ) "" homebrew_mirror_env;
        in
        lib.mkBefore ''
          echo >&2 '${env_script}'
          ${env_script}
        '';
    };
}
