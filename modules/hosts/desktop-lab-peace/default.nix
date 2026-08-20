# Desktop workstation at lab
# Host configuration and module registrations
{ ... }:
{
  # Host definition
  hosts.nixos.desktop-lab-peace = {
    modules = [
      "core"
      "system"
      "development"
      "agents"
      "apps"
      "network"
      "desktop"
      "hosts/desktop-lab-peace"
      "hardware"
    ];
    excludeModules = [
      "apps/gaming"
      "desktop/niri"
      "hardware/lenovo-x13s"
    ];
    user = {
      name = "pengwy";
      email = "pengwyuan@gmail.com";
      trusted = true;
      sshPubKey = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR"
      ];
      shell = "fish";
      homeStateVersion = "26.05";
      # extraGroups = [ ];
      passwordSecret = "tendo-password.age";
    };
    hostPlatform = "x86_64-linux";
    stateVersion = "26.05";
  };

  # Subnet router: advertise the lab networks to the tailnet. `useRoutingFeatures
  # = "server"` enables IP forwarding. host.tailscale.upFlags overrides the
  # default --accept-routes with --advertise-routes (--operator is added by the
  # tailscale-auth script). The advertised routes must be approved in the
  # Tailscale admin console (or via autoApprovers in the ACL) to take effect.
  # Do NOT add --accept-routes: a node that both advertises and accepts the same
  # route sends its own directly-connected subnet traffic through itself (the
  # HA subnet-router pitfall).
  flake.modules.nixos."hosts/desktop-lab-peace" =
    { ... }:
    {
      host.tailscale.upFlags = [
        "--advertise-routes=172.18.36.0/23,172.18.34.0/23,10.16.0.0/17"
      ];
      services.tailscale.useRoutingFeatures = "server";
    };
}
