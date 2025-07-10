{
  hosts.darwin.laptop-solar-modoka = {
    modules = [
      "core"
      "system"
      "development"
      "agents"
      "network"
      "hosts/laptop-solar-modoka"
      "desktop/fonts"
      "desktop/input-method"
      "desktop/default-apps-darwin"
      "apps"
      "network/tailscale"
      "network/tailnet"
    ];
    excludeModules = [
      "apps/kitty"
      "apps/mpv"
      "network/mihomo"
    ];
    user = {
      name = "tendo";
      email = "pengwyuan@gmail.com";
      trusted = true;
      sshPubKey = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR"
      ];
      shell = "fish";
      homeStateVersion = "25.11";
    };
    hostPlatform = "aarch64-darwin";
    stateVersion = 6;
  };
}
