{
  flake.modules.home."apps/ghostty" =
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
          # Force dark window chrome (tabs/titlebar) instead of following system light/dark
          window-theme = "dark";
          scrollback-limit = 200000;
          background-opacity = 0.90;
          unfocused-split-opacity = 1; # disable unfocus darken
          # notify
          notify-on-command-finish = "unfocused";
          notify-on-command-finish-action = "no-bell, notify";
          notify-on-command-finish-after = "30s";
          # macOS blur, seems works on KDE too
          background-blur = "macos-glass-regular";
          background-blur-radius = 20;
          # Quality of life
          mouse-hide-while-typing = true;
          clipboard-trim-trailing-spaces = true;
          link-url = true;
        }
        // lib.optionalAttrs pkgs.stdenv.isDarwin {
          # macOS only
          macos-option-as-alt = true;
          window-save-state = "always";
        };
      };
    };
}
