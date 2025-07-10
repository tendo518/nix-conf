{
  flake.modules.darwin."system/darwin-base" =
    { pkgs, hostContext, ... }:
    {
      system.primaryUser = hostContext.user.name;

      security.pam.services.sudo_local.touchIdAuth = true;

      programs.fish.enable = true;
      programs.zsh.enable = true;
      environment.shells = [
        pkgs.fish
        pkgs.zsh
      ];
    };
}
