{
  flake.modules.nixos."apps/chrome" = { pkgs, ... }: {
    # https://chromeenterprise.google/policies/
    programs.chromium = {
      enable = true;
      enablePlasmaBrowserIntegration = true;

      extraOpts = {
        # Privacy & Security
        MetricsReportingEnabled = false;
        AdsSettingForIntrusiveAdsSites = 2;
        AdvancedProtectionAllowed = true;
        InsecureFormsWarningsEnabled = true;
        EncryptedClientHelloEnabled = false;
        BuiltInDnsClientEnabled = false;

        # Autofill & Payments
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        PaymentMethodQueryEnabled = false;
        ImportAutofillFormData = false;

        # Password Manager
        PasswordManagerEnabled = false;
        ImportSavedPasswords = false;

        # Browser Behavior
        BackgroundModeEnabled = false;
        DefaultBrowserSettingEnabled = false;
        SitePerProcess = true;
        HighEfficiencyModeEnabled = false;

        # Startup, Home & New Tab
        ShowHomeButton = false;
        ImportHomepage = false;

        # Bookmarks & History
        BookmarkBarEnabled = false;
        ImportBookmarks = false;
        ImportHistory = false;

        # Search & Suggestions
        SearchSuggestEnabled = true;
        ImportSearchEngine = false;

        # Media & Autoplay
        AutoplayAllowed = false;
        EnableMediaRouter = false;
        MediaRecommendationsEnabled = false;

        # Features & Integrations
        AssistantWebEnabled = false;
        BrowserLabsEnabled = false;
        ClickToCallEnabled = false;
        LensRegionSearchEnabled = false;
        SideSearchEnabled = false;
        ShoppingListEnabled = false;
        TranslateEnabled = false;

        # Accessibility
        AccessibilityImageLabelsEnabled = false;

        # UI
        ShowFullUrlsInAddressBar = true;
        PromotionalTabsEnabled = false;

        # Spell Check
        SpellCheckServiceEnabled = false;
        SpellcheckEnabled = false;

        # Network
        NetworkPredictionOptions = 2;
        BrowserNetworkTimeQueriesEnabled = false;

        # Printing
        CloudPrintProxyEnabled = false;

        # Clear browsing data on exit (disabled)
        # ClearBrowsingDataOnExitList = [
        #   "browsing_history"
        #   "download_history"
        #   "cached_images_and_files"
        #   "password_signin"
        #   "autofill"
        #   "site_settings"
        # ];
      };
    };
  };
}