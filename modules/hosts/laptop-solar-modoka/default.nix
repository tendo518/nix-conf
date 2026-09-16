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
        llm-agents.chatgpt
        llm-agents.hermes-desktop
        # spotify  # 这玩意发布不带版本的，上游只能 web.archive.org 打包
        ticktick

        wechat
        qq
        tencent-meeting
        workbuddy-cn

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
