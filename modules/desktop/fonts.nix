let
  sharedPackages =
    pkgs: with pkgs; [
      # icon fonts
      material-design-icons
      noto-fonts
      noto-fonts-color-emoji
      # typst have some problem supporting variable font
      # use static version until they fix this:
      # https://github.com/typst/typst/issues/185
      noto-fonts-cjk-sans-static
      noto-fonts-cjk-serif-static
      font-awesome
      sarasa-gothic
      lxgw-wenkai
      lxgw-neoxihei
      inriafonts
      newcomputermodern

      # monospace font with Chinese + Nerd Font support
      maple-mono.NF-CN
      # iosevka-slab
      # iosevka-term
      fira-code
      jetbrains-mono
      hack-font
      nerd-fonts.symbols-only
    ];
in
{
  flake.modules.nixos."desktop/fonts" =
    { pkgs, ... }:
    {
      fonts.packages = sharedPackages pkgs;

      fonts.fontconfig = {
        enable = true;
        defaultFonts = {
          serif = [
            "Noto Serif"
            "Noto Serif CJK SC"
            "Noto Color Emoji"
          ];
          sansSerif = [
            "Noto Sans"
            "Noto Sans CJK SC"
            "Noto Color Emoji"
          ];
          monospace = [
            "Maple Mono NF CN"
            "Symbols Nerd Font"
            "Sarasa Mono SC"
            "Noto Color Emoji"
          ];
          emoji = [ "Noto Color Emoji" ];
        };
        localConf = ''
          <?xml version='1.0'?>
          <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
            <fontconfig>
              <!-- 默认 emoji 字体。 -->
              <match target="pattern">
                  <test name="family" qual="any">
                      <string>emoji</string>
                  </test>
                  <edit name="family" mode="prepend" binding="same">
                      <string>Noto Color Emoji</string>
                  </edit>
              </match>
              <!-- 替换 Apple Color Emoji 字体。 -->
              <match target="pattern">
                  <test name="family" qual="any">
                      <string>Apple Color Emoji</string>
                  </test>
                  <edit name="family" mode="assign" binding="same">
                      <string>Noto Color Emoji</string>
                  </edit>
              </match>
        ''
        + ''
          <!-- 让 Noto CJK 在不同语言下采用不同的汉字变体。 -->
          <match target="pattern">
              <test name="lang">
                  <string>zh-HK</string>
              </test>
              <test name="family" qual="any">
                  <string>Noto Sans CJK SC</string>
              </test>
              <edit name="family" mode="assign" binding="same">
                  <string>Noto Sans CJK HK</string>
              </edit>
          </match>
          <match target="pattern">
              <test name="lang">
                  <string>zh-HK</string>
              </test>
              <test name="family" qual="any">
                  <string>Noto Serif CJK SC</string>
              </test>
              <edit name="family" mode="assign" binding="same">
                  <string>Noto Serif CJK HK</string>
              </edit>
          </match>
          <match target="pattern">
              <test name="lang">
                  <string>zh-HK</string>
              </test>
              <test name="family" qual="any">
                  <string>Noto Sans Mono CJK SC</string>
              </test>
              <edit name="family" mode="assign" binding="same">
                  <string>Noto Sans Mono CJK HK</string>
              </edit>
          </match>
          <match target="pattern">
              <test name="lang">
                  <string>zh-TW</string>
              </test>
              <test name="family" qual="any">
                  <string>Noto Sans CJK SC</string>
              </test>
              <edit name="family" mode="assign" binding="same">
                  <string>Noto Sans CJK TW</string>
              </edit>
          </match>
          <match target="pattern">
              <test name="lang">
                  <string>zh-TW</string>
              </test>
              <test name="family" qual="any">
                  <string>Noto Serif CJK SC</string>
              </test>
              <edit name="family" mode="assign" binding="same">
                  <string>Noto Serif CJK TC</string>
              </edit>
          </match>
          <match target="pattern">
              <test name="lang">
                  <string>zh-TW</string>
              </test>
              <test name="family" qual="any">
                  <string>Noto Sans Mono CJK SC</string>
              </test>
              <edit name="family" mode="assign" binding="same">
                  <string>Noto Sans Mono CJK TC</string>
              </edit>
          </match>
          <match target="pattern">
              <test name="lang">
                  <string>ja</string>
              </test>
              <test name="family" qual="any">
                  <string>Noto Sans CJK SC</string>
              </test>
              <edit name="family" mode="assign" binding="same">
                  <string>Noto Sans CJK JP</string>
              </edit>
          </match>
          <match target="pattern">
              <test name="lang">
                  <string>ja</string>
              </test>
              <test name="family" qual="any">
                  <string>Noto Serif CJK SC</string>
              </test>
              <edit name="family" mode="assign" binding="same">
                  <string>Noto Serif CJK JP</string>
              </edit>
          </match>
          <match target="pattern">
              <test name="lang">
                  <string>ja</string>
              </test>
              <test name="family" qual="any">
                  <string>Noto Sans Mono CJK SC</string>
              </test>
              <edit name="family" mode="assign" binding="same">
                  <string>Noto Sans Mono CJK JP</string>
              </edit>
          </match>
          <match target="pattern">
              <test name="lang">
                  <string>ko</string>
              </test>
              <test name="family">
                  <string>Noto Sans CJK SC</string>
              </test>
              <edit name="family" mode="assign" binding="same">
                  <string>Noto Sans CJK KR</string>
              </edit>
          </match>
          <match target="pattern">
              <test name="lang">
                  <string>ko</string>
              </test>
              <test name="family" qual="any">
                  <string>Noto Serif CJK SC</string>
              </test>
              <edit name="family" mode="assign" binding="same">
                  <string>Noto Serif CJK KR</string>
              </edit>
          </match>
          <match target="pattern">
              <test name="lang">
                  <string>ko</string>
              </test>
              <test name="family" qual="any">
                  <string>Noto Sans Mono CJK SC</string>
              </test>
              <edit name="family" mode="assign" binding="same">
                  <string>Noto Sans Mono CJK KR</string>
              </edit>
          </match>
        ''
        + ''
            <!-- Web Fonts -->
            <match target="pattern">
                <test qual="any" name="family">
                    <string>ui-monospace</string>
                </test>
                <edit name="family" mode="assign" binding="same">
                    <string>monospace</string>
                </edit>
            </match>

            <match target="pattern">
                <test qual="any" name="family">
                    <string>ui-sans-serif</string>
                </test>
                <edit name="family" mode="assign" binding="same">
                    <string>sans-serif</string>
                </edit>
            </match>

            <match target="pattern">
                <test qual="any" name="family">
                    <string>ui-serif</string>
                </test>
                <edit name="family" mode="assign" binding="same">
                    <string>serif</string>
                </edit>
            </match>

            <match target="pattern">
                <test qual="any" name="family">
                    <string>-apple-system</string>
                </test>
                <edit name="family" mode="assign" binding="same">
                    <string>sans-serif</string>
                </edit>
            </match>
          </fontconfig>
        '';
        hinting.enable = false;
        # hinting.style = "slight";
        antialias = true;
        subpixel = {
          rgba = "rgb"; # IPS 屏幕使用 rgb 排列
        };
      };
    };
  flake.modules.darwin."desktop/fonts" =
    { pkgs, ... }:
    {
      fonts.packages = sharedPackages pkgs;
    };
}
