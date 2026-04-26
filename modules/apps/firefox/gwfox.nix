{
  flake.modules.homeManager."apps/firefox/ui-fix" =
    {
      pkgs,
      lib,
      config,
      inputs,
      ...
    }:
    let
      inherit (pkgs) stdenv;

      # gwfox source from flake input
      gwfox-src = inputs.gwfox;

      gwfox-chrome = pkgs.runCommand "gwfox-chrome" { } ''
        mkdir -p $out/chrome
        cp ${gwfox-src}/userChrome.css $out/chrome/userChrome.css
        cp ${gwfox-src}/userContent.css $out/chrome/userContent.css
      '';

      # Firefox profile path differs between Linux and macOS
      firefoxProfilePath =
        if stdenv.isDarwin then
          "Library/Application Support/Firefox/Profiles/default"
        else
          "${config.programs.firefox.configPath}/default";
    in
    {
      home.file = {
        "${firefoxProfilePath}/chrome/userChrome.css".source = "${gwfox-chrome}/chrome/userChrome.css";
        "${firefoxProfilePath}/chrome/userContent.css".source = "${gwfox-chrome}/chrome/userContent.css";
      };
      programs.firefox = {
        profiles.default.settings = {
          # Required gwfox settings
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "svg.context-properties.content.enabled" = true;
          "sidebar.animation.enabled" = false;

          # Platform-specific settings
          "widget.gtk.rounded-bottom-corners.enabled" = if stdenv.isLinux then true else false;
          "widget.macos.native-context-menus" = if stdenv.isDarwin then false else true;

          # Optional gwfox customizations
          "gwfox.plus" = false; # Bundled layout (macOS UI + Compact mode)
          "gwfox.plus_sc" = true;
          "gwfox.icons" = true; # Enable menu icons
          "gwfox.noborder" = false; # Borderless window mode
          "gwfox.ac" = false; # Accent color
          "gwfox.tp" = false; # Enable New Tab transparency Requires allow_transparent_browser
          "gwfox.db" = false; # Disable blur on panels/menus
          # "gwfox.sidebar" = Set sidebar width 1, 2, 3
        };
      };
    };
}
