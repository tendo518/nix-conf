{
  flake.modules.nixos."system/bin-symlinks" =
    { pkgs, ... }:
    {
      # Create symlinks for common shebang interpreters in /bin
      # Many scripts expect interpreters at hardcoded paths like /bin/bash, /bin/sh, /bin/env
      systemd.tmpfiles.rules = [
        "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
        "L+ /bin/sh - - - - ${pkgs.bash}/bin/sh"
        "L+ /bin/env - - - - ${pkgs.coreutils}/bin/env"
        "L+ /bin/python - - - - ${pkgs.python3}/bin/python3"
        "L+ /bin/python3 - - - - ${pkgs.python3}/bin/python3"
        "L+ /bin/node - - - - ${pkgs.nodejs}/bin/node"
      ];
    };
}
