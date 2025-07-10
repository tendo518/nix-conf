let
  # Get all subdirectories that contain a default.nix
  hostDirs = builtins.filter (name: builtins.pathExists (./. + "/${name}/default.nix")) (
    builtins.attrNames (builtins.readDir ./.)
  );
in
{
  imports = map (name: ./. + "/${name}/default.nix") hostDirs;
}
