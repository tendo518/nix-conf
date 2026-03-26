{
  flake.modules.homeManager."apps/firefox-home" =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      firefox-ui-fix-src = pkgs.fetchFromGitHub {
        owner = "black7375";
        repo = "Firefox-UI-Fix";
        rev = "v8.7.5";
        hash = "sha256-IfR5pI+tpP5RfoTqO6Vgnbc5nADqSA4gg+9csz/+pO0=";
      };

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
        if pkgs.stdenv.isDarwin then
          "Library/Application Support/Firefox/Profiles/default"
        else
          ".mozilla/firefox/default";
    in
    {
      programs.firefox = {
        enable = true;
        package = pkgs.firefox;

        policies = {
          DisplayBookmarksToolbar = false;
          OfferToSaveLogins = false;
          PasswordManagerEnable = false;
          DisableAppUpdate = true;
          DisableFeedbackCommands = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableTelemetry = true;
          DontCheckDefaultBrowser = true;

          Cookies = {
            Behavior = "limit-foreign";
            BehaviorPrivateBrowsing = "limit-foreign";
          };

          EnableTrackingProtection = {
            Value = true;
            Cryptomining = true;
            Fingerprinting = true;
            EmailTracking = true;
          };

          FirefoxHome = {
            Locked = true;
            TopSites = false;
            SponsoredTopSites = false;
            Highlights = false;
            Pocket = false;
            SponsoredPocket = false;
            Snippets = false;
            Stories = false;
            SponsoredStories = false;
          };

          FirefoxSuggest = {
            WebSuggestions = false;
            SponsoredSuggestions = false;
            ImproveSuggest = false;
            Locked = true;
          };

          Homepage.StartPage = "previous-session";
          HttpsOnlyMode = "enabled";
          NetworkPrediction = false;
          NewTabPage = false;
          NoDefaultBookmarks = true;
          PopupBlocking.Default = true;
          Proxy.UseProxyForDNS = false;

          Permissions = {
            Camera.BlockNewRequests = true;
            Microphone.BlockNewRequests = true;
            Location.BlockNewRequests = true;
          };

          SanitizeOnShutdown = {
            Cache = true;
          };

          SearchSuggestEnabled = false;
          TranslateEnabled = false;

          UserMessaging = {
            ExtensionRecommendations = false;
            FeatureRecommendations = false;
            UrlbarInterventions = false;
            SkipOnboarding = true;
            MoreFromMozilla = false;
            FirefoxLabs = false;
          };
          GenerativeAI = {
            Enabled = false;
          };
        };

        profiles.default = {
          id = 0;
          name = "default";
          isDefault = true;

          settings = {
            "browser.aboutConfig.showWarning" = false;

            "accessibility.force_disabled" = true;
            "accessibility.typeaheadfind" = false;
            "accessibility.typeaheadfind.autostart" = false;

            "beacon.enabled" = false;
            "browser.cache.disk.enable" = false;
            "browser.cache.memory.enable" = true;
            "browser.cache.memory.capacity" = 2097152;
            "browser.cache.memory.max_entry_size" = -1;
            "browser.contentblocking.category" = "strict";
            "browser.discovery.enabled" = false;
            "browser.display.auto_quality_min_font_size" = 0;
            "browser.quitShortcut.disabled" = true;
            "browser.search.suggest.enabled" = false;
            "browser.sessionstore.restore_pinned_tabs_on_demand" = true;
            "browser.tabs.insertAfterCurrent" = true;
            "browser.uitour.enabled" = false;
            "browser.urlbar.decodeURLsOnCopy" = true;
            "browser.urlbar.quicksuggest.enabled" = false;
            "browser.urlbar.suggest.quickactions" = false;
            "browser.urlbar.suggest.addons" = false;
            "browser.urlbar.suggest.clipboard" = false;
            "browser.urlbar.suggest.engines" = false;
            "browser.urlbar.suggest.remotetab" = false;
            "browser.urlbar.suggest.weather" = false;
            "browser.urlbar.suggest.yelp" = false;
            "browser.urlbar.suggest.topsites" = false;
            "browser.urlbar.suggest.trending" = false;
            "browser.urlbar.resultMenu.keyboardAccessible" = false;
            "browser.urlbar.autoFill.adaptiveHistory.enabled" = true;
            "browser.urlbar.update2.engineAliasRefresh" = true;

            "dom.ipc.forkserver.enable" = true;
            "dom.netinfo.enabled" = false;
            "dom.battery.enabled" = false;
            "dom.vr.enabled" = false;
            "dom.webshare.enabled" = false;
            "dom.security.https_only_mode_send_http_background_request" = false;
            "dom.text_fragments.create_text_fragment.enabled" = true;

            "general.autoScroll" = true;
            "geo.enabled" = false;
            "gfx.webrender.all" = true;

            "javascript.options.baselinejit.threshold" = 50;

            "media.autoplay.default" = 5;
            "media.autoplay.blocking_policy" = 2;
            "media.memory_cache_max_size" = 16777216;
            "media.peerconnection.enabled" = false;
            "media.webspeech.recognition.enable" = false;
            "media.webspeech.synth.enabled" = false;

            "network.cookie.thirdparty.sessionOnly" = true;
            "network.buffer.cache.size" = 65535;
            "network.IDN_show_punycode" = true;
            "network.http.referer.XOriginTrimmingPolicy" = 2;
            "network.http.referer.trimmingPolicy" = 1;

            "pdfjs.enableScripting" = false;
            "pdfjs.firstRun" = false;
            "privacy.userContext.enabled" = true;
            "privacy.userContext.ui.enabled" = true;

            "security.ssl.require_safe_negotiation" = true;

            "app.normandy.enabled" = false;
            "app.normandy.api_url" = "";
            "app.normandy.user_id" = "";
            "app.shield.optoutstudies.enabled" = false;
            "extensions.getAddons.showPane" = false;
            "findbar.highlightAll" = true;
            "privacy.spoof_english" = 2;
            "privacy.donottrackheader.enabled" = false;
            "privacy.trackingprotection.enabled" = true;
            "security.mixed_content.block_active_content" = true;
            "security.mixed_content.block_display_content" = true;
            "security.ssl.treat_unsafe_negotiation_as_broken" = true;
            "toolkit.telemetry.coverage.opt-out" = true;
            "toolkit.tabbox.switchByScrolling" = true;
            "toolkit.telemetry.enabled" = false;
            "toolkit.coverage.opt-out" = true;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

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

          userChrome = ''
            @import url("chrome/userChrome.css");
          '';
          userContent = ''
            @import url("chrome/userContent.css");
          '';
        };
      };

      home.file = {
        "${firefoxProfilePath}/chrome/userChrome.css".source =
          "${firefox-ui-fix-chrome}/chrome/userChrome.css";
        "${firefoxProfilePath}/chrome/userContent.css".source =
          "${firefox-ui-fix-chrome}/chrome/userContent.css";
        "${firefoxProfilePath}/chrome/css".source = "${firefox-ui-fix-chrome}/chrome/css";
        "${firefoxProfilePath}/chrome/icons".source = "${firefox-ui-fix-chrome}/chrome/icons";
        "${firefoxProfilePath}/chrome/theme".source = "${firefox-ui-fix-chrome}/chrome/theme";
      };
    };
}
