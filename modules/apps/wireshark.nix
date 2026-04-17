{
  flake.modules.nixos."apps/wireshark" = { pkgs, config,... }: {

  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };

users.users = 
  let user = config.host.user.name; in
  {
  "${user}".extraGroups = [ "wireshark" ];
  };
  };
}
