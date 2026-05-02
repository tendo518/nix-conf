{
  flake.modules.homeManager."system/xdg-workaround" =
    { lib, config, ... }:
    let
      inherit (config) xdg;
    in
    {
      # XDG Base Directory environment variables for applications that don't natively support it
      # Based on Arch Wiki: https://wiki.archlinux.org/title/XDG_Base_Directory
      home.sessionVariables = {
        # ═══════════════════════════════════════════════════════════════════════
        # PARTIAL SUPPORT - Requires environment variables
        # ═══════════════════════════════════════════════════════════════════════

        # ── Ack ──
        ACKRC = "${xdg.configHome}/ack/ackrc";

        # ── Ansible ──
        ANSIBLE_HOME = "${xdg.configHome}/ansible";
        ANSIBLE_CONFIG = "${xdg.configHome}/ansible/ansible.cfg";
        ANSIBLE_GALAXY_CACHE_DIR = "${xdg.cacheHome}/ansible/galaxy_cache";
        ANSIBLE_LOCAL_TEMP = "${xdg.cacheHome}/ansible/tmp";
        ANSIBLE_SSH_CONTROL_PATH_DIR = "${xdg.cacheHome}/ansible/cp";
        ANSIBLE_ASYNC_DIR = "${xdg.cacheHome}/ansible_async";

        # ── AWS CLI ──
        AWS_SHARED_CREDENTIALS_FILE = "${xdg.configHome}/aws/credentials";
        AWS_CONFIG_FILE = "${xdg.configHome}/aws/config";

        # ── Azure CLI ──
        AZURE_CONFIG_DIR = "${xdg.dataHome}/azure";

        # ── Bash completion ──
        BASH_COMPLETION_USER_FILE = "${xdg.configHome}/bash-completion/bash_completion";

        # ── Bitwarden ──
        # runtimeDir not available in home-manager, use XDG_RUNTIME_DIR directly
        # BITWARDEN_SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/bitwarden-ssh-agent.sock";

        # ── Bogofilter ──
        BOGOFILTER_DIR = "${xdg.dataHome}/bogofilter";

        # ── Bun ──
        # Bun prioritizes XDG vars when explicitly set
        BUN_INSTALL = "${xdg.dataHome}/bun";

        # ── Calc ──
        CALCHISTFILE = "${xdg.cacheHome}/calc_history";

        # ── Cargo (Rust) ──
        CARGO_HOME = "${xdg.dataHome}/cargo";

        # ── cd-bookmark ──
        CD_BOOKMARK_FILE = "${xdg.configHome}/cd-bookmark/bookmarks";

        # ── CGDB ──
        CGDB_DIR = "${xdg.configHome}/cgdb";

        # ── chez-scheme ──
        # petite --eehistory "$XDG_DATA_HOME"/chezscheme/history

        # ── Conky ──
        # Use: conky --config="$XDG_CONFIG_HOME"/conky/conkyrc

        # ── crawl ──
        CRAWL_DIR = "${xdg.dataHome}/crawl/";

        # ── CUDA ──
        CUDA_CACHE_PATH = "${xdg.cacheHome}/nv";

        # ── Docker ──
        DOCKER_CONFIG = "${xdg.configHome}/docker";

        # ── Docker Machine ──
        MACHINE_STORAGE_PATH = "${xdg.dataHome}/docker-machine";

        # ── Electrum ──
        ELECTRUMDIR = "${xdg.dataHome}/electrum";

        # ── ELinks ──
        ELINKS_CONFDIR = "${xdg.configHome}/elinks";

        # ── Elixir ──
        MIX_XDG = "true";

        # ── Elm ──
        ELM_HOME = "${xdg.configHome}/elm";

        # ── Emscripten ──
        EM_CONFIG = "${xdg.configHome}/emscripten/config";
        EM_CACHE = "${xdg.cacheHome}/emscripten/cache";
        EM_PORTS = "${xdg.dataHome}/emscripten/cache";

        # ── FFmpeg ──
        FFMPEG_DATADIR = "${xdg.configHome}/ffmpeg";

        # ── GHCup ──
        GHCUP_USE_XDG_DIRS = "true";

        # ── Gitsign ──
        TUF_ROOT = "${xdg.dataHome}/sigstore/root";

        # ── GNU Screen ──
        SCREENRC = "${xdg.configHome}/screen/screenrc";
        # SCREENDIR = "$XDG_RUNTIME_DIR/screen"; # runtimeDir not available

        # ── GnuPG ──
        GNUPGHOME = "${xdg.dataHome}/gnupg";

        # ── GNU Radio ──
        GR_PREFS_PATH = "${xdg.configHome}/gnuradio";
        GRC_PREFS_PATH = "${xdg.configHome}/gnuradio/grc.conf";

        # ── Go ──
        GOPATH = "${xdg.dataHome}/go";
        GOMODCACHE = "${xdg.cacheHome}/go/mod";

        # ── Gradle ──
        GRADLE_USER_HOME = "${xdg.dataHome}/gradle";

        # ── GTK 1 ──
        GTK_RC_FILES = "${xdg.configHome}/gtk-1.0/gtkrc";

        # ── GTK 2 ──
        GTK2_RC_FILES = "${xdg.configHome}/gtk-2.0/gtkrc:${xdg.configHome}/gtk-2.0/gtkrc.mine";

        # ── hledger ──
        LEDGER_FILE = "${xdg.dataHome}/hledger.journal";

        # ── imapfilter ──
        IMAPFILTER_HOME = "${xdg.configHome}/imapfilter";

        # ── IPFS ──
        IPFS_PATH = "${xdg.dataHome}/ipfs";

        # ── irb (Ruby) ──
        IRBRC = "${xdg.configHome}/irb/irbrc";

        # ── Java ──
        _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${xdg.configHome}/java";

        # ── Jupyter (pre-v5) ──
        # v5+: JUPYTER_PLATFORM_DIRS="1"
        # v6+: full support enabled by default

        # ── k9s ──
        K9SCONFIG = "${xdg.configHome}/k9s";

        # ── KDE4 ──
        KDEHOME = "${xdg.configHome}/kde";

        # ── keychain ──
        # Use: keychain --absolute --dir "$XDG_RUNTIME_DIR"/keychain

        # ── kscript ──
        KSCRIPT_CACHE_DIR = "${xdg.cacheHome}/kscript";

        # ── Leiningen ──
        LEIN_HOME = "${xdg.dataHome}/lein";

        # ── libdvdcss ──
        DVDCSS_CACHE = "${xdg.dataHome}/dvdcss";

        # ── libice ──
        ICEAUTHORITY = "${xdg.cacheHome}/ICEauthority";

        # ── Lynx ──
        LYNX_CFG = "${xdg.configHome}/lynx.cfg";

        # ── Maven ──
        MAVEN_OPTS = "-Dmaven.repo.local=${xdg.dataHome}/maven/repository";
        MAVEN_ARGS = "--settings ${xdg.configHome}/maven/settings.xml";

        # ── Mathematica/Wolfram ──
        WOLFRAM_USERBASE = "${xdg.configHome}/Wolfram";

        # ── Maxima ──
        MAXIMA_USERDIR = "${xdg.configHome}/maxima";

        # ── Mednafen ──
        MEDNAFEN_HOME = "${xdg.configHome}/mednafen";

        # ── Minikube ──
        MINIKUBE_HOME = "${xdg.dataHome}/minikube";

        # ── Minio Client ──
        MC_CONFIG_DIR = "${xdg.configHome}/minio-client";

        # ── MOC ──
        # Use: mocp -M "$XDG_CONFIG_HOME"/moc

        # ── most ──
        MOST_INITFILE = "${xdg.configHome}/mostrc";

        # ── MPlayer ──
        MPLAYER_HOME = "${xdg.configHome}/mplayer";

        # ── mypy ──
        MYPY_CACHE_DIR = "${xdg.cacheHome}/mypy";

        # ── MySQL ──
        MYSQL_HISTFILE = "${xdg.dataHome}/mysql_history";

        # ── n (node version manager) ──
        N_PREFIX = "${xdg.dataHome}/n";

        # # ── ncurses ── use nix set, following broke terminfo search path /etc/terminfo
        # TERMINFO = "${xdg.dataHome}/terminfo";
        # TERMINFO_DIRS = "${xdg.dataHome}/terminfo:/usr/share/terminfo";

        # ── Node.js ──
        NODE_REPL_HISTORY = "${xdg.dataHome}/node_repl_history";

        # ── nodenv ──
        NODENV_ROOT = "${xdg.dataHome}/nodenv";

        # ── npm ── (also requires config file)
        NPM_CONFIG_USERCONFIG = "${xdg.configHome}/npm/npmrc";

        # ── NuGet ──
        NUGET_PACKAGES = "${xdg.cacheHome}/NuGetPackages";

        # ── nvm ──
        NVM_DIR = "${xdg.dataHome}/nvm";

        # ── Octave ──
        OCTAVE_HISTFILE = "${xdg.cacheHome}/octave-hsts";
        OCTAVE_SITE_INITFILE = "${xdg.configHome}/octave/octaverc";

        # ── Omnisharp ──
        OMNISHARPHOME = "${xdg.configHome}/omnisharp";

        # ── opam ──
        OPAMROOT = "${xdg.dataHome}/opam";

        # ── OpenAI Codex ──
        CODEX_HOME = "${xdg.configHome}/codex";

        # ── parallel ──
        PARALLEL_HOME = "${xdg.configHome}/parallel";

        # ── pass ──
        PASSWORD_STORE_DIR = "${xdg.dataHome}/pass";

        # ── Phive ──
        PHIVE_HOME = "${xdg.dataHome}/phive";

        # ── PHP ──
        PHP_HISTFILE = "${xdg.stateHome}/php/history";

        # ── PlatformIO ──
        PLATFORMIO_CORE_DIR = "${xdg.dataHome}/platformio";

        # ── PostgreSQL ──
        PSQLRC = "${xdg.configHome}/pg/psqlrc";
        PSQL_HISTORY = "${xdg.stateHome}/psql_history";
        PGPASSFILE = "${xdg.configHome}/pg/pgpass";
        PGSERVICEFILE = "${xdg.configHome}/pg/pg_service.conf";

        # ── pyenv ──
        PYENV_ROOT = "${xdg.dataHome}/pyenv";

        # ── Python ──
        PYTHON_HISTORY = "${xdg.stateHome}/python_history";
        PYTHONPYCACHEPREFIX = "${xdg.cacheHome}/python";
        PYTHONUSERBASE = "${xdg.dataHome}/python";

        # ── python-easyocr ──
        EASYOCR_MODULE_PATH = "${xdg.configHome}/EasyOCR";

        # ── python-grip ──
        GRIPHOME = "${xdg.configHome}/grip";

        # ── python-kivy ──
        KIVY_HOME = "${xdg.dataHome}/kivy";

        # ── python-setuptools ──
        PYTHON_EGG_CACHE = "${xdg.cacheHome}/python-eggs";

        # ── Racket ──
        PLTUSERHOME = "${xdg.dataHome}/racket";

        # ── rbenv ──
        RBENV_ROOT = "${xdg.dataHome}/rbenv";

        # ── readline ──
        INPUTRC = "${xdg.configHome}/readline/inputrc";

        # ── recoll ──
        RECOLL_CONFDIR = "${xdg.configHome}/recoll";

        # ── Redis ──
        REDISCLI_HISTFILE = "${xdg.dataHome}/redis/rediscli_history";
        REDISCLI_RCFILE = "${xdg.configHome}/redis/redisclirc";

        # ── Ren'Py ──
        RENPY_PATH_TO_SAVES = "${xdg.dataHome}/renpy";
        RENPY_MULTIPERSISTENT = "${xdg.dataHome}/renpy_shared";

        # ── ripgrep ──
        RIPGREP_CONFIG_PATH = "${xdg.configHome}/ripgrep/config";

        # ── rlwrap ──
        RLWRAP_HOME = "${xdg.dataHome}/rlwrap";

        # ── ruby-bundler ──
        BUNDLE_USER_CACHE = "${xdg.cacheHome}/bundle";
        BUNDLE_USER_CONFIG = "${xdg.configHome}/bundle/config";
        BUNDLE_USER_PLUGIN = "${xdg.dataHome}/bundle";

        # ── ruby-solargraph ──
        SOLARGRAPH_CACHE = "${xdg.cacheHome}/solargraph";

        # ── ruby-travis ──
        TRAVIS_CONFIG_PATH = "${xdg.configHome}/travis";

        # ── Ruff ──
        RUFF_CACHE_DIR = "${xdg.cacheHome}/ruff";

        # ── rustup ──
        RUSTUP_HOME = "${xdg.dataHome}/rustup";

        # ── SageMath ──
        DOT_SAGE = "${xdg.configHome}/sage";

        # ── SDKMAN ──
        SDKMAN_DIR = "${xdg.dataHome}/sdkman";

        # ── Singularity CE ──
        SINGULARITY_CONFIGDIR = "${xdg.configHome}/singularity";
        SINGULARITY_CACHEDIR = "${xdg.cacheHome}/singularity";

        # ── spacemacs ──
        SPACEMACSDIR = "${xdg.configHome}/spacemacs";

        # ── SQLite ──
        SQLITE_HISTORY = "${xdg.stateHome}/sqlite_history";

        # ── starship ──
        STARSHIP_CONFIG = "${xdg.configHome}/starship.toml";
        STARSHIP_CACHE = "${xdg.cacheHome}/starship";

        # ── taskwarrior ──
        TASKDATA = "${xdg.dataHome}/task";
        TASKRC = "${xdg.configHome}/task/taskrc";

        # ── TeX Live ──
        TEXMFHOME = "${xdg.dataHome}/texmf";
        TEXMFVAR = "${xdg.cacheHome}/texlive/texmf-var";
        TEXMFCONFIG = "${xdg.configHome}/texlive/texmf-config";

        # ── TeXmacs ──
        TEXMACS_HOME_PATH = "${xdg.stateHome}/texmacs";

        # ── uncrustify ──
        UNCRUSTIFY_CONFIG = "${xdg.configHome}/uncrustify/uncrustify.cfg";

        # ── Unison ──
        UNISON = "${xdg.dataHome}/unison";

        # ── urxvtd ──
        # RXVT_SOCKET = "$XDG_RUNTIME_DIR/urxvtd"; # runtimeDir not available

        # ── Vagrant ──
        VAGRANT_HOME = "${xdg.dataHome}/vagrant";
        VAGRANT_ALIAS_FILE = "${xdg.dataHome}/vagrant/aliases";

        # ── virtualenv ──
        WORKON_HOME = "${xdg.dataHome}/virtualenvs";

        # ── w3m ──
        W3M_DIR = "${xdg.stateHome}/w3m";

        # ── wakatime ──
        WAKATIME_HOME = "${xdg.configHome}/wakatime";

        # ── wget ──
        WGETRC = "${xdg.configHome}/wgetrc";

        # ── wine ──
        WINEPREFIX = "${xdg.dataHome}/wineprefixes/default";

        # ── x3270 ──
        X3270PRO = "${xdg.configHome}/x3270/config";
        C3270PRO = "${xdg.configHome}/c3270/config";

        # ── xinit ──
        XINITRC = "${xdg.configHome}/X11/xinitrc";
        XSERVERRC = "${xdg.configHome}/X11/xserverrc";

        # ── Xorg xauth ──
        # XAUTHORITY = "$XDG_RUNTIME_DIR/Xauthority"; # runtimeDir not available

        # ── yarn ──
        # Use: yarn --use-yarnrc "$XDG_CONFIG_HOME/yarn/config"

        # ── z ──
        _Z_DATA = "${xdg.dataHome}/z";

        # ── Zsh ──
        ZDOTDIR = "${xdg.configHome}/zsh";

        # ═══════════════════════════════════════════════════════════════════════
        # HARDCODED - Workarounds via environment variables
        # ═══════════════════════════════════════════════════════════════════════

        # ── arduino-cli ──
        # Use: arduino-cli --config-file $XDG_CONFIG_HOME/arduino15/arduino-cli.yaml

        # ── conan ──
        CONAN_USER_HOME = "${xdg.configHome}";

        # ── Kubernetes ──
        KUBECONFIG = "${xdg.configHome}/kube";
        KUBECACHEDIR = "${xdg.cacheHome}/kube";

        # ── Julia ──
        JULIA_DEPOT_PATH = "${xdg.dataHome}/julia:$JULIA_DEPOT_PATH";
        JULIAUP_DEPOT_PATH = "${xdg.dataHome}/julia";

        # ── Ollama ──
        OLLAMA_MODELS = "${xdg.dataHome}/ollama/models";

        # ── TeamSpeak ──
        TS3_CONFIG_DIR = "${xdg.configHome}/ts3client";

        # ── Xorg session files ──
        # These need to be set in Xorg init scripts, not session variables
        # USERXSESSION="$XDG_CACHE_HOME/X11/xsession"
        # USERXSESSIONRC="$XDG_CACHE_HOME/X11/xsessionrc"
        # ALTUSERXSESSION="$XDG_CACHE_HOME/X11/Xsession"
        # ERRFILE="$XDG_CACHE_HOME/X11/xsession-errors"

        # ── mailcap ──
        MAILCAPS = "${xdg.configHome}/mailcap";

        # ── Presage (maliit-keyboard) ──
        # No workaround available, compile master branch of maliit-keyboard

        # ── Hstr ──
        # No workaround, hardcoded

        # ── Nix ──
        # Set in /etc/nix/nix.conf: use-xdg-base-directories = true

        # ── STM (Spring Tool Suite) ──
        # Pass JVM arg: -Dlanguageserver.boot.symbolCacheDir=$XDG_CACHE_HOME/sts4/symbolCache
      };

      # ═══════════════════════════════════════════════════════════════════════
      # Config files that need to be created
      # ═══════════════════════════════════════════════════════════════════════

      # wget needs hsts file location in config
      xdg.configFile."wgetrc".text = ''
        hsts-file = ${xdg.stateHome}/wget-hsts
      '';

      # npm config (partial - already handled in langs.nix but included here for completeness)
      # xdg.configFile."npm/npmrc".text = ''
      #   prefix=${xdg.dataHome}/npm
      #   cache=${xdg.cacheHome}/npm
      #   init-module=${xdg.configHome}/npm/config/npm-init.js
      #   logs-dir=${xdg.stateHome}/npm/logs
      # '';

      # Zsh history and completion directories
      xdg.configFile."zsh/.zshrc" = lib.mkIf (config.programs.zsh.enable) {
        text = ''
          # XDG dirs for completion and history files
          [[ -d "${xdg.stateHome}/zsh" ]] || mkdir -p "${xdg.stateHome}/zsh"
          HISTFILE="${xdg.stateHome}/zsh/history"
          [[ -d "${xdg.cacheHome}/zsh" ]] || mkdir -p "${xdg.cacheHome}/zsh"
          zstyle ':completion:*' cache-path "${xdg.cacheHome}/zsh/zcompcache"
          compinit -d "${xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"
        '';
      };

      # ═══════════════════════════════════════════════════════════════════════
      # Create necessary directories
      # ═══════════════════════════════════════════════════════════════════════
      home.activation.createXdgDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Create common XDG directories
        mkdir -p "${xdg.configHome}"
        mkdir -p "${xdg.dataHome}"
        mkdir -p "${xdg.cacheHome}"
        mkdir -p "${xdg.stateHome}"

        # Create application-specific directories that are commonly needed
        mkdir -p "${xdg.configHome}/aws"
        mkdir -p "${xdg.configHome}/docker"
        mkdir -p "${xdg.configHome}/gnupg"
        mkdir -p "${xdg.configHome}/kube"
        mkdir -p "${xdg.configHome}/npm"
        mkdir -p "${xdg.configHome}/pg"
        mkdir -p "${xdg.configHome}/readline"
        mkdir -p "${xdg.configHome}/zsh"
        mkdir -p "${xdg.configHome}/ripgrep/"

        mkdir -p "${xdg.dataHome}/cargo"
        mkdir -p "${xdg.dataHome}/go"
        mkdir -p "${xdg.dataHome}/gnupg"
        mkdir -p "${xdg.dataHome}/julia"
        mkdir -p "${xdg.dataHome}/npm"
        mkdir -p "${xdg.dataHome}/rustup"
        mkdir -p "${xdg.dataHome}/terminfo"
        mkdir -p "${xdg.dataHome}/wineprefixes"

        mkdir -p "${xdg.cacheHome}/go"
        mkdir -p "${xdg.cacheHome}/npm"
        mkdir -p "${xdg.cacheHome}/python"
        mkdir -p "${xdg.cacheHome}/zsh"

        mkdir -p "${xdg.stateHome}/python"
        mkdir -p "${xdg.stateHome}/zsh"
      '';
    };
}
