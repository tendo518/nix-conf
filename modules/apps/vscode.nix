{
  flake.modules.homeManager."apps/vscode" =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      programs.vscode = {
        enable = true;
        mutableExtensionsDir = true; # install ext by vscode itself
        profiles.default = {
          userSettings = {
            # Editor
            "editor.fontFamily" =
              if pkgs.stdenv.isDarwin then
                "\"Iosevka Lnxw\", monospace, \"Symbols Nerd Font\", \"等距更纱黑体 SC\", \"Noto Color Emoji\""
              else
                "monospace, \"Symbols Nerd Font\", \"等距更纱黑体 SC\", \"Noto Color Emoji\"";
            "editor.fontLigatures" = true;
            "editor.fontSize" = 14;
            "editor.smoothScrolling" = true;
            "editor.stickyScroll.enabled" = true;
            "editor.cursorBlinking" = "phase";
            "editor.bracketPairColorization.independentColorPoolPerBracketType" = true;
            "editor.guides.bracketPairs" = "active";
            "editor.linkedEditing" = true;
            "editor.acceptSuggestionOnCommitCharacter" = false;
            "editor.find.findOnType" = false;
            "editor.defaultColorDecorators" = "auto";
            "editor.suggest.preview" = true;
            "editor.suggest.shareSuggestSelections" = true;
            "editor.suggest.showStatusBar" = true;
            "editor.suggestSelection" = "recentlyUsedByPrefix";

            # Files
            "files.autoSave" = "afterDelay";
            "files.autoGuessEncoding" = true;
            "files.insertFinalNewline" = true;
            "files.trimFinalNewlines" = true;

            # Terminal
            "terminal.integrated.fontSize" = 14;
            "terminal.integrated.smoothScrolling" = true;
            "terminal.integrated.cursorBlinking" = true;
            "terminal.integrated.inheritEnv" = false;
            # "terminal.integrated.shellIntegration.enabled" = false;

            # Workbench
            "workbench.sideBar.location" = "right";
            "workbench.list.openMode" = "doubleClick";
            "workbench.list.smoothScrolling" = true;
            "workbench.tree.enableStickyScroll" = true;
            "workbench.tree.renderIndentGuides" = "always";
            "workbench.editor.revealIfOpen" = true;
            "workbench.editor.scrollToSwitchTabs" = true;
            "workbench.editor.sharedViewState" = true;
            "workbench.editor.empty.hint" = "hidden";
            "workbench.settings.enableNaturalLanguageSearch" = false;
            "workbench.remoteIndicator.showExtensionRecommendations" = false;
            "workbench.enableExperiments" = false;
            "workbench.startupEditor" = "none";

            # Window
            "window.menuStyle" = "custom";
            "window.menuBarVisibility" = "hidden";
            "window.titleBarStyle" = if pkgs.stdenv.isDarwin then "custom" else "native";
            "window.customTitleBarVisibility" = "never";

            # Update
            "update.mode" = "none";

            # Git
            "git.autofetch" = true;
            "git.confirmSync" = false;

            # Explorer
            "explorer.compactFolders" = false;

            # Search
            "search.useGlobalIgnoreFiles" = true;

            # SCM
            "scm.alwaysShowRepositories" = true;

            # Security & Trust
            "security.workspace.trust.enabled" = false;
            "extensions.ignoreRecommendations" = true;

            # Telemetry
            "telemetry.telemetryLevel" = "off";

            # Markdown
            "markdown.preview.breaks" = true;

            # Language specific
            "[markdown]"."editor.defaultFormatter" = "DavidAnson.vscode-markdownlint";
            "[shellscript]"."editor.defaultFormatter" = "mads-hartmann.bash-ide-vscode";

            # Python
            "python.languageServer" = "Pylance";
            "python.analysis.diagnosticMode" = "workspace";
            "python.analysis.languageServerMode" = "full";
            "python.analysis.autoImportCompletions" = true;
            "python.analysis.completeFunctionParens" = true;
            "python.analysis.enableSyncServer" = true;
            "python.analysis.regenerateStdLibIndices" = true;
            "python.analysis.inlayHints.callArgumentNames" = "partial";
            "python.analysis.typeEvaluation.strictListInference" = true;
            "python.analysis.typeEvaluation.strictDictionaryInference" = true;
            "python.analysis.typeEvaluation.strictSetInference" = true;
            "python.analysis.autoFormatStrings" = true;
            "python.analysis.enableParallelIndexing" = true;
            "python.analysis.generateWithTypeAnnotation" = true;
            "python.analysis.inlayHints.functionReturnTypes" = true;
            "python.analysis.inlayHints.pytestParameters" = true;
            "python.analysis.inlayHints.variableTypes" = true;
            "python.analysis.typeEvaluation.enableReachabilityAnalysis" = true;
            "python.analysis.typeCheckingMode" = "standard";

            # TypeScript/JavaScript
            "typescript.updateImportsOnFileMove.enabled" = "always";
            "javascript.updateImportsOnFileMove.enabled" = "never";

            # Remote SSH
            "remote.SSH.enableX11Forwarding" = false;
            "remote.SSH.externalSSH_ASKPASS" = true;
            "remote.SSH.remotePlatform" = {
              "*.tailscale" = "linux";
              "*.local" = "linux";
              "*.cluster" = "linux";
            };

            # Debug
            "debug.showVariableTypes" = true;
            "lldb.suppressUpdateNotifications" = true;

            # Media
            "mediaPreview.video.autoPlay" = false;
            "mediaPreview.video.loop" = false;

            # Extensions
            "clangd.detectExtensionConflicts" = false;

            # Claude Code
            "claudeCode.preferredLocation" = "panel";
            "claudeCode.useTerminal" = true;

            # AI
            "chat.disableAIFeatures" = true;

            # Theme
            "workbench.iconTheme" = "material-icon-theme";
            "window.autoDetectColorScheme" = true;
            "workbench.preferredLightColorTheme" = "Maple Light";
            "workbench.preferredDarkColorTheme" = "Maple Dark";
            "editor.semanticTokenColorCustomizations".rules = {
              interface.italic = true;
              selfParameter.italic = true;
              keyword.italic = true;
              "*.static".italic = true;
            };
            "editor.tokenColorCustomizations".textMateRules = [
              {
                scope = [
                  "constant.language.undefined"
                  "constant.language.null"
                  "constant.language.nullptr"
                  "meta.type keyword.operator.expression.typeof"
                  "meta.type keyword.operator.expression.keyof"
                  "keyword.control"
                  "keyword.function"
                  "keyword.operator.new"
                  "keyword.operator.borrow.and.rust"
                  "storage.type"
                  "storage.modifier"
                  "variable.language.this"
                  "markup.italic"
                ];
                settings.fontStyle = "italic";
              }
            ];
          };
        };
      };
    };
}
