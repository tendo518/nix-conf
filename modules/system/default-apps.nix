# Configure default applications for document types using duti
{ ... }:
{
  flake.modules.darwin."system/default-apps" =
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
        set_default "$VSCODE" "public.html"            # .html, .htm
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
        # mpv - Video player
        # ============================================================
        MPV="io.mpv"

        # Video formats
        set_ext "$MPV" "mp4"
        set_ext "$MPV" "mkv"
        set_ext "$MPV" "webm"
        set_ext "$MPV" "avi"
        set_ext "$MPV" "mov"
        set_ext "$MPV" "wmv"
        set_ext "$MPV" "flv"
        set_ext "$MPV" "m4v"
        set_ext "$MPV" "mpeg"
        set_ext "$MPV" "mpg"
        set_ext "$MPV" "3gp"
        # Note: .ts excluded (conflicts with TypeScript)

        # Audio formats
        set_ext "$MPV" "mp3"
        set_ext "$MPV" "flac"
        set_ext "$MPV" "wav"
        set_ext "$MPV" "aac"
        set_ext "$MPV" "ogg"
        set_ext "$MPV" "m4a"
        set_ext "$MPV" "wma"
        set_ext "$MPV" "opus"

        echo "Default applications configured."
      '';
    };
}