{
  flake.modules.home."apps/firefox/ui-fix" =
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

          # Platform-specific settings
          "widget.gtk.rounded-bottom-corners.enabled" = if stdenv.isLinux then true else false;
          "widget.macos.native-context-menus" = if stdenv.isDarwin then false else true;

          # gwfox customizations
          "gwfox.icons" = true; # Enable menu icons
          "gwfox.blur" = true; # Enable UI blur effects
          "gwfox.toolbar" = false; # Auto-hide bookmarks toolbar
          "gwfox.bms" = false; # Enable transparency (Linux only)
          "gwfox.noborder" = false; # Borderless window mode
          "gwfox.newtab" = false; # Enable New Tab transparency (requires allow_transparent_browser)
          "gwfox.urlbar" = false; # Move address bar to sidebar
          "gwfox.atbc" = true; # Adaptive Tab Bar Colour compatibility
          "gwfox.ac" = false; # Accent color (edit --bg0 in CSS to customize)
          # "gwfox.sidebar" = 1; # Set sidebar width (1, 2, or 3)
        };
      };
    };
}
