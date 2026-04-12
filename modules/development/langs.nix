let
  # Shared system-level module (used by both nixos and darwin)
  systemModule =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        # Ansible
        ansible
        ansible-lint

        # Bun
        bun

        # C++
        gnumake
        clang
        clang-tools
        cmake
        neocmakelsp
        lldb
        meson

        # LaTeX
        tectonic

        # Nix
        nixd
        nil
        nixfmt

        # Node.js
        nodejs

        # Python
        python3
        uv
        ruff
        pixi

        # Rust
        rustup
        cargo-binstall

        # Typst
        typst
        tinymist
        typstyle
      ];
    };
in
{
  flake.modules.nixos."development/langs" = systemModule;
  flake.modules.darwin."development/langs" = systemModule;

  # Home-manager module for HM-specific config (env vars, XDG, programs)
  flake.modules.homeManager."development/langs" =
    { config, ... }:
    let
      xdg = config.xdg;
    in
    {
      home.sessionVariables = {
        # ── Rust mirrors ──
        RUSTUP_DIST_SERVER = "https://rsproxy.cn";
        RUSTUP_UPDATE_ROOT = "https://rsproxy.cn/rustup";
      };

      home.sessionPath = [
        "${xdg.dataHome}/npm/bin"
        "${xdg.dataHome}/cargo/bin"
      ];

      # ── npm: XDG dirs + China mirror ──
      xdg.configFile."npm/npmrc".text = ''
        prefix=${xdg.dataHome}/npm
        cache=${xdg.cacheHome}/npm
        init-module=${xdg.configHome}/npm/config/npm-init.js
        logs-dir=${xdg.stateHome}/npm/logs
        registry=https://registry.npmmirror.com
      '';

      # ── Cargo: crates.io mirror (rsproxy) ──
      home.file."${xdg.dataHome}/cargo/config.toml".text = ''
        [source.crates-io]
        replace-with = 'rsproxy-sparse'

        [source.rsproxy-sparse]
        registry = "sparse+https://rsproxy.cn/index/"

        [registries.rsproxy]
        index = "https://rsproxy.cn/crates.io-index"

        [net]
        git-fetch-with-cli = true
      '';

      # ── Bun: China mirror ──
      xdg.configFile."bun/bunfig.toml".text = ''
        [install]
        registry = "https://registry.npmmirror.com"
      '';

      # ── Python: uv mirror ──
      programs.uv = {
        enable = true;
        settings = {
          index-url = "https://mirrors.sustech.edu.cn/pypi/web/simple";
        };
      };
    };
}
