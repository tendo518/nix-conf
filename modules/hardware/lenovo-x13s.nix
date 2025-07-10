# ThinkPad X13s (Qualcomm SC8280XP / Snapdragon 8cx Gen 3)
# Aligned with nixos-hardware/lenovo/thinkpad/x13s
_:
let
  wifiMac = "98:d6:a5:99:05:a7";
  bluetoothMac = "D0:10:28:00:75:95";
in
{
  flake.modules.nixos."hardware/lenovo-x13s" =
    {
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
      # 2026-08: sc8280xp GPI DMA 回归 —— dtsi 的 dma-channel-mask 用了 0xfff/0x1fff
      # 全部通道，而 X13s 实际只有 HLOS 可用的通道 0-1（DSDT 显示 0x3）。
      # raid456/async_tx 等公共 DMA 消费者触发遍历非法通道 → 偶发固件级硬复位
      # （表现为重启要进两次 systemd-boot）。驱动侧修复（DMA_PRIVATE）已合入 v7.2，
      # 但 v7.2 在本机仍无法稳定启动（多次硬复位，只能退回 7.1.x）。DT 掩码系列
      # 仍在评审。若需本地覆写，hardware.deviceTree.overlays 是天然落点。

      boot = {
        # 7.2 在 X13s 上无法稳定启动，钉在 7.1 分支直到上游修复可用。
        kernelPackages = pkgs.linuxPackages_7_1;
        # hardware.deviceTree 会让 systemd-boot 加载内核自带的 DTB
        # （启动项里的 `devicetree /EFI/nixos/*-dtbs-filtered-*`），因此不需要 dtb= 参数。
        # 固件通过 UEFI configuration table 提供的 DT 只在未指定 DTB 时才会被使用。
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

      networking.useDHCP = lib.mkDefault true;
      # https://wiki.gentoo.org/wiki/NetworkManager#Failed_to_add_new_connection:_802.1x_connections_must_have_IWD_provisioning_files
      networking.networkmanager.wifi.backend = "wpa_supplicant";

      systemd.services.bluetooth-x13s-mac = {
        wantedBy = [ "multi-user.target" ];
        before = [ "bluetooth.service" ];
        requiredBy = [ "bluetooth.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.util-linux}/bin/script -q -c '${pkgs.bluez}/bin/btmgmt --index 0 public-addr ${bluetoothMac}' /dev/null";
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
