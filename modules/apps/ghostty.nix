{
  flake.modules.home."apps/ghostty" =
    { pkgs, lib, ... }:
    {
      programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
        settings = {
          font-size = if pkgs.stdenv.hostPlatform.isDarwin then 14 else 12;
          font-family = [
            "IBM Plex Mono"
            "Sarasa Mono SC"
            "Symbols Nerd Font"
          ];
          theme = "Dark Modern";
          # Force dark window chrome (tabs/titlebar) instead of following system light/dark
          window-theme = "dark";
          scrollback-limit = 200000000;
          background-opacity = 0.90;
          unfocused-split-opacity = 1; # disable unfocus darken
          copy-on-select = "clipboard";
          clipboard-paste-protection = false;
          shell-integration-features = "cursor,sudo,title,ssh-env,ssh-terminfo";
          window-padding-x = 8;
          window-padding-y = 8;
          window-padding-balance = true;
          focus-follows-mouse = true;
          window-new-tab-position = "end";
          quit-after-last-window-closed = true;
          minimum-contrast = 1.1;
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
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          # macOS only
          auto-update = "off";
          font-thicken = true;
          macos-option-as-alt = true;
          macos-titlebar-style = "tabs";
          window-save-state = "always";
          window-step-resize = true;
        };
      };
    };
}
