{
  lib,
  pkgs,
  config,
  ...
}:
let
  # Helper function to generate duti commands
  mkDutiCmd =
    bundleId: extensions:
    lib.concatStringsSep "\n" (map (ext: "${pkgs.duti}/bin/duti -s ${bundleId} ${ext} all") extensions);

  # File associations grouped by application
  associations = {
    # CotEditor - text and code files
    "com.coteditor.CotEditor" = [
      # MIME types
      "public.plain-text"
      "public.source-code"
      "net.daringfireball.markdown"
      # Extensions
      "json"
      "py"
      "js"
      "ts"
      "jsx"
      "tsx"
      "css"
      "scss"
      "md"
      "sh"
      "bash"
      "zsh"
      "yaml"
      "yml"
      "toml"
      "ini"
      "nix"
      "c"
      "h"
      "cpp"
      "hpp"
      "cc"
      "java"
      "rs"
      "go"
      "rb"
      "php"
      "swift"
      "pl"
      "lua"
      "tex"
      "sql"
      "dockerfile"
      "Makefile"
    ];

    # Skim - PDF files
    "net.sourceforge.skim-app.skim" = [
      "pdf"
    ];
  };
in
{
  home.packages = with pkgs; [
    duti
  ];

  home.activation.fileAssociations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList mkDutiCmd associations)}
  '';
}
