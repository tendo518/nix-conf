{
  flake.modules.nixos."system/virtualisation" =
    { pkgs, config, ... }:
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

      users.users =
        let
          user = config.host.user.name;
        in
        {
          "${user}".extraGroups = [
            "libvirtd"
            "kvm"
          ];
        };
    };
}
