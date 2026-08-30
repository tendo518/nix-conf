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
      "network/tailnet"
    ];
    excludeModules = [
      "apps/kitty"
      "apps/mpv"
      "network/mihomo"
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
        chatgpt-desktop
        llm-agents.hermes-desktop
        spotify
        ticktick

        wechat
        qq
        tencent-meeting

        # stats
        drawio
        moonlight-qt
        clash-verge-rev
        keepingyouawake
        zotero

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
