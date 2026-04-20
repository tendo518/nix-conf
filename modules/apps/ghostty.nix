{
  flake.modules.homeManager."apps/ghostty" =
    { pkgs, ... }:
    {
      programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
        settings = {
          font-size = if pkgs.stdenv.isDarwin then 14 else 12;
          font-family = "Retedo Mono";
        };
      };
    };
}
