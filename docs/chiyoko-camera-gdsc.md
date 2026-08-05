# chiyoko: 相机（OV5675）当前不可用（camcc GDSC 回归）

> 调查日期：2026-08-05
> 结论：相机不可用，根因是 camcc `titan_top_gdsc` 无法上电；上游已有修复在评审、
> 尚未合入主线，预计 v7.3。处理决定：先不改，等上游。

## 现象

kamoso 打开相机失败（`camera ready: false`），内核报
`qcom-camss: Failed to start media pipeline: -32`。

## 验证结果（2026-08-05）

- 设备节点齐全：`/dev/video0-31`、`/dev/media0`（root:video + uaccess ACL）。
- OV5675 绑定正常：i2c `27-0010`，`qcom_camss` / `ov5675` 模块已加载。
- libcamera 可见：`cam --list` → “Internal front camera”。
- 实际抓帧失败：libcamera 配置 2584x1944 管线后 `/dev/video0` STREAMON 报错，
  内核日志：

  ```
  titan_top_gdsc status stuck at 'off'
  WARNING: drivers/clk/qcom/gdsc.c:178 gdsc_toggle_logic
  qcom-camss ac5a000.camss: Failed to power up pipeline: -110 / -22
  ```

  调用栈：`csiphy_set_power → pm_runtime_resume → genpd_power_on → gdsc_enable`。
- kamoso（23:15）与直接 libcamera 抓帧（23:26/23:28）均稳定复现。

## 根因

- camcc 的 `titan_top_gdsc`（相机顶层电源域）无法切换；
- GDSC 切换所必需的 `camcc_gdsc_clk` 在 clk/pmdomain 子系统引入 sync_state
  支持后被关闭（unused clock 处理）；
- 注意：`clk_ignore_unused` 启动参数无法避免此问题。

## 上游状态

Brian Masney（Red Hat）2026-06-26 ~ 07-08 提交三个候选修复（均基于 X13s 实测）：

1. `clk: qcom: camcc-sc8280xp: enable ALWAYS_ON for titan_top_gdsc`
   （2026-06-26）
2. `clk: qcom: camcc-sc8280xp: add CLK_IGNORE_UNUSED to camcc_gdsc_clk`
   （2026-07-01，Konrad 建议改为 unregister 方案）
3. `clk: qcom: camcc-sc8280xp: unregister CAMCC_GDSC_CLK`（2026-07-08）

截至 v7.2-rc6，三个补丁均未合入 mainline（`camcc-sc8280xp.c` 无任何改动）。
相机修复预计 v7.3，或视 stable 回传情况提前。

## 处理决定

- **先不改**，等 v7.3（或 7.2.y/7.1.y stable 回传）。
- 如急用相机：可对内核打 unregister 补丁（经 nixpkgs overlay），待评估。

升级后验证：

```bash
uname -r                       # 应为 v7.3 及以上
journalctl -b -k | rg -i 'gdsc|camss|power up pipeline'   # 不应再报错
/nix/store/*libcamera*/bin/cam --list
/nix/store/*libcamera*/bin/cam -c '<camera-id>' --capture=1 --file
```

## 与 GPI DMA 问题的关系

独立问题：v7.2 只修双启动（GPI DMA），相机需等 v7.3。
另见 [chiyoko GPI DMA 回归](./chiyoko-gpi-dma-boot-reset.md)。
