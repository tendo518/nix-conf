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
        # ── Ansible XDG ──
        ANSIBLE_HOME = "${xdg.configHome}/ansible";
        ANSIBLE_CONFIG = "${xdg.configHome}/ansible/ansible.cfg";
        ANSIBLE_GALAXY_CACHE_DIR = "${xdg.cacheHome}/ansible/galaxy_cache";

        # ── Node.js XDG ──
        NPM_CONFIG_USERCONFIG = "${xdg.configHome}/npm/npmrc";
        NODE_REPL_HISTORY = "${xdg.dataHome}/node_repl_history";

        # ── Rust XDG + mirrors ──
        RUSTUP_HOME = "${xdg.dataHome}/rustup";
        CARGO_HOME = "${xdg.dataHome}/cargo";
        RUSTUP_DIST_SERVER = "https://rsproxy.cn";
        RUSTUP_UPDATE_ROOT = "https://rsproxy.cn/rustup";

        # ── Python XDG ──
        PYTHON_HISTORY = "${xdg.stateHome}/python/history";
        PYTHONPYCACHEPREFIX = "${xdg.cacheHome}/python";
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
