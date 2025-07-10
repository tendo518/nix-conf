{
  flake.modules.nixos."apps/gaming" =
    { pkgs, ... }:
    {
      # https://wiki.archlinux.org/title/steam
      # Games installed by Steam works fine on NixOS, no other configuration needed.
      programs.steam = {
        # Some location that should be persistent:
        #   ~/.local/share/Steam - The default Steam install location
        #   ~/.local/share/Steam/steamapps/common - The default Game install location
        #   ~/.steam/root        - A symlink to ~/.local/share/Steam
        #   ~/.steam             - Some Symlinks & user info
        enable = true;
        # https://github.com/ValveSoftware/gamescope
        # Run a GameScope driven Steam session from your display-manager
        # fix resolution upscaling and stretched aspect ratios
        gamescopeSession.enable = true;
        # https://github.com/Winetricks/winetricks
        # Whether to enable protontricks, a simple wrapper for running Winetricks commands for Proton-enabled games.
        protontricks.enable = true;
        # Whether to enable Load the extest library into Steam, to translate X11 input events to uinput events (e.g. for using Steam Input on Wayland) .
        extest.enable = true;
        # Defaults to system fonts, but could be overridden to use other fonts
        #  — useful for users who would like to customize CJK fonts used in Steam.
        #  According to the upstream issue, Steam only follows the per-user
        #  fontconfig configuration.
        #fontPackages = [
        #  pkgs.wqy_zenhei # Need by steam for Chinese
        # ];
      };

      environment.systemPackages = with pkgs; [
        # https://github.com/flightlessmango/MangoHud
        # a simple overlay program for monitoring FPS, temperature, CPU and GPU load, and more.
        mangohud
        # a GUI game launcher for Steam/GoG/Epic
        protonup-rs
        # https://usebottles.com
        # a GUI Wine prefix manager
        (bottles.override { removeWarningPopup = true; })

        # wineWow64Packages.wayland
        # winetricks

        ffmpeg-full
        # gst_all_1.gstreamer # bin: gst-play-1.0, gst-launch-1.0, etc.
        # gst_all_1.gstreamer.out # out: core plugins (typefind, coreelements, etc.)
        # gst_all_1.gst-plugins-base
        # gst_all_1.gst-plugins-good
        # gst_all_1.gst-plugins-bad
        # gst_all_1.gst-plugins-ugly
        # gst_all_1.gst-libav
        # gst_all_1.gst-vaapi
      ];

      # Optimise Linux system performance on demand
      # https://github.com/FeralInteractive/GameMode
      # https://wiki.archlinux.org/title/Gamemode
      #
      # Usage:
      #   1. For games/launchers which integrate GameMode support:
      #      https://github.com/FeralInteractive/GameMode#apps-with-gamemode-integration
      #      simply running the game will automatically activate GameMode.
      programs.gamescope = {
        enable = true;
        capSysNice = false;
      };
      # GStreamer plugin discovery:
      # - GST_PLUGIN_PATH: 32-bit plugins only, scanned first by any
      #   process. 64-bit apps skip these (ELFCLASS32) and fall back to
      #   GST_PLUGIN_SYSTEM_PATH_1_0. Proton/Wine's 32-bit gstreamer finds
      #   them immediately (Proton overrides SYSTEM_PATH with its own).
      # - GST_PLUGIN_SYSTEM_PATH_1_0: 64-bit system path + 32-bit paths,
      #   replaces the default scan. 64-bit apps find valid plugins in the
      #   system path; Proton overrides this entirely for game processes.
      # environment.sessionVariables.GST_PLUGIN_PATH =
      #   let
      #     gst32 = pkgs.pkgsi686Linux.gst_all_1;
      #   in
      #   lib.makeSearchPath "lib/gstreamer-1.0" [
      #     gst32.gstreamer.out
      #     gst32.gst-plugins-base
      #     gst32.gst-plugins-good
      #     gst32.gst-plugins-bad
      #     gst32.gst-plugins-ugly
      #     gst32.gst-libav
      #     gst32.gst-vaapi
      #   ];
      # environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 =
      #   let
      #     gst32 = pkgs.pkgsi686Linux.gst_all_1;
      #   in
      #   "/run/current-system/sw/lib/gstreamer-1.0"
      #   + ":"
      #   + lib.makeSearchPath "lib/gstreamer-1.0" [
      #     gst32.gstreamer.out
      #     gst32.gst-plugins-base
      #     gst32.gst-plugins-good
      #     gst32.gst-plugins-bad
      #     gst32.gst-plugins-ugly
      #     gst32.gst-libav
      #     gst32.gst-vaapi
      #   ];
      # environment.sessionVariables.BOTTLES_USE_SYSTEM_GSTREAMER = 1;
    };

}
