{
  description = "Nix flake for NixOS/macOS configuration";

  nixConfig = {
    # Mirrors are intentionally duplicated in modules/core/nix.nix:
    # the flake schema requires a literal nixConfig attribute set.
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirror.nju.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    # -small cause tooo many compilation in darwin
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    # Keep lanzaboote on its pinned nixpkgs: following the root input would
    # pull a different rustc toolchain build (large) on secure-boot hosts.
    lanzaboote.url = "github:nix-community/lanzaboote/v1.1.0";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    # Keep its upstream nixpkgs pin: cache.numtide.com publishes agent builds
    # against it, so following the root nixpkgs would reduce cache hits.
    llm-agents.url = "github:numtide/llm-agents.nix";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rime-ice = {
      url = "github:tendo518/rime-ice";
      flake = false;
    };

  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        (inputs.import-tree ./flake)
        (inputs.import-tree ./hosts)
        (inputs.import-tree ./modules)
      ];
    };
}
