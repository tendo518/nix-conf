{
  flake.modules.nixos."hardware/nvidia" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # Enable OpenGL
      hardware.graphics = {
        enable = true;
      };

      # Load nvidia driver for Xorg and Wayland
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        # Modesetting is required.
        modesetting.enable = true;

        nvidiaPersistenced = true;

        # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
        # Enable this if you have graphical corruption issues or application crashes after waking
        # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
        # of just the bare essentials.

        # failed to boot on some systems (with PCI-E extension cable)
        powerManagement.enable = lib.mkDefault true;

        # Fine-grained power management. Turns off GPU when not in use.
        # Experimental and only works on modern Nvidia GPUs (Turing or newer).
        powerManagement.finegrained = lib.mkDefault false;

        # Use the NVidia open source kernel module (not to be confused with the
        # independent third-party "nouveau" open source driver).
        # Support is limited to the Turing and later architectures. Full list of
        # supported GPUs is at:
        # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
        # Only available from driver 515.43.04+
        open = lib.mkDefault true;

        # Enable the Nvidia settings menu,
        # accessible via `nvidia-settings`.
        nvidiaSettings = false;

        # Optionally, you may need to select the appropriate driver version for your specific GPU.
        # cache only build for stable kernel ...
        # package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      # Make NVIDIA driver + CUDA libraries available to precompiled binaries via nix-ld
      programs.nix-ld.enable = lib.mkDefault true;
      programs.nix-ld.libraries = [
        config.hardware.nvidia.package
        pkgs.cudaPackages.cudatoolkit
        pkgs.stdenv.cc.cc
      ];

      environment.systemPackages = [ pkgs.cudaPackages.cudatoolkit ];

      environment.sessionVariables = {
        CUDA_HOME = pkgs.cudaPackages.cudatoolkit;
        CUDA_PATH = pkgs.cudaPackages.cudatoolkit;
        # Triton bypasses ld.so and calls /sbin/ldconfig directly; tell it where libcuda.so lives
        TRITON_LIBCUDA_PATH = "/run/opengl-driver/lib";
      };
      # ensure sunshine works
      services.sunshine.package = pkgs.sunshine.override { cudaSupport = true; };

      # hardware.nvidia-container-toolkit.enable = true;  # when nvidia driver update, version mismatch error when restart, lead to switch failure
    };
}
