{
  flake.modules.homeManager."desktop/input-method" =
    {
      pkgs,
      inputs,
      lib,
      ...
    }:
    let
      isLinux = pkgs.stdenv.isLinux;
      isDarwin = pkgs.stdenv.isDarwin;
    in
    {
      # Input method (fcitx5 + rime)
      i18n.inputMethod = lib.mkIf isLinux {
        enable = true;
        type = "fcitx5";
        fcitx5.addons = with pkgs; [
          fcitx5-gtk
          fcitx5-rime
          qt6Packages.fcitx5-configtool
          fcitx5-mellow-themes
        ];
      };

      xdg.dataFile."fcitx5/rime" = lib.mkIf isLinux {
        source = inputs.rime-ice;
        recursive = true;
      };

      xdg.configFile."fcitx5/conf/classicui.conf" = lib.mkIf isLinux {
        text = ''
          # 垂直候选列表
          Vertical Candidate List=False
          # 使用鼠标滚轮翻页
          WheelForPaging=True
          # 字体
          Font="Sans 10"
          # 菜单字体
          MenuFont="Sans 10"
          # 托盘字体
          TrayFont="Sans Bold 10"
          # 托盘标签轮廓颜色
          TrayOutlineColor=#000000
          # 托盘标签文本颜色
          TrayTextColor=#ffffff
          # 优先使用文字图标
          PreferTextIcon=True
          # 在图标中显示布局名称
          ShowLayoutNameInIcon=True
          # 使用输入法的语言来显示文字
          UseInputMethodLanguageToDisplayText=True
          # 主题
          Theme=mellow-youlan
          # 深色主题
          DarkTheme=mellow-youlan-dark
          # 跟随系统浅色/深色设置
          UseDarkTheme=True
          # 当被主题和桌面支持时使用系统的重点色
          UseAccentColor=False
          # 在 X11 上针对不同屏幕使用单独的 DPI
          PerScreenDPI=False
          # 固定 Wayland 的字体 DPI
          ForceWaylandDPI=0
          # 在 Wayland 下启用分数缩放
          EnableFractionalScale=True
        '';
      };

      home.file."Library/Rime" = lib.mkIf isDarwin {
        source = inputs.rime-ice;
        recursive = true;
      };

      home.file.".local/share/fcitx5/rime" = lib.mkIf isDarwin {
        source = inputs.rime-ice;
        recursive = true;
      };
    };
}
