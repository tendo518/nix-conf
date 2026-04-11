# MacBook Pro for development
# Host configuration and module registrations
{ inputs, ... }:
{
  # Host definition
  hosts.darwin.laptop-solar-modoka = {
    modules = [
      "core"
      "system"
      "development"
      "network"
      "hosts/laptop-solar-modoka"
      "desktop/fonts"
      "apps/firefox"
      # "apps/kitty"
      "apps/mpv"
      "apps/vscode"
      "network/tailscale"
    ];
    user = {
      name = "tendo";
      email = "pengwyuan@gmail.com";
      trusted = true;
      sshPubKey = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR"
      ];
      shell = "fish";
      homeStateVersion = "25.05";
    };
    hostPlatform = "aarch64-darwin";
    stateVersion = 6;
  };

  # Darwin system configuration
  flake.modules.darwin."hosts/laptop-solar-modoka" =
    { pkgs, ... }:
    {
      networking.hostName = "laptop-solar-modoka";
      networking.computerName = "laptop-solar-modoka";
      system.defaults.smb.NetBIOSName = "laptop-solar-modoka";

      environment.systemPackages = with pkgs; [
        google-chrome
        obsidian
        skimpdf
        spotify

        inkscape
        darktable

        localsend
        alt-tab-macos
        ticktick

        wechat
        telegram-desktop
        qq

        stats
        ghostty-bin

        moonlight-qt

        antigravity
        bitwarden-desktop
      ];

      # Homebrew
      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = false;
          upgrade = false;
          cleanup = "zap";
        };

        masApps = {
          # Xcode = 497799835;
          # Wechat = 836500024;
          # NeteaseCloudMusic = 944848654;
          # QQ = 451108668;
          # WeCom = 1189898970;
          # TecentMetting = 1484048379;
          # QQMusic = 595615424;
        };

        taps = [
          "deskflow/tap"
        ];

        brews = [ ];

        casks = [
          "dropbox"
          "keepingyouawake"
          "deskflow"
          "tencent-meeting"
          "tencent-docs"
          "clash-verge-rev"
          "sfm"
        ];
      };
    };

  flake.modules.homeManager."hosts/laptop-solar-modoka" =
    {
      inputs,
      config,
      pkgs,
      ...
    }:
    {
      imports = [ ];

      # Texlive for Chinese/English writing with IEEE templates
      home.packages = [
        (pkgs.texlive.combine {
          inherit (pkgs.texlive)
            scheme-medium
            collection-langchinese
            latexmk
            ieeetran
            biblatex
            biber
            ;
        })
      ];

      home.file."Library/Rime" = {
        source = inputs.rime-ice;
        recursive = true;
      };

      home.file.".local/share/fcitx5/rime" = {
        source = inputs.rime-ice;
        recursive = true;
      };

      xdg = {
        enable = true;
        cacheHome = "${config.home.homeDirectory}/.cache";
        configHome = "${config.home.homeDirectory}/.config";
        dataHome = "${config.home.homeDirectory}/.local/share";
        stateHome = "${config.home.homeDirectory}/.local/state";
      };
    };
}
