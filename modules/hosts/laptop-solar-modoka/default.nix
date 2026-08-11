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
      "agents"
      "network"
      "hosts/laptop-solar-modoka"
      "desktop/fonts"
      "desktop/input-method"
      "apps"
      "network/tailscale"
    ];
    excludeModules = [
      "apps/kitty"
      "apps/mpv"
    ];
    user = {
      name = "tendo";
      email = "pengwyuan@gmail.com";
      trusted = true;
      sshPubKey = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR"
      ];
      shell = "fish";
      homeStateVersion = "25.11";
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
        telegram-desktop
        iina
        google-chrome
        obsidian
        skimpdf
        deskflow
        codex-desktop
        spotify
        # zed-editor  # broken again and again in macos

        ticktick

        wechat
        qq

        stats
        # ghostty-bin

        moonlight-qt
        clash-verge-rev

      ];
    };

  flake.modules.home."hosts/laptop-solar-modoka" =
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
        pkgs.texliveFull
        pkgs.pdf2svg
        pkgs.ghostscript
        # (pkgs.texlive.combine {
        #   inherit (pkgs.texlive)
        #     scheme-medium
        #     collection-langchinese
        #     latexmk
        #     ieeetran
        #     biblatex
        #     biber
        #     ;
        # })
      ];

      xdg = {
        enable = true;
        cacheHome = "${config.home.homeDirectory}/.cache";
        configHome = "${config.home.homeDirectory}/.config";
        dataHome = "${config.home.homeDirectory}/.local/share";
        stateHome = "${config.home.homeDirectory}/.local/state";
      };
    };
}
