{
  flake.modules.homeManager."apps/ghostty" =
    { pkgs, lib, ... }:
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
          theme = "Dark Modern";
          scrollback-limit = 20000;
          background-opacity = 0.95;

          # notify
          notify-on-command-finish = "unfocused";
          notify-on-command-finish-action = "no-bell, notify";
          notify-on-command-finish-after = "15s";

        }
        // lib.optionalAttrs pkgs.stdenv.isDarwin {
          # macOS blur
          background-blur = "macos-glass-regular";
          background-blur-radius = 10;
        };
      };
    };
}
