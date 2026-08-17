# Lab server: AZW EQ (Intel N100)
#
# This host was previously provisioned without keeping its source
# configuration in the repo. The files below reconstruct the running system
# from inspection of 192.168.16.154, reusing shared modules and preserving
# the original disko/network layout.
{ ... }:
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
      "core/ssh"

      "system/base"
      "system/boot"
      "system/security"
      "system/oomd"

      "apps/helix"
      "apps/neovim"
      "apps/yazi"

      "network/tailscale"
      "network/tailnet"

      "hosts/server-lab-sardine"
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
      extraGroups = [
        "libvirtd"
        "kvm"
      ];
      # Use the shared agenix-encrypted tendo password.
      passwordSecret = "tendo-password.age";
    };
    hostPlatform = "x86_64-linux";
    stateVersion = "26.05";
  };
}
