{
  flake.modules.nixos."system/security" =
    {
      lib,
      ...
    }:
    {
      # Sudo
      security.sudo = {
        enable = true;
      };

      # SSHD
      services.openssh = {
        enable = true;
        ports = [ 22 ];
        settings = {
          # default to no, but some vm may need root login
          PermitRootLogin = lib.mkDefault "no";
          PasswordAuthentication = lib.mkDefault false;
          KbdInteractiveAuthentication = false;
          PubkeyAuthentication = true;
        };
      };

      services.fail2ban = {
        enable = true;
        # sshd jail is enabled by default
      };
    };
}
