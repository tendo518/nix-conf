{ lib }:
{
  options.host = {
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "The hostname of the machine";
    };
    user = lib.mkOption {
      type = lib.types.submoduleWith {
        modules = [
          {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Username";
              };
              email = lib.mkOption {
                type = lib.types.str;
                description = "User email";
              };
              trusted = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Whether the user is trusted (wheel/admin)";
              };
              sshPubKey = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "SSH public keys";
              };
              shell = lib.mkOption {
                type = lib.types.str;
                default = "bash";
                description = "User shell (e.g. fish, zsh)";
              };
              homeStateVersion = lib.mkOption {
                type = lib.types.str;
                description = "Home Manager state version";
              };
              passwordSecret = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Age secret filename for user password";
              };
              extraGroups = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Additional groups for the user";
              };
            };
          }
        ];
        specialArgs.userVars = lib.mkDefault { };
      };
      description = "Single user configuration";
    };
  };
}
