{
  flake.modules.homeManager."apps/firefox/home" =
    {
      pkgs,
      lib,
      config,
      inputs,
      ...
    }:
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
            "ui.key.menuAccessKeyFocuses" = false;
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
          };

          userChrome = ''
            @import url("chrome/userChrome.css");
          '';
          userContent = ''
            @import url("chrome/userContent.css");
          '';
        };
      };
    };
}
