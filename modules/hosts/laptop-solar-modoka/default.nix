# Darwin host modules
_: {
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
        imagemagick

      ];
    };

  flake.modules.home."hosts/laptop-solar-modoka" =
    {
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
