# Configure default applications for document types using duti
_: {
  flake.modules.darwin."desktop/default-apps-darwin" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      primaryUser = lib.escapeShellArg config.system.primaryUser;
      typeBundle = "Nix Development File Types.app";
      typeNamespace = "local.nix-conf.development-file-types";
      undeclaredExtensions = [
        "nix"
        "vim"
        "tsx"
        "jsx"
        "scss"
        "sass"
        "less"
        "config"
        "env"
        "dockerfile"
        "dockerignore"
        "gitignore"
        "gitattributes"
      ];
      developmentTypes = pkgs.writeTextDir "Applications/${typeBundle}/Contents/Info.plist" (
        lib.generators.toPlist { escape = true; } {
          CFBundleIdentifier = typeNamespace;
          CFBundleName = "Nix Development File Types";
          CFBundlePackageType = "APPL";
          CFBundleVersion = "1";
          LSBackgroundOnly = true;
          # Imported types serve as a fallback when no installed app exports a type.
          UTImportedTypeDeclarations = map (extension: {
            UTTypeIdentifier = "${typeNamespace}.${extension}";
            UTTypeConformsTo = [ "public.plain-text" ];
            UTTypeTagSpecification."public.filename-extension" = [ extension ];
          }) undeclaredExtensions;
        }
      );
    in
    {
      environment.systemPackages = [
        pkgs.duti
        developmentTypes
      ];

      system.activationScripts.postActivation.text = lib.mkAfter ''
        echo "Setting default applications..."

        # Activation scripts run as root, but LaunchServices associations are
        # per-user. Run duti in the primary user's GUI session.
        run_as_user() {
          /bin/launchctl asuser "$(/usr/bin/id -u -- ${primaryUser})" \
            /usr/bin/sudo --user=${primaryUser} -- "$@"
        }

        # duti needs a declared UTI to set a default for an extension.
        lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
        if ! run_as_user "$lsregister" -f ${lib.escapeShellArg "/Applications/Nix Apps/${typeBundle}"}; then
          echo "warning: failed to register development file types" >&2
        fi

        # Set default app by UTI
        set_default() {
          local bundle_id="$1"
          local uti="$2"
          if ! run_as_user ${lib.getExe pkgs.duti} -s "$bundle_id" "$uti" all; then
            echo "warning: failed to set $uti handler to $bundle_id" >&2
          fi
        }

        # Resolve the preferred UTI for a filename extension.
        set_ext() {
          local bundle_id="$1"
          local ext="$2"
          if ! run_as_user ${lib.getExe pkgs.duti} -s "$bundle_id" ".$ext" all; then
            echo "warning: failed to set .$ext handler to $bundle_id" >&2
          fi
        }

        # ============================================================
        # CotEditor - Plain-text files
        # ============================================================
        COTEDITOR="com.coteditor.CotEditor"
        set_default "$COTEDITOR" "public.plain-text"   # .txt
        set_ext "$COTEDITOR" "txt"

        # ============================================================
        # VSCode - Source code files
        # ============================================================
        VSCODE="com.microsoft.VSCode"

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
        for extension in ${lib.escapeShellArgs undeclaredExtensions}; do
          set_ext "$VSCODE" "$extension"
        done
        set_ext "$VSCODE" "rs"
        set_ext "$VSCODE" "go"
        set_ext "$VSCODE" "lua"
        set_ext "$VSCODE" "toml"
        set_ext "$VSCODE" "ts"
        set_ext "$VSCODE" "js"
        set_ext "$VSCODE" "css"
        set_ext "$VSCODE" "conf"
        set_ext "$VSCODE" "ini"

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
