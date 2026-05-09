{
  flake.modules.nixos."desktop/base" =
    {
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        libinput
        wayland-utils
        wl-clipboard
        libinput
        pavucontrol
        xlsclients

        # GPU related
        libva-utils # vainfo
        vulkan-tools # vulkaninfo
      ];

      # Enable Wayland for electron apps packaged by Nix
      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      # Common desktop services and settings
      services.dbus.implementation = "broker";
      services.printing.enable = true;
      services.gnome.gnome-keyring.enable = true;
      networking.networkmanager.enable = true;
      programs.dconf.enable = true;

      # Sound
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };

      # Bluetooth
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      # Keyboard layout
      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      # flatpak
      services.flatpak.enable = false;
      # xdg.portals.enable = true;

      # improve desktop responsiveness when updating the system
      nix.daemonCPUSchedPolicy = "idle";
    };
  flake.modules.homeManager."desktop/base" =

    {
      config,
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        xdg-utils # provides cli tools such as `xdg-mime` `xdg-open`
        xdg-user-dirs
      ];

      # XDG base directory env vars are set in core/xdg
      xdg.userDirs = {
        enable = true;
        createDirectories = true;
        setSessionVariables = true;
        extraConfig = {
          SCREENSHOTS = "${config.xdg.userDirs.pictures}/Screenshots";
        };
      };
    };
}
