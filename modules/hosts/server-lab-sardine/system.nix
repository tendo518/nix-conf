# System settings recovered from server-lab-sardine.
#
# The recovered server is a headless lab box with DHCP on enp1s0, the
# default systemd-boot/sshd/fail2ban/oomd stack, and no nix-ld helper.
{ lib, ... }:
{
  flake.modules.nixos."hosts/server-lab-sardine/system" =
    { ... }:
    {
      # Reuse system/base for its journald/nscd/no-file/limit defaults, but
      # keep nix-ld off to match the recovered system.
      programs.nix-ld.enable = lib.mkForce false;

      # Recovered network state: predictable names, firewall enabled with
      # ping allowed. Per-interface DHCP is configured in router.nix.
      networking.useDHCP = false;
      networking.usePredictableInterfaceNames = true;
      networking.firewall.enable = true;
      networking.firewall.allowPing = true;

      # Allow root SSH key login on this host so nix-anywhere can target
      # root@server-lab-sardine directly on future deployments. Password auth
      # remains disabled by system/security.
      services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR"
      ];

      # Recovered account state: locked password, uid 1001, wheel only.
      users.mutableUsers = false;
      users.users.tendo = {
        uid = 1001;
        group = "users";
      };
    };
}
