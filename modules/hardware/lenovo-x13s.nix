# ThinkPad X13s (Qualcomm SC8280XP / Snapdragon 8cx Gen 3)
# Aligned with nixos-hardware/lenovo/thinkpad/x13s
{ config, lib, pkgs, ... }:
let
  wifiMac = "e6:65:38:52:22:aa";
  bluetoothMac = "E6:25:18:22:44:AB";
in
{
  flake.modules.nixos."hardware/lenovo-x13s" =
    { config, lib, pkgs, ... }:
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

      # TPM is non-functional on X13s — mask the service to avoid 90s timeout
      systemd.services.systemd-tpm2-setup = {
        enable = false;
        unitConfig.ConditionPathExists = "";
      };

      hardware.enableRedistributableFirmware = true;

      systemd.services.bluetooth-x13s-mac = {
        wantedBy = [ "multi-user.target" ];
        before = [ "bluetooth.service" ];
        requiredBy = [ "bluetooth.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.util-linux}/bin/script -q -c '${pkgs.bluez}/bin/btmgmt --index 0 public-addr ${bluetoothMac}'";
        };
      };

      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="dma_heap", KERNEL=="linux,cma", GROUP="video", MODE="0660"
        ACTION=="add", SUBSYSTEM=="dma_heap", KERNEL=="system", GROUP="video", MODE="0660"
        ACTION=="add", SUBSYSTEM=="net", KERNELS=="0006:01:00.0", RUN+="${pkgs.iproute2}/bin/ip link set dev $name address ${wifiMac}"
      '';

      # X13s TPM is non-functional — mask device units to avoid 90s timeout
      systemd = {
        services."systemd-tpm2-setup".masked = true;
        services."systemd-pcrmachine".masked = true;
        targets."tpm2".masked = true;
        units."dev-tpm0.device".masked = true;
        units."dev-tpmrm0.device".masked = true;
      };
    };
}
