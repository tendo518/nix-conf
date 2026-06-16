{
  flake.modules.home."apps/kitty" =
    { pkgs, ... }:
    {
      # Kitty
      programs.kitty = {
        enable = true;
        settings = {
          # font
          font_family = "monospace";
          bold_font = "auto";
          italic_font = "auto";
          bold_italic_font = "auto";
          font_size = if pkgs.stdenv.isDarwin then 14.0 else 12.0;

          # misc
          scrollback_lines = 10000;
          enable_audio_bell = false;
          update_check_interval = 0;
          bell_on_tab = "🔔 ";
          window_border_width = "1pt";
          draw_minimal_borders = "yes";
          single_window_margin_width = "2";
          tab_bar_style = "powerline";
          tab_powerline_style = "slanted";
          notify_on_cmd_finish = "unfocused 10.0 notify";

          # macos
          macos_quit_when_last_window_closed = "yes";

          # wayland
          wayland_enable_ime = "yes";

        };
      };
    };
}
