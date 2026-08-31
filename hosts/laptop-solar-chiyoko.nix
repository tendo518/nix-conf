{
  hosts.nixos.laptop-solar-chiyoko = {
    modules = [
      "core"
      "system"
      "development"
      "agents"
      "apps"
      "network"
      "desktop"
      "hosts/laptop-solar-chiyoko"
      "network/tailscale"
      "network/mihomo"
      "hardware"
    ];
    excludeModules = [
      "apps/deskflow"
      "apps/gaming"
      "apps/wireshark"
      "desktop/niri"
      "system/disable-sleep"
      "hardware/nvidia"
      "development/virtualisation"
    ];
    user = {
      name = "tendo";
      email = "pengwyuan@gmail.com";
      trusted = true;
      sshPubKey = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR"
      ];
      shell = "fish";
      homeStateVersion = "26.05";
      extraGroups = [ "video" ];
    };
    hostPlatform = "aarch64-linux";
    stateVersion = "26.05";
  };
}
