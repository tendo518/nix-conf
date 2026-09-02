# Spotifyd: a lightweight Spotify Connect client daemon.
#
# Uses home-manager's built-in `services.spotifyd` module, which runs spotifyd
# as a user service so audio flows through the desktop's PipeWire/Pulse session
# (a systemd system service cannot reach the user's PipeWire socket) and MPRIS
# integrates with the desktop session.
#
# Authentication is handled by LAN discovery (zeroconf): spotifyd advertises
# itself as a Spotify Connect device on the local network, so no Spotify
# credentials need to be stored on this machine. Pick the device name from
# any Spotify client on the same LAN. For single-user OAuth login instead,
# run `spotifyd auth` once (credentials are cached under ~/.cache/spotifyd).
{
  flake.modules.nixos."apps/spotifyd" = {
    # LAN discovery: mDNS advertisement (5353/udp, shared with avahi) and the
    # fixed zeroconf TCP port that Spotify clients connect to.
    networking.firewall.allowedUDPPorts = [ 5353 ];
    networking.firewall.allowedTCPPorts = [ 1234 ];
  };

  flake.modules.homeNixOS."apps/spotifyd" =
    { hostContext, ... }:
    {
      services.spotifyd = {
        enable = true;
        settings.global = {
          device_name = hostContext.hostname;
          device_type = "computer";
          backend = "pulseaudio";
          bitrate = 320;
          volume_normalisation = true;
          use_mpris = true;
          zeroconf_port = 1234;
        };
      };
    };
}
