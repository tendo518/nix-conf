# Recursively import all .nix files from subdirectories
# Excludes default.nix files which are entry points
let
  # Check if string ends with suffix
  hasSuffix = suffix: str:
    let
      suffixLen = builtins.stringLength suffix;
      strLen = builtins.stringLength str;
    in
    if strLen < suffixLen then false
    else builtins.substring (strLen - suffixLen) suffixLen str == suffix;

  # Collect .nix files from a directory (non-default.nix files only)
  collectNixFiles =
    dir:
    let
      entries = builtins.readDir dir;
      isNixFile = name: hasSuffix ".nix" name && name != "default.nix";
      isDir = name:
        let
          path = dir + "/${name}";
        in
        builtins.pathExists path && builtins.readFileType path == "directory";

      nixFiles = builtins.filter isNixFile (builtins.attrNames entries);
      subdirs = builtins.filter isDir (builtins.attrNames entries);

      # Get full paths for nix files
      nixPaths = map (name: dir + "/${name}") nixFiles;

      # Recursively collect from subdirs
      subdirPaths = builtins.concatMap (subdir: collectNixFiles (dir + "/${subdir}")) subdirs;
    in
    nixPaths ++ subdirPaths;
in
{
  imports = collectNixFiles ./.;
}
