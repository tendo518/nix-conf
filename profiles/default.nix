# ============================================================================
# Host Configuration Profiles
#
# Reusable profiles for common host configurations.
# Profiles define default module lists that can be extended per-host.
#
# Usage in host configs:
#   let
#     profiles = import ../profiles/default.nix;
#   in
#   {
#     flake.modules.nixos."nixosConfigurations/my-host" = config.flake.lib.mkHost {
#       modules = profiles.desktop.modules ++ [
#         "my-host-system"
#         "my-host-home"
#         "desktop-environments/plasma"
#       ];
#     };
#   };
# ============================================================================

{
  # Base profile for all workstations
  # Includes core functionality without GUI
  workstation = {
    modules = [
      "core" # All core/* modules
      "system" # All system/* modules
      "development"
      "apps"
      "networking"
    ];
  };

  # Desktop workstation with GUI
  # Includes desktop environment modules
  # Note: User must select specific DE (plasma, gnome, niri, etc.)
  desktop = {
    modules = [
      "core"
      "system"
      "development"
      "apps"
      "networking"
      "desktop"
      # "desktop-environments"  # Do not include all DEs; user selects specific DE
    ];
  };

  # Laptop-specific profile
  # Includes power management and laptop-specific modules
  laptop = {
    modules = [
      "core"
      "system"
      "development"
      "apps"
      "networking"
    ];
  };

  # Darwin-specific base profile
  darwin-base = {
    modules = [
      "core"
      "system"
      "development"
      "networking"
    ];
  };

  # Darwin laptop profile
  darwin-laptop = {
    modules = [
      "core"
      "system"
      "development"
      "networking"
    ];
  };
}
