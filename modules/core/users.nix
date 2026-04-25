{
  flake.modules.nixos."core/users" =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      user = config.host.user;
      username = user.name;
    in
    {
      # Declare age secrets for user password and root password
      age.secrets =
        lib.optionalAttrs (user.passwordSecret != null) {
          "${username}-password" = {
            file = "${inputs.self}/secrets/${user.passwordSecret}";
            owner = "root";
            group = "root";
            mode = "0400";
          };
        }
        // {
          root-password = {
            file = "${inputs.self}/secrets/root-password.age";
            owner = "root";
            group = "root";
            mode = "0400";
          };
        };

      users.mutableUsers = false;

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
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    {
      users.users =
        let
          user = config.host.user;
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
