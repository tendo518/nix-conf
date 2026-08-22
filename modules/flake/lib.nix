{
  config,
  framework,
  lib,
  ...
}:
{
  options.hostBuilder = lib.mkOption {
    type = lib.types.unspecified;
    default = { };
    description = "Host builder used by NixOS/Darwin output modules";
  };

  config.hostBuilder = framework.mkHostConfigurations config;
}
