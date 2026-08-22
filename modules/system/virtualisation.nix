{
  flake.modules.nixos."system/virtualisation" =
    { pkgs, hostContext, ... }:
    {
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
        };
      };

      virtualisation.spiceUSBRedirection.enable = true;

      programs.virt-manager.enable = true;

      users.users.${hostContext.user.name}.extraGroups = [
        "libvirtd"
        "kvm"
      ];
    };
}
