{
  flake.modules.nixos."desktop/audio" = {
    # Sound
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true; # for wine
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
  };
}
