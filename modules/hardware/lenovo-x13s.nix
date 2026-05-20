# ThinkPad X13s (Qualcomm SC8280XP / Snapdragon 8cx Gen 3)
# Aligned with nixos-hardware/lenovo/thinkpad/x13s
{
  config,
  lib,
  pkgs,
  ...
}:
let
  wifiMac = "98:d6:a5:99:05:a7";
  bluetoothMac = "D0:10:28:00:75:95";
in
{
  flake.modules.nixos."hardware/lenovo-x13s" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      hardware.deviceTree = {
        enable = true;
        filter = lib.mkDefault "sc8280xp-lenovo-thinkpad-x13s*.dtb";
        name = lib.mkDefault "qcom/sc8280xp-lenovo-thinkpad-x13s.dtb";
      };

      boot = {
        # No dtb= param — the X13s firmware provides the device tree via
        # the UEFI configuration table, same as how Ubuntu boots.
        kernelParams = [
          "clk_ignore_unused"
          "pd_ignore_unused"
          "arm64.nopauth"
          "console=tty0"
        ];

        initrd.kernelModules = [
          "nvme"
          "phy-qcom-qmp-pcie"
          # "pcie-qcom" # no longer a module since 6.12
          "i2c-core"
          "i2c-hid"
          "i2c-hid-of"
          "i2c-qcom-geni"
          "leds_qcom_lpg"
          "pwm_bl"
          "qrtr"
          "pmic_glink_altmode"
          "gpio_sbu_mux"
          "phy-qcom-qmp-combo"
          "gpucc_sc8280xp"
          "dispcc_sc8280xp"
          "phy_qcom_edp"
          "panel-edp"
          "msm"
          "btrfs"
        ];

        kernelModules = [
          "phy-qcom-qmp-pcie"
          "i2c-qcom-geni"
          "i2c-hid"
          "i2c-hid-of"
          "leds_qcom_lpg"
          "pwm_bl"
          "qrtr"
          "pmic_glink_altmode"
          "gpio_sbu_mux"
          "phy-qcom-qmp-combo"
          "gpucc_sc8280xp"
          "dispcc_sc8280xp"
          "phy_qcom_edp"
          "panel-edp"
          "msm"
        ];
      };

      hardware.enableRedistributableFirmware = true;

      systemd.services.bluetooth-x13s-mac = {
        wantedBy = [ "multi-user.target" ];
        before = [ "bluetooth.service" ];
        requiredBy = [ "bluetooth.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.bluez}/bin/btmgmt --index 0 public-addr ${bluetoothMac}";
        };
      };

      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="dma_heap", KERNEL=="linux,cma", GROUP="video", MODE="0660"
        ACTION=="add", SUBSYSTEM=="dma_heap", KERNEL=="system", GROUP="video", MODE="0660"
        ACTION=="add", SUBSYSTEM=="net", KERNELS=="0006:01:00.0", RUN+="${pkgs.iproute2}/bin/ip link set dev $name address ${wifiMac}"
      '';

      # X13s TPM is non-functional — disable all TPM2 systemd units to avoid 90s boot timeout
      # BIOS does not have an option to disable TPM
      # systemd.tpm2.enable = false removes upstream TPM units entirely;
      # enable=false on individual units creates a symlink to /dev/null (same as systemctl mask)
      boot.initrd.systemd.tpm2.enable = false;
      systemd.tpm2.enable = false;
      systemd.services.systemd-pcrmachine.enable = false;
    };
}
