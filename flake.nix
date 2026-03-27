{
  description = "Nix flake for NixOS/macOS configuration";

  nixConfig = {
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    use-xdg-base-directories = true;
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rime-ice = {
      url = "github:tendo518/rime-ice";
      flake = false;
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree = {
      url = "github:vic/import-tree";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
  # inputs@{ self, ... }:
  # inputs.flake-parts.lib.mkFlake { inherit inputs self; } {
  #   imports = [
  #     ./modules/flake-parts.nix
  #     ./modules
  #     ./overlays/default.nix
  #     ./hosts/default.nix
  #   ];
  #   systems = [
  #     "x86_64-linux"
  #     "aarch64-darwin"
  #   ];

  #   # perSystem module for pkgs override and devShell
  #   perSystem =
  #     { system, pkgs, ... }:
  #     {
  #       formatter = pkgs.nixfmt-tree;
  #     };
  # };
}
