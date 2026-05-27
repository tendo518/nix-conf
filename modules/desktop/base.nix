{
  flake.modules.nixos."desktop/base" =
    {
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        libinput
        wayland-utils
        wl-clipboard
        libinput
        pavucontrol
        xlsclients
        libnotify # for notify-send command in path

        # GPU related
        libva-utils # vainfo
        vulkan-tools # vulkaninfo
      ];

      # Enable Wayland for electron apps packaged by Nix
      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      # Common desktop services and settings
      services.dbus.implementation = "broker";
      services.upower.enable = true;
      services.printing.enable = true;
      services.gnome.gnome-keyring.enable = true;
      networking.networkmanager.enable = true;
      programs.dconf.enable = true;

      # Sound
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };

      # Bluetooth
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      # Keyboard layout
      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      # flatpak
      services.flatpak.enable = false;

      # improve desktop responsiveness when updating the system
      nix.daemonCPUSchedPolicy = "idle";

      # Display manager (login screen)
      services.displayManager.sddm = {
        enable = true;
        enableHidpi = true;
        wayland.enable = true;
      };

      # XDG desktop portal
      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
      };

      # Common MIME type associations
      xdg.mime.defaultApplications = {
        # Browser
        "text/html" = "firefox.desktop";
        "application/xhtml+xml" = "firefox.desktop";
        "application/xml" = "firefox.desktop";
        "application/xhtml_xml" = "firefox.desktop";
        "application/rdf+xml" = "firefox.desktop";
        "application/rss+xml" = "firefox.desktop";
        "text/xml" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/ftp" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";

        # Text / code editor
        "text/plain" = "code.desktop";
        "text/css" = "code.desktop";
        "application/json" = "code.desktop";
        "application/x-shellscript" = "code.desktop";
        "application/x-python" = "code.desktop";

        # Media player
        "audio/*" = "mpv.desktop";
        "video/*" = "mpv.desktop";
        "audio/mp3" = "mpv.desktop";
        "audio/mp4" = "mpv.desktop";
        "video/mp4" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";

        # Terminal
        "application/x-terminal-emulator" = "kitty.desktop";
      };

      xdg.mime.removedAssociations = {
        "application/pdf" = "firefox.desktop";
      };
    };
  flake.modules.homeManager."desktop/base" =

    {
      config,
      pkgs,
      inputs,
      ...
    }:
    {
      home.packages = with pkgs; [
        xdg-utils # provides cli tools such as `xdg-mime` `xdg-open`
        xdg-user-dirs
      ];

      # XDG base directory env vars are set in core/xdg
      xdg.userDirs = {
        enable = true;
        createDirectories = true;
        setSessionVariables = true;
        extraConfig = {
          SCREENSHOTS = "${config.xdg.userDirs.pictures}/Screenshots";
        };
      };

      # GTK / dconf defaults for non-GNOME/Plasma desktops
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          icon-theme = "Adwaita";
        };
      };

      # Default terminal emulator
      xdg.terminal-exec = {
        enable = true;
        settings = {
          default = [ "kitty.desktop" ];
        };
      };

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
}
