{
  flake.modules.home."apps/kitty" =
    { pkgs, ... }:
    {
      # Kitty
      programs.kitty = {
        enable = true;
        keybindings."kitty_mod+t" = "new_tab_with_cwd";
        settings = {
          # shell integration
          shell_integration = "no-rc";

          # font
          font_family = "monospace";
          bold_font = "auto";
          italic_font = "auto";
          bold_italic_font = "auto";
          font_size = if pkgs.stdenv.hostPlatform.isDarwin then 14.0 else 12.0;

          # misc
          scrollback_lines = 80000;
          enable_audio_bell = false;
          update_check_interval = 0;
          bell_on_tab = "🔔 ";
          window_border_width = "1pt";
          draw_minimal_borders = "yes";
          single_window_margin_width = "2";
          tab_bar_style = "powerline";
          tab_powerline_style = "slanted";
          tab_title_max_length = 20;
          tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{secure_input_symbol}{fmt.fg.tab}{tab.last_focused_progress_percent}{title}";
          notify_on_cmd_finish = "unfocused 10.0 notify";

          # appearance
          background_opacity = 0.85;
          background_blur = 20;

          # Kaolin Ocean theme
          background = "#14141e";
          foreground = "#e6e6e8";
          selection_background = "#e6e6e8";
          selection_foreground = "#14141e";
          cursor = "#e6e6e8";
          cursor_text_color = "#14141e";
          active_border_color = "#6bd9db";
          inactive_border_color = "#545c5e";
          active_tab_background = "#e6e6e8";
          active_tab_foreground = "#14141e";
          inactive_tab_background = "#545c5e";
          inactive_tab_foreground = "#14141e";
          color0 = "#14141e";
          color8 = "#545c5e";
          color1 = "#e84c58";
          color9 = "#e84c58";
          color2 = "#35BF88";
          color10 = "#7CF083";
          color3 = "#dbac66";
          color11 = "#eed891";
          color4 = "#4ca6e8";
          color12 = "#53859d";
          color5 = "#c79af4";
          color13 = "#cea2ca";
          color6 = "#6bd9db";
          color14 = "#4d9391";
          color7 = "#e6e6e8";
          color15 = "#bebec4";

          # macos
          macos_quit_when_last_window_closed = "yes";

          # wayland
          wayland_enable_ime = "yes";

        };
      };
    };
}
