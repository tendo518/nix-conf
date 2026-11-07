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

          # Optional GWfox-T customization; leave unset unless needed.
          # "gwt.oneliner" = true; # Compact layout
          # "gwt.toolbar" = true; # Auto-hide bookmarks toolbar
          # "gwt.toolbox" = true; # Auto-hide navigator toolbox
          # "gwt.atbc" = true; # Adaptive Tab Bar Colour compatibility
        }
        // lib.optionalAttrs (!isDarwin) {
          "widget.gtk.rounded-bottom-corners.enabled" = true;

          # gwfox customization. Only icons is enabled; the rest are left
          # unset by default.
          "gwfox.icons" = true;
          # "gwfox.urlbar" = true; # Move address bar to sidebar
          # "gwfox.toolbar" = true; # Auto-hide bookmarks toolbar
          # "gwfox.urlbar.ac" = true; # Auto-collapse address bar
          # "gwfox.blur" = true; # Acrylic effect on floating panels
          # "gwfox.ac" = true; # Accent color
          # "gwfox.atbc" = true; # Adaptive Tab Bar Colour compatibility
          # "gwfox.newtab" = true; # Transparent new tab
          # "gwfox.noborder" = true; # Remove window borders
          # "gwfox.bms" = true; # Main-window transparency
          # "gwfox.mwc" = true; # macOS-style window controls
          # "gwfox.msc" = true; # macOS-style tab close button
          # "gwfox.twc" = true; # Theme-styled window controls
          # "gwfox.twc.ac" = true; # Auto-collapse window controls
          # "gwfox.fxa" = true; # Avatar in app menu
          # "gwfox.fsi" = true; # FluentUI System Icons
          # "gwfox.sidebar" = 3; # Sidebar width: 1 narrow, 3 wide
          # "gwfox.container" = 5; # Container tab indicator: 1-5
        };
      };
    };
}
