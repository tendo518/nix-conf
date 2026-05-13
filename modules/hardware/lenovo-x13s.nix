{
  flake.modules.nixos."hardware/lenovo-x13s" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.boot.kernelPackages) kernel;

      dtbName = "sc8280xp-lenovo-thinkpad-x13s.dtb";
      dtb = "${kernel}/dtbs/qcom/${dtbName}";
      dtbEfiPath = "dtbs/x13s-${kernel.version}.dtb";
      wifiMac = "e6:65:38:52:22:aa";
      bluetoothMac = "E6:25:18:22:44:AB";
    in
    {
      boot = {
        loader.systemd-boot.extraFiles."${dtbEfiPath}" = dtb;

        kernelParams = [
          "dtb=${dtbEfiPath}"
          "clk_ignore_unused"
          "pd_ignore_unused"
          "arm64.nopauth"
        ];

        kernelModules = [
          "nvme"
          "phy-qcom-qmp-pcie"
          "pcie-qcom"
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
          ExecStart = "${pkgs.util-linux}/bin/script -q -c '${pkgs.bluez}/bin/btmgmt --index 0 public-addr ${bluetoothMac}'";
        };
      };

      # networking.modemmanager.fccUnlockScripts = [
      #   {
      #     id = "105b:e0c3";
      #     path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/105b";
      #   }
      # ];

      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="dma_heap", KERNEL=="linux,cma", GROUP="video", MODE="0660"
        ACTION=="add", SUBSYSTEM=="dma_heap", KERNEL=="system", GROUP="video", MODE="0660"
        ACTION=="add", SUBSYSTEM=="net", KERNELS=="0006:01:00.0", RUN+="${pkgs.iproute2}/bin/ip link set dev $name address ${wifiMac}"
      '';
    };
}
