{
  flake.modules.homeManager."core/shell" =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      starship_preset = "plain-text-symbols";
      starship_settings = pkgs.runCommand "starship.toml" { } ''
        ${pkgs.starship}/bin/starship preset ${starship_preset} > $out
      '';
    in
    {

      home.shellAliases = {
        exa = "eza";
        l = "eza --git --group --time-style=long-iso";
        ll = "l -l";
        la = "l -a";
        lla = "l -la";
        # use rm and mv with caution
        rm = "rm -iv";
        mv = "mv -iv";
        cpr = "rsync --archive -hh --partial --info=stats1,progress2 --modify-window=1";
        mvr = "rsync --archive -hh --partial --info=stats1,progress2 --modify-window=1 --remove-source-files";
        y = "yazi";
      };

      programs.fish = {
        enable = true;
        shellInit = ''
          set -gx GPG_TTY (tty)
        '';
        shellAbbrs = {
          sctl = "sudo systemctl";
          sctlu = "systemctl --user";
          restart-plasma = "systemctl --user restart plasma-plasmashell.service";
          g = "git";
          v = "vim";
          s = "sudo";
          which = "command -v";
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          del = "trash";
          ts = "sudo tailscale";
          kssh = "kitty +kitten ssh";
          icat = "kitty +kitten icat";
        };
        functions = {
          fish_greeting = ''

          '';
        };
      };

      programs.zsh = {
        # enable = true;
        enableCompletion = true;
        syntaxHighlighting.enable = true;
        autosuggestion.enable = true;
        dotDir = "${config.xdg.configHome}/zsh";
        history = {
          size = 10000;
          path = "${config.xdg.dataHome}/zsh/history";
        };
      };

      programs.eza = {
        enable = true;
        git = true;
        icons = "auto";
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;
      };

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      programs.zoxide = {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;
      };

      programs.atuin = {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;
        flags = [
          "--disable-up-arrow"
        ];
      };

      programs.starship = {
        enable = true;
        # enableTransience = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;
      };
      xdg.configFile."starship.toml".source = starship_settings;

      home.packages = with pkgs; [
        # --- Core Utilities ---
        uutils-coreutils-noprefix # Cross-platform core utilities (ls, cp, mv, etc.)
        uutils-findutils # Cross-platform find, xargs
        uutils-diffutils # Cross-platform diff
        gnused # GNU sed (stream editor)
        gnugrep # GNU grep (text search)
        gawk # GNU awk (pattern scanning and processing language)
        which # Locate a command
        file # Determine file type
        just
        git
        trash-cli
        fastfetch
        unrar

        lsof
        # --- File & Directory Management ---
        tree # Display directory structure as a tree
        gdu # Disk usage analyzer with console interface
        fd # A simple, fast and user-friendly alternative to 'find'

        # --- Archiving & Compression ---
        zip # Pack and unpack zip files
        unzip # Extract zip files
        xz # Compress or decompress .xz and .lzma files
        p7zip # 7-Zip file archiver
        gnutar # GNU tar for creating and extracting archives
        zstd # Zstandard compression

        # --- Searching & Filtering ---
        ripgrep # A line-oriented search tool that recursively searches for a regex pattern
        jq # Command-line JSON processor
        yq-go # Command-line YAML, JSON and XML processor
        fzf # A command-line fuzzy finder

        # --- Networking ---
        aria2 # Lightweight multi-protocol & multi-source command-line download utility
        socat # Multipurpose relay (SOcket CAT)
        nmap # Network discovery and security auditing tool
        caddy # Web server with automatic HTTPS
        gnupg # GNU Privacy Guard for encryption and signing
        rsync # A fast, versatile, remote (and local) file-copying tool
        wget # Non-interactive download of files from the Web
        curlFull # Transfer data with URLs
        httpie # Command-line HTTP client

        # --- System Monitoring ---
        htop # Interactive process viewer

        # --- Media ---
        ffmpeg-full # A complete, cross-platform solution to record, convert and stream audio and video

        # --- Development & Code ---
        tokei # Displays statistics about your code
        bat # A cat(1) clone with wings

        # --- Documentation & Typesetting ---
        glow # Render markdown on the CLI
        typst # A modern typesetting system
        tealdeer # A very fast implementation of tldr in Rust

        # --- Miscellaneous ---
        tmux # Terminal multiplexer
        zellij # Another terminal workspace with batteries included

        imagemagick
        pandoc
        dysk
        rlwrap
        # easy to use tui calculator
        libqalculate
      ];
    };
  flake.modules.nixos."core/shell" = {
    environment.enableAllTerminfo = true;
  };
  flake.modules.darwin."core/shell" = {
    environment.enableAllTerminfo = true;
  };
}
