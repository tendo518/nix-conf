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

      # Firefox-UI-Fix source from flake input
      firefox-ui-fix-src = inputs.firefox-ui-fix;

      firefox-ui-fix-chrome = pkgs.runCommand "firefox-ui-fix-chrome" { } ''
        mkdir -p $out/chrome
        cp ${firefox-ui-fix-src}/userChrome.css $out/chrome/userChrome.css
        cp ${firefox-ui-fix-src}/userContent.css $out/chrome/userContent.css
        cp -r ${firefox-ui-fix-src}/css $out/chrome/
        cp -r ${firefox-ui-fix-src}/icons $out/chrome/icons 2>/dev/null || true
        cp -r ${firefox-ui-fix-src}/theme $out/chrome/theme 2>/dev/null || true
      '';

      # Firefox profile path differs between Linux and macOS
      firefoxProfilePath =
        if stdenv.isDarwin then
          "Library/Application Support/Firefox/Profiles/default"
        else
          ".mozilla/firefox/default";
    in
    {
      home.file = {
        "${firefoxProfilePath}/chrome/userChrome.css".source =
          "${firefox-ui-fix-chrome}/chrome/userChrome.css";
        "${firefoxProfilePath}/chrome/userContent.css".source =
          "${firefox-ui-fix-chrome}/chrome/userContent.css";
        "${firefoxProfilePath}/chrome/css".source = "${firefox-ui-fix-chrome}/chrome/css";
        "${firefoxProfilePath}/chrome/icons".source = "${firefox-ui-fix-chrome}/chrome/icons";
        "${firefoxProfilePath}/chrome/theme".source = "${firefox-ui-fix-chrome}/chrome/theme";
      };
      programs.firefox = {
        profiles.default.settings = {
          # Firefox-UI-Fix settings
          "svg.context-properties.content.enabled" = true;
          "browser.compactmode.show" = true;
          "browser.newtabpage.activity-stream.improvesearch.handoffToAwesomebar" = false;
          "layout.css.has-selector.enabled" = true;
          "browser.tabs.hoverPreview.enabled" = true;
          "browser.urlbar.clipboard.featureGate" = true;
          "browser.urlbar.suggest.calculator" = true;
          "userChrome.compatibility.theme" = true;
          "userChrome.compatibility.os" = true;
          "userChrome.theme.built_in_contrast" = true;
          "userChrome.theme.system_default" = true;
          "userChrome.theme.proton_color" = true;
          "userChrome.theme.proton_chrome" = true;
          "userChrome.theme.fully_color" = true;
          "userChrome.theme.fully_dark" = true;
          "userChrome.decoration.cursor" = true;
          "userChrome.decoration.field_border" = true;
          "userChrome.decoration.download_panel" = true;
          "userChrome.decoration.animate" = true;
          "userChrome.padding.tabbar_width" = true;
          "userChrome.padding.tabbar_height" = true;
          "userChrome.padding.toolbar_button" = true;
          "userChrome.padding.navbar_width" = true;
          "userChrome.padding.urlbar" = true;
          "userChrome.padding.bookmarkbar" = true;
          "userChrome.padding.infobar" = true;
          "userChrome.padding.menu" = true;
          "userChrome.padding.bookmark_menu" = true;
          "userChrome.padding.global_menubar" = true;
          "userChrome.padding.panel" = true;
          "userChrome.padding.popup_panel" = true;
          "userChrome.tab.multi_selected" = true;
          "userChrome.tab.unloaded" = true;
          "userChrome.tab.letters_cleary" = true;
          "userChrome.tab.close_button_at_hover" = true;
          "userChrome.tab.sound_hide_label" = true;
          "userChrome.tab.sound_with_favicons" = true;
          "userChrome.tab.pip" = true;
          "userChrome.tab.container" = true;
          "userChrome.tab.crashed" = true;
          "userChrome.tab.connect_to_window" = true;
          "userChrome.tab.color_like_toolbar" = true;
          "userChrome.tab.lepton_like_padding" = true;
          "userChrome.tab.dynamic_separator" = true;
          "userChrome.tab.newtab_button_like_tab" = true;
          "userChrome.tab.box_shadow" = true;
          "userChrome.tab.bottom_rounded_corner" = true;
          "userChrome.icon.panel_full" = true;
          "userChrome.icon.library" = true;
          "userChrome.icon.panel" = true;
          "userChrome.icon.menu" = true;
          "userChrome.icon.context_menu" = true;
          "userChrome.icon.global_menu" = true;
          "userChrome.icon.global_menubar" = true;
          "userChrome.icon.1-25px_stroke" = true;
          "userChrome.fullscreen.overlap" = true;
          "userChrome.fullscreen.show_bookmarkbar" = true;
          "userContent.player.ui" = true;
          "userContent.player.icon" = true;
          "userContent.player.noaudio" = true;
          "userContent.player.size" = true;
          "userContent.player.click_to_play" = true;
          "userContent.player.animate" = true;
          "userContent.newTab.full_icon" = true;
          "userContent.newTab.animate" = true;
          "userContent.newTab.pocket_to_last" = true;
          "userContent.newTab.searchbar" = true;
          "userContent.page.field_border" = true;
          "userContent.page.illustration" = true;
          "userContent.page.proton_color" = true;
          "userContent.page.dark_mode" = true;
          "userContent.page.proton" = true;
        };
      };
    };
}
