{
  flake.modules.nixos."network/firewall" =
    { lib, ... }:
    {
      networking.firewall = {
        enable = lib.mkDefault true;
        allowPing = true;
      };

      # Avahi/mDNS for local hostname discovery
      services.avahi.openFirewall = true;
    };
}
