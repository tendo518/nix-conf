{
  flake.modules.nixos."system/nix-ld" =
    { pkgs, ... }:
    {
      # Keep the shared fallback deliberately small. Hardware and desktop
      # modules append graphics, CUDA, and Wayland libraries as needed.
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          zlib
          glib
          libxcb
        ];
      };
    };
}
