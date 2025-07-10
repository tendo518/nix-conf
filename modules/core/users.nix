{
  flake.modules.nixos."core/users" =
    {
      config,
      hostContext,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (hostContext) user;
      username = user.name;
    in
    {
      # Declare age secrets for user password and root password
      age.secrets =
        lib.optionalAttrs (user.passwordSecret != null) {
          "${username}-password" = {
            file = ../../secrets + "/${user.passwordSecret}";
            owner = "root";
            group = "root";
            mode = "0400";
          };
        }
        // {
          root-password = {
            file = ../../secrets/root-password.age;
            owner = "root";
            group = "root";
            mode = "0400";
          };
        };

      # users.mutableUsers = false;

      users.users = lib.mkMerge [
        {
          "${username}" = {
            isNormalUser = true;
            shell = pkgs.${user.shell} or pkgs.bash;
            extraGroups = lib.optionals user.trusted [ "wheel" ] ++ user.extraGroups;
            openssh.authorizedKeys.keys = user.sshPubKey;
          }
          // lib.optionalAttrs (user.passwordSecret != null) {
            hashedPasswordFile = config.age.secrets."${username}-password".path;
          };
        }
        {
          root.hashedPasswordFile = config.age.secrets.root-password.path;
        }
      ];
    };

  flake.modules.darwin."core/users" =
    {
      hostContext,
      pkgs,
      ...
    }:
    {
      users.users =
        let
          inherit (hostContext) user;
          username = user.name;
        in
        {
          "${username}" = {
            name = username;
            home = "/Users/${username}";
            shell = pkgs.${user.shell} or pkgs.zsh;
            openssh.authorizedKeys.keys = user.sshPubKey;
          };
        };
    };
}
