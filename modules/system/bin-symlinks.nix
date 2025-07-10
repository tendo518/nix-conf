{
  flake.modules.nixos."system/bin-symlinks" = _: {
    # Create symlinks for common shebang interpreters in /bin
    # Many scripts expect interpreters at hardcoded paths like /bin/bash, /bin/sh, /bin/env
    systemd.tmpfiles.rules = [
      "L+ /bin/bash - - - - /run/current-system/sw/bin/bash"
      "L+ /bin/sh - - - - /run/current-system/sw/bin/sh"
      "L+ /bin/env - - - - /run/current-system/sw/bin/env"
      "L+ /bin/python - - - - /run/current-system/sw/bin/python3"
      "L+ /bin/python3 - - - - /run/current-system/sw/bin/python3"
      "L+ /bin/node - - - - /run/current-system/sw/bin/node"
    ];
  };
}
