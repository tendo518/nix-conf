{
  flake.modules.nixos."core/command-not-found" =
    {
      lib,
      pkgs,
      config,
      inputs,
      ...
    }:
    {
      # Enable nix-index with pre-built database from nix-index-database flake
      # This provides:
      # - `nix-locate` command for searching packages by file/command
      # - Automatic command-not-found suggestions
      # - `comma` command to temporarily run packages from nixpkgs
      imports = [
        inputs.nix-index-database.nixosModules.default
      ];

      programs.nix-index = {
        enable = true;
        # Shell integrations for command-not-found suggestions
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;
      };

      # Enable comma feature to easily run commands from nixpkgs
      # Usage: comma <command> - runs the command, offering to install it if missing
      programs.nix-index-database.comma.enable = true;

      # Disable legacy command-not-found (nix-index takes over)
      programs.command-not-found.enable = false;
    };

  flake.modules.darwin."core/command-not-found" =
    {
      lib,
      pkgs,
      config,
      inputs,
      ...
    }:
    {
      # Enable nix-index with pre-built database for macOS
      imports = [
        inputs.nix-index-database.darwinModules.default
      ];

      programs.nix-index = {
        enable = true;
      };

      # Enable comma feature
      programs.nix-index-database.comma.enable = true;
    };
}
