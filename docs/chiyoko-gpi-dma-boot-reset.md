# chiyoko: 偶发两次进入 systemd-boot / 启动硬复位（GPI DMA 回归）

> 调查日期：2026-08-05
> 结论：上游已有修复（已合入 v7.2），等待内核更新即可，无需本地改动。

## 现象

chiyoko（Lenovo ThinkPad X13s, aarch64）偶尔重启后需要进两次 systemd-boot：
第一次选择启动项后滚动日志，随后突然关机，看起来像第二次开机才成功进入系统。

## 日志证据

- `journalctl --list-boots` 显示多次短命启动：
  - boot -1（8/5 22:27:06）在单调时钟 **6.534s** 处死亡，最后一条是
    `Time spent on flushing ... for 934 entries`，没有 panic 或正常关机序列
    → 固件级硬复位。
  - boot -6（8/1 01:35）同样在 **6.38s** 死亡。
- 下一次成功启动时 journald 报告 `system.journal corrupted or uncleanly shut down`，
  证实前一次是非正常断电。
- 崩溃点恰在 udev coldplug / 设备探测窗口；pstore 为空，watchdog 未激活。

注意：启动早期日志时间戳停留在固件纪元（如 “Mar 18 03:55:52”），
RTC 驱动约 8s 后才注册，排查时需要用 `-o short-monotonic` 对齐。

## 根因

**GPI DMA 上游回归**：

- 2025-08 上游合入 “Enable GPI DMA for sc8280xp”（Pengyu Luo），
  但 `sc8280xp.dtsi` 使用了 `dma-channel-mask = <0xfff>/<0x1fff>`（全部通道）。
- X13s 实际只有 HLOS 可用的通道 0–1（Windows DSDT 显示 `0x3`）。
- GPI 驱动被“公共”DMA 消费者（如 raid456/async_tx）触发遍历所有通道，
  访问非法硬件 → 固件/hypervisor 级 hang/reset。

本机验证：

- 运行中 DTB（内核自带，systemd-boot `devicetree /EFI/nixos/*-dtbs-filtered-*`）
  掩码为 `0xfff/0x1fff/0xfff`。
- 7.1.6 内核源 DTB 解析得 `[4095, 8191, 4095]` —— 坏掩码仍在。
- `CONFIG_QCOM_GPI_DMA=m`，`gpi` 模块已加载。

旁证：

- [Ubuntu bug 2142403](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/2142403)：
  Ubuntu 26.04 Resolute 在 gpi-dma 处卡死，Ubuntu 在 7.0.0-12.12 回退该 DT 改动修复。
- [Fedora 论坛帖子](https://discussion.fedoraproject.org/t/fedora-43-44-beta-aarch64-wont-boot-on-thinkpad-x13s/183074/13)：
  同一现象。

## 上游修复状态

### 1. 驱动侧修复（关键，已合入）

`dmaengine: qcom: gpi: set DMA_PRIVATE capability`（Icenowy Zheng）

- [commit 4e351f408743354d54ee1af5193fc78234f2044e](https://github.com/torvalds/linux/commit/4e351f408743354d54ee1af5193fc78234f2044e)
- 把 GPI DMA 标记为私有 DMA 引擎，公共消费者（raid456/async_tx）不再遍历其通道。
- 2026-06-08 由 Vinod Koul 合入 dmaengine 树。
- **v7.1 没有该修复；v7.2-rc6 已有**（`drivers/dma/qcom/gpi.c` 中
  `dma_cap_set(DMA_PRIVATE, ...)`）。
- 截至调查日未见 stable 7.1.y 回传。

### 2. DTS 侧加固（仍在评审，未合入）

`arm64: dts: qcom: sc8280xp: set GPI DMA channels according to DSDT`
（[邮件线程](https://lore.kernel.org/lkml/20260602081451.3808833-1-zhengxingda@iscas.ac.cn/)）

- 按各板 DSDT 设置 `dma-channel-mask = <0x3>`，并从 dtsi 移除错误掩码。
- 2026-06-02 提交，6/19 仍有评审讨论，截至调查日未合入 mainline。
- 属于防御性加固；驱动侧 `DMA_PRIVATE` 才是关键修复。

## 处理决定

**等待 nixos-unstable 内核升到 v7.2**，届时：

```bash
just up && just switch-nixos chiyoko
```

升级后验证：

```bash
uname -r                          # 应 ≥ 7.2
journalctl --list-boots           # 不再出现 6~7 秒死亡的短命 boot
journalctl -b | rg 'uncleanly shut down|corrupted'   # 应无此字样
```

## 备选本地方案（如等待太久再考虑）

1. `boot.blacklistedKernelModules = [ "gpi" ]` —— 最简单，
   但可能影响走 GPI DMA 的 SPI/I2C 外设，需观察触控等是否正常。
2. 本地 DTB 覆写 `dma-channel-mask = <0x3>` —— 与上游修复思路一致。
3. 沿用 Ubuntu 的回退 patch（移除 sc8280xp GPI DMA 的 DT 改动）。

---

另见 [chiyoko 相机不可用（camcc GDSC）](./chiyoko-camera-gdsc.md)。
