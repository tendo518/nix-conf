{
  flake.modules.darwin."desktop/input-method" =
    { pkgs, lib, ... }:
    let
      source = "${pkgs.fcitx5-macos}/Applications/Fcitx5.app";
      destination = "/Library/Input Methods/Fcitx5.app";
      move = "${pkgs.coreutils}/bin/mv";
    in
    {
      # Install only the app bundle. macOS owns input-source registration and
      # the user enables Fcitx5 from System Settings; doing that automatically
      # would modify per-user input preferences from a system activation.
      system.activationScripts.postActivation.text = lib.mkAfter ''
        # Leave the live input method alone when the store bundle is unchanged.
        if ! /usr/bin/diff -qr --no-dereference ${lib.escapeShellArg source} ${lib.escapeShellArg destination} >/dev/null 2>&1; then
          (
            /bin/mkdir -p "/Library/Input Methods"
            staging_root="$(/usr/bin/mktemp -d "/Library/Input Methods/.fcitx5-nix-staging.XXXXXX")"
            trap '/bin/rm -rf "$staging_root"' EXIT
            staging="$staging_root/Fcitx5.app"
            /usr/bin/ditto ${lib.escapeShellArg source} "$staging"
            /usr/bin/codesign --verify --deep --strict "$staging"

            if [[ -e ${lib.escapeShellArg destination} || -L ${lib.escapeShellArg destination} ]]; then
              # Keep the registered bundle path present throughout the upgrade.
              ${move} --exchange --no-copy -T "$staging" ${lib.escapeShellArg destination}
              echo "Fcitx5 updated. Choose Restart in the Fcitx5 menu to load the update." >&2
            else
              ${move} --no-copy --update=none-fail -T "$staging" ${lib.escapeShellArg destination}
              echo "Fcitx5 installed. Log out and back in, then add it in System Settings > Keyboard > Input Sources." >&2
            fi
          )
        fi
      '';
    };

  flake.modules.homeNixOS."desktop/input-method" =
    {
      pkgs,
      inputs,
      ...
    }:
    {
      # Input method (fcitx5 + rime)
      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5.addons = with pkgs; [
          fcitx5-gtk
          fcitx5-rime
          qt6Packages.fcitx5-configtool
          fcitx5-mellow-themes
        ];
      };

      xdg.dataFile."fcitx5/rime" = {
        source = inputs.rime-ice;
        recursive = true;
      };

      # ClassicUI reads themes from $XDG_DATA_HOME/fcitx5/themes as well as from
      # the data dirs the fcitx5 wrapper exports; link them here so the theme is
      # found no matter which fcitx5 binary ends up running.
      xdg.dataFile."fcitx5/themes" = {
        source = "${pkgs.fcitx5-mellow-themes}/share/fcitx5/themes";
        recursive = true;
      };

      xdg.configFile."fcitx5/conf/classicui.conf".text = ''
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

  flake.modules.homeDarwin."desktop/input-method" =
    {
      inputs,
      ...
    }:
    {
      home.file."Library/Rime" = {
        source = inputs.rime-ice;
        recursive = true;
      };

      home.file.".local/share/fcitx5/rime" = {
        source = inputs.rime-ice;
        recursive = true;
      };
    };
}
