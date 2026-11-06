{
  flake.modules.home."apps/firefox-gwfox" =
    { lib, pkgs, ... }:
    let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      theme = if isDarwin then pkgs."gwfox-t" else pkgs."gwfox";
      themeDir = if isDarwin then "gwfox-t" else "gwfox";
    in
    {
      programs.firefox.profiles.default = {
        # Put the theme first: its stylesheet starts with an @namespace rule,
        # which must precede all ordinary CSS rules.
        userChrome = lib.mkBefore ''
          ${builtins.readFile "${theme}/share/${themeDir}/userChrome.css"}
        '';
        userContent = lib.mkBefore ''
          ${builtins.readFile "${theme}/share/${themeDir}/userContent.css"}
        '';

        settings = {
          "svg.context-properties.content.enabled" = true;
          "browser.newtabpage.activity-stream.nova.enabled" = true;
          "browser.nova.enabled" = true;
        }
        // lib.optionalAttrs isDarwin {
          "widget.macos.native-context-menus" = false;
          # Keep the sidebar visible while it is collapsed.
          "gwt.sidebar" = true;
        }
        // lib.optionalAttrs (!isDarwin) {
          "widget.gtk.rounded-bottom-corners.enabled" = true;
        };
      };
    };
}
