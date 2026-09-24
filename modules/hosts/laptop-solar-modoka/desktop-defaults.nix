{
  flake.modules.darwin."hosts/laptop-solar-modoka/desktop-defaults" = _: {
    system.defaults = {
      dock = {
        autohide = false; # Dock 常驻，不自动隐藏
        show-recents = false; # Dock 中不显示“最近使用”
        minimize-to-application = true; # 最小化窗口进应用图标
        mru-spaces = false; # 不按最近使用自动重排 Space

        wvous-tl-corner = 2; # 左上角: 调度中心
        wvous-tr-corner = 1;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;

        expose-group-apps = false; # 调度中心: 窗口不按应用分组
      };

      finder = {
        _FXShowPosixPathInTitle = true; # 窗口标题显示完整 POSIX 路径
        AppleShowAllExtensions = true; # 显示文件扩展名
        FXEnableExtensionChangeWarning = false; # 修改扩展名时不弹窗警告
        QuitMenuItem = true; # 菜单栏增加“退出 Finder”
        ShowPathbar = true; # 始终显示窗口底部路径栏
        ShowStatusBar = true; # 始终显示窗口底部状态栏
        FXPreferredViewStyle = "icnv"; # 默认视图: 图标视图 (Nlsv=列表 clmv=列 gdlv=画廊)
        AppleShowAllFiles = false; # 不显示隐藏文件 (可随时 Cmd+Shift+. 切换)
        NewWindowTarget = "Home"; # 新 Finder 窗口默认打开主目录
        _FXSortFoldersFirstOnDesktop = true; # 桌面排序时文件夹排在文件前面
        ShowExternalHardDrivesOnDesktop = false; # 桌面不显示外置硬盘
        ShowHardDrivesOnDesktop = false; # 桌面不显示内置磁盘
        ShowMountedServersOnDesktop = false; # 桌面不显示已挂载的网络共享
        ShowRemovableMediaOnDesktop = false; # 桌面不显示可移动媒体
        _FXSortFoldersFirst = true; # 文件夹排在文件前面
        FXDefaultSearchScope = "SCcf"; # 默认搜索范围: 当前文件夹
      };

      controlcenter = {
        BatteryShowPercentage = true; # 菜单栏电池显示百分比
      };

      trackpad = {
        Clicking = true; # 开启轻点点击
        TrackpadRightClick = true; # 双指轻点 = 右键
        TrackpadThreeFingerDrag = false; # 禁用三指拖动窗口
        TrackpadThreeFingerTapGesture = 0; # 三指轻点: 0=无动作 (1=显示桌面 2=智能缩放)
      };

      NSGlobalDomain = {
        "com.apple.swipescrolldirection" = false; # 关闭自然滚动
        "com.apple.sound.beep.feedback" = 0; # 静音系统错误提示音
        AppleKeyboardUIMode = 3; # 输入法菜单只列出当前应用的输入法 (1=全局)
        ApplePressAndHoldEnabled = true; # 长按按键弹出变音符号/字符面板
        InitialKeyRepeat = 15; # 首次重复前的按键次数 (越小越快)
        KeyRepeat = 3; # 按键重复速率 (越小越快)
        NSAutomaticCapitalizationEnabled = false; # 关闭句首自动大写
        NSAutomaticDashSubstitutionEnabled = false; # 关闭自动破折号
        NSAutomaticPeriodSubstitutionEnabled = false; # 关闭自动省略号 (…)
        NSAutomaticQuoteSubstitutionEnabled = false; # 关闭智能引号
        NSAutomaticSpellingCorrectionEnabled = false; # 关闭自动拼写纠正
        NSAutomaticWindowAnimationsEnabled = false; # 关闭窗口打开/关闭动画
        NSDocumentSaveNewDocumentsToCloud = false; # 新文档默认保存到本机
        NSTableViewDefaultSizeMode = 1; # Finder 侧栏使用小图标
        AppleSpacesSwitchOnActivate = true; # 点击 Dock 应用时切换到其所在 Space
        NSNavPanelExpandedStateForSaveMode = true; # 保存对话框: 侧边栏默认展开
        NSNavPanelExpandedStateForSaveMode2 = true; # 打开对话框: 侧边栏默认展开
      };

      screencapture = {
        type = "png"; # 截图格式: PNG
        disable-shadow = true; # 窗口截图不带阴影
        show-thumbnail = false; # 截图后不显示右下角缩略图
      };

      WindowManager = {
        EnableStandardClickToShowDesktop = false; # 禁用“点空白处显示桌面”
        StandardHideDesktopIcons = false; # 显示桌面图标
        HideDesktop = false; # 台前调度: 不自动隐藏桌面
        StageManagerHideWidgets = false; # 台前调度: 显示小组件
        StandardHideWidgets = false; # 桌面显示小组件
      };

      screensaver = {
        askForPassword = true; # 屏保/锁屏后需要密码
        askForPasswordDelay = 5; # 恢复后 5 秒才开始要求密码
      };

      CustomUserPreferences = {
        # nix-darwin 未声明 key 的全局项 (写入 .GlobalPreferences, 与 NSGlobalDomain 同域)
        NSGlobalDomain = {
          WebKitDeveloperExtras = true; # 启用 WebKit 系应用的“开发”菜单
          AppleActionOnDoubleClick = "Fill"; # 双击标题栏: 填充 (Maximize=缩放 Minimize=最小化 None=无操作)
          NSWindowResizeGesturesEnabled = true; # 拖拽标题栏/窗口边缘直接缩放窗口
          AppleShowAllApplications = true; # Cmd+Tab 显示所有 Space 中的应用
          AppleAllowPastingPasswordsFromClipboard = false; # 向密码框粘贴时不弹“允许粘贴密码?”
        };

        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true; # 网络共享不写 .DS_Store
          DSDontWriteUSBStores = true; # USB/可移动介质不写 .DS_Store
        };

        "com.apple.AdLib".allowApplePersonalizedAdvertising = false; # 关闭 Apple 个性化广告
        "com.apple.ImageCapture".disableHotPlug = true; # 插入摄像头/USB 设备不自动打开“图像捕捉”
      };

      loginwindow = {
        GuestEnabled = false; # 禁用访客账户
        SHOWFULLNAME = true; # 登录界面显示全名 (而非仅名字)
      };
    };

    system.keyboard = {
      enableKeyMapping = true; # 启用按键重映射
      remapCapsLockToControl = false; # Caps Lock 不映射为 Control
      remapCapsLockToEscape = true; # Caps Lock 映射为 Escape
      swapLeftCommandAndLeftAlt = false; # 不交换左 Cmd 与左 Option
    };

  };
}
