# Configure default applications for document types using duti
_: {
  flake.modules.darwin."desktop/default-apps-darwin" =
    { pkgs, lib, ... }:
    {
      environment.systemPackages = [ pkgs.duti ];

      system.activationScripts.postActivation.text = lib.mkAfter ''
        echo "Setting default applications..."

        # Helper function to set default app by UTI
        set_default() {
          local bundle_id="$1"
          local uti="$2"
          ${pkgs.duti}/bin/duti -s "$bundle_id" "$uti" all 2>/dev/null || true
        }

        # For file types with dynamic UTIs, we use extension-based approach
        # duti supports: echo 'bundle_id .ext role' | duti
        set_ext() {
          local bundle_id="$1"
          local ext="$2"
          echo "$bundle_id .$ext all" | ${pkgs.duti}/bin/duti 2>/dev/null || true
        }

        # ============================================================
        # VSCode - Text and source code files
        # ============================================================
        VSCODE="com.microsoft.VSCode"

        # Standard text types
        set_default "$VSCODE" "public.plain-text"      # .txt
        set_default "$VSCODE" "public.source-code"     # generic source code
        set_default "$VSCODE" "public.script"          # generic scripts
        set_default "$VSCODE" "public.shell-script"    # .sh, .bash, .zsh
        set_default "$VSCODE" "public.python-script"   # .py
        set_default "$VSCODE" "public.json"            # .json
        set_default "$VSCODE" "public.yaml"            # .yaml, .yml
        set_default "$VSCODE" "public.xml"             # .xml
        # set_default "$VSCODE" "public.html"            # .html, .htm
        set_default "$VSCODE" "net.daringfireball.markdown"  # .md

        # Programming languages by extension
        set_ext "$VSCODE" "nix"
        set_ext "$VSCODE" "rs"
        set_ext "$VSCODE" "go"
        set_ext "$VSCODE" "lua"
        set_ext "$VSCODE" "vim"
        set_ext "$VSCODE" "toml"
        set_ext "$VSCODE" "ts"
        set_ext "$VSCODE" "tsx"
        set_ext "$VSCODE" "js"
        set_ext "$VSCODE" "jsx"
        set_ext "$VSCODE" "css"
        set_ext "$VSCODE" "scss"
        set_ext "$VSCODE" "sass"
        set_ext "$VSCODE" "less"
        set_ext "$VSCODE" "conf"
        set_ext "$VSCODE" "config"
        set_ext "$VSCODE" "ini"
        set_ext "$VSCODE" "env"
        set_ext "$VSCODE" "dockerfile"
        set_ext "$VSCODE" "dockerignore"
        set_ext "$VSCODE" "gitignore"
        set_ext "$VSCODE" "gitattributes"

        # ============================================================
        # Skim - PDF reader
        # ============================================================
        SKIM="net.sourceforge.skim-app.skim"
        set_default "$SKIM" "com.adobe.pdf"

        # ============================================================
        # IINA - Video player
        # ============================================================
        IINA="com.colliderli.iina"

        # Video formats
        set_ext "$IINA" "mp4"
        set_ext "$IINA" "mkv"
        set_ext "$IINA" "webm"
        set_ext "$IINA" "avi"
        set_ext "$IINA" "mov"
        set_ext "$IINA" "wmv"
        set_ext "$IINA" "flv"
        set_ext "$IINA" "m4v"
        set_ext "$IINA" "mpeg"
        set_ext "$IINA" "mpg"
        set_ext "$IINA" "3gp"
        # Note: .ts excluded (conflicts with TypeScript)

        # Audio formats
        set_ext "$IINA" "mp3"
        set_ext "$IINA" "flac"
        set_ext "$IINA" "wav"
        set_ext "$IINA" "aac"
        set_ext "$IINA" "ogg"
        set_ext "$IINA" "m4a"
        set_ext "$IINA" "wma"
        set_ext "$IINA" "opus"

        echo "Default applications configured."
      '';
    };
}
