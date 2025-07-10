{
  hosts.nixos.server-lab-sardine = {
    modules = [
      "core/nix"
      "core/nixpkgs"
      "core/packages"
      "core/users"
      "core/shell"
      "core/editors"
      "core/xdg"
      "network/ssh-client"

      "system/base"
      "system/boot"
      "system/nix-ld"
      "system/security"
      "system/oomd"

      "apps/helix"
      "apps/neovim"
      "apps/yazi"

      "network/tailscale"
      "network/tailnet"

      "hosts/server-lab-sardine"
    ];
    excludeModules = [ "network/mihomo" ];
    user = {
      name = "tendo";
      email = "pengwyuan@gmail.com";
      trusted = true;
      sshPubKey = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKLqKE9nQVet+MSWdtO0mlECDSwJz8md4ZIZgv9y09KR"
      ];
      shell = "fish";
      homeStateVersion = "26.05";
      extraGroups = [
        "libvirtd"
        "kvm"
      ];
      passwordSecret = "tendo-password.age";
    };
    hostPlatform = "x86_64-linux";
    stateVersion = "26.05";
  };
}
