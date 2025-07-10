{
  flake.modules.nixos."apps/wireshark" =
    { pkgs, hostContext, ... }:
    {
      programs.wireshark = {
        enable = true;
        package = pkgs.wireshark;
      };

      users.users.${hostContext.user.name}.extraGroups = [ "wireshark" ];
    };
}
