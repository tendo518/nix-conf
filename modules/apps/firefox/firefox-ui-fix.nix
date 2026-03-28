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
    };
}
