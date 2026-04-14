{
  flake.modules.homeManager."core/editors" = {
    # Neovim
    programs.neovim = {
      enable = true;
      vimAlias = true;
      viAlias = true;
      withPython3 = false;
      withRuby = false;

    };

    # Helix
    programs.helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        theme = "jetbrains_dark";

        editor = {
          auto-format = false;
          auto-save = true;
          bufferline = "multiple";
          cursorcolumn = false;
          cursorline = true;
          idle-timeout = 100;
          line-number = "absolute";
          mouse = true;
          true-color = true;

          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };

          indent-guides = {
            character = "╎";
            render = true;
            skip-levels = 0;
          };

          lsp = {
            display-inlay-hints = true;
            display-messages = true;
            enable = true;
          };

          soft-wrap = {
            enable = true;
            wrap-indicator = "↩ ";
          };

          statusline = {
            center = [ ];
            left = [
              "mode"
              "file-name"
              "spinner"
            ];
            right = [
              "diagnostics"
              "selections"
              "position"
              "file-encoding"
              "file-line-ending"
              "file-type"
            ];
            separator = "│";

            mode = {
              insert = "I";
              normal = "N";
              select = "V";
            };
          };

          whitespace = {
            characters = {
              nbsp = "⍽";
              newline = "⏎";
              nnbsp = "␣";
              space = "·";
              tab = "→";
              tabpad = "·";
            };

            render = {
              nbsp = "all";
              newline = "none";
              nnbsp = "all";
              space = "none";
              tab = "all";
            };
          };
        };

        keys = {
          normal = {
            space.w = ":w";
            space.q = ":q";
            esc = [
              "collapse_selection"
              "keep_primary_selection"
            ];
          };
          insert = {
            j.k = "normal_mode";
          };
        };
      };
    };
  };
}
