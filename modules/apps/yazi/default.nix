{
  flake.modules.home."apps/yazi" =
    {
      ...
    }:
    {
      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
        shellWrapperName = "y";

        settings = {
          mgr = {
            # Hide parent directory pane (leftmost panel)
            ratio = [0 4 3];
            # Show symlink targets after filenames
            show_symlink = true;
            # Show hidden files by default
            show_hidden = true;
            # Keep 5 files of context above/below cursor when scrolling
            scrolloff = 5;
            # Show file sizes in the file list
            linemode = "size";
            # Directories first, alphabetical, case-insensitive
            sort_by = "alphabetical";
            sort_dir_first = true;
            sort_sensitive = false;
          };
          preview = {
            # 2-space tab width in code preview
            tab_size = 2;
            # No line wrapping in code preview
            wrap = "no";
            # Larger max dimensions for image preview
            max_width = 2000;
            max_height = 2000;
          };
        };

        keymap = {
          # NOTE: yazi v25+ renamed the `manager` layer to `mgr` in keymap.toml.
          # Using `manager.prepend_keymap` is silently ignored.
          mgr.prepend_keymap = [
            {
              # T: maximize/restore preview pane
              run = "plugin toggle-pane -- max-preview";
              on = ["T"];
              desc = "Maximize or restore the preview pane";
            }
            {
              # <C-t>: hide/show preview pane (t is a prefix key for tabs in default keymap)
              run = "plugin toggle-pane -- min-preview";
              on = ["<C-t>"];
              desc = "Show or hide the preview pane";
            }
          ];
        };

        plugins."toggle-pane" = ./plugins/toggle-pane;
      };

      # ycd: launch yazi then cd to the directory you navigated to.
      # Must be shell functions (not a script) because cd affects the current session.
      programs.fish.functions.ycd = ''
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
          builtin cd -- "$cwd"
        end
        command rm -f -- "$tmp"
      '';
    };
}
