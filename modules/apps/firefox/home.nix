{
  flake.modules.home."apps/firefox/home" =
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
        # configPath = "${config.xdg.configHome}/mozilla/firefox";

        policies = {
          # Privacy & Security
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisableFeedbackCommands = true;
          EnableTrackingProtection = {
            Value = true;
            Cryptomining = true;
            Fingerprinting = true;
            EmailTracking = true;
          };
          HttpsOnlyMode = "enabled";
          Cookies = {
            Behavior = "limit-foreign";
            BehaviorPrivateBrowsing = "limit-foreign";
          };
          Permissions = {
            Camera.BlockNewRequests = true;
            Microphone.BlockNewRequests = true;
            Location.BlockNewRequests = true;
          };
          Proxy.UseProxyForDNS = false;
          PopupBlocking.Default = true;
          SanitizeOnShutdown = {
            Cache = true;
            Downloads = false;
            FormData = false;
            History = false;
          };

          # Updates & Experiments
          DisableAppUpdate = true;
          DisablePocket = true;
          GenerativeAI = {
            Enabled = false;
          };

          # UI & Behavior
          DisplayBookmarksToolbar = false;
          DontCheckDefaultBrowser = true;
          ShowHomeButton = false;
          Homepage.StartPage = "previous-session";
          NewTabPage = false;
          NoDefaultBookmarks = true;
          UseSystemPrintDialog = true;
          NetworkPrediction = false;
          SearchSuggestEnabled = false;
          TranslateEnabled = false;

          # User Messaging (disable annoyances)
          UserMessaging = {
            WhatsNew = false;
            ExtensionRecommendations = false;
            FeatureRecommendations = false;
            UrlbarInterventions = false;
            SkipOnboarding = true;
            MoreFromMozilla = false;
            FirefoxLabs = false;
          };

          # Passwords & Logins
          OfferToSaveLogins = false;
          PasswordManagerEnable = false;

          # Firefox Home
          FirefoxHome = {
            Locked = true;
            Search = true;
            TopSites = false;
            SponsoredTopSites = false;
            Highlights = false;
            Pocket = false;
            SponsoredPocket = false;
            Snippets = false;
            Stories = false;
            SponsoredStories = false;
          };

          # Firefox Suggest
          FirefoxSuggest = {
            WebSuggestions = false;
            SponsoredSuggestions = false;
            ImproveSuggest = false;
            Locked = true;
          };

          # Custom Support Menu
          SupportMenu = {
            Title = "Lan Tian @ Blog";
            URL = "https://lantian.pub";
            AccessKey = "S";
          };
        };

        profiles.default = {
          id = 0;
          name = "default";
          path = "default";
          isDefault = true;

          settings = {
            # UI & Display
            "ui.key.menuAccessKeyFocuses" = false;
            "browser.aboutConfig.showWarning" = false;
            "browser.display.auto_quality_min_font_size" = 0;
            "browser.quitShortcut.disabled" = true;
            "general.autoScroll" = true;
            "sidebar.verticalTabs" = true;
            "toolkit.tabbox.switchByScrolling" = true;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

            # Browser Behavior
            "browser.tabs.insertAfterCurrent" = true;
            "browser.sessionstore.restore_pinned_tabs_on_demand" = true;
            "browser.urlbar.decodeURLsOnCopy" = true;
            "findbar.highlightAll" = true;

            # URL Bar Suggestions
            "browser.search.suggest.enabled" = false;
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

            # Privacy & Security
            "browser.contentblocking.category" = "strict";
            "privacy.userContext.enabled" = true;
            "privacy.userContext.ui.enabled" = true;
            "privacy.spoof_english" = 2;
            "privacy.donottrackheader.enabled" = false;
            "privacy.trackingprotection.enabled" = true;
            "security.ssl.require_safe_negotiation" = true;
            "security.ssl.treat_unsafe_negotiation_as_broken" = true;
            "security.mixed_content.block_active_content" = true;
            "security.mixed_content.block_display_content" = true;
            "dom.security.https_only_mode_send_http_background_request" = false;

            # Accessibility
            "accessibility.force_disabled" = true;
            "accessibility.typeaheadfind" = false;
            "accessibility.typeaheadfind.autostart" = false;

            # Performance & Caching
            "browser.cache.disk.enable" = false;
            "browser.cache.memory.enable" = true;
            "browser.cache.memory.capacity" = 2097152;
            "browser.cache.memory.max_entry_size" = -1;
            "media.memory_cache_max_size" = 16777216;
            "gfx.webrender.all" = true;

            # JavaScript
            "javascript.options.baselinejit.threshold" = 50;

            # Media
            "media.autoplay.default" = 5;
            "media.autoplay.blocking_policy" = 2;
            "media.peerconnection.enabled" = false;
            "media.webspeech.recognition.enable" = false;
            "media.webspeech.synth.enabled" = false;

            # Network
            "network.cookie.thirdparty.sessionOnly" = true;
            "network.buffer.cache.size" = 65535;
            "network.IDN_show_punycode" = true;
            "network.http.referer.XOriginTrimmingPolicy" = 2;
            "network.http.referer.trimmingPolicy" = 1;

            # DOM & Features
            "dom.ipc.forkserver.enable" = true;
            "dom.netinfo.enabled" = false;
            "dom.battery.enabled" = false;
            "dom.vr.enabled" = false;
            "dom.webshare.enabled" = false;
            "dom.text_fragments.create_text_fragment.enabled" = true;

            # Location & Sensors
            "geo.enabled" = false;

            # PDF Viewer
            "pdfjs.enableScripting" = false;
            "pdfjs.firstRun" = false;

            # Beacon API
            "beacon.enabled" = false;

            # Telemetry & Studies
            "app.normandy.enabled" = false;
            "app.normandy.api_url" = "";
            "app.normandy.user_id" = "";
            "app.shield.optoutstudies.enabled" = false;
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.coverage.opt-out" = true;
            "toolkit.coverage.opt-out" = true;

            # Extensions
            "extensions.getAddons.showPane" = false;

            # Use XDG desktop portal for file picker (KDE integration)
            "widget.use-xdg-desktop-portal.file-picker" = 1;

            # Discovery & UI Tours
            "browser.discovery.enabled" = false;
            "browser.uitour.enabled" = false;
          };

          userChrome = ''
            @import url("chrome/userChrome.css");

            #sidebar-main[sidebar-launcher-expanded],
            #sidebar-container[sidebar-launcher-expanded] {
              width: 210px !important;
              min-width: 210px !important;
              max-width: 210px !important;
            }

            #sidebar-launcher-splitter {
              display: none !important;
            }
          '';
          userContent = ''
            @import url("chrome/userContent.css");
          '';
        };
      };
    };
}
