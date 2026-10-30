# Changelog / 更新日志

All notable changes to this mod are recorded here.

本文件记录该模组的重要新增、调整与修复。

## 0.1.0-alpha — 2026-10-06

### Added / 新增

- Added the `Preservative.PreservativeBottle` item with a dedicated static inventory icon.
- 新增 `Preservative.PreservativeBottle` 防腐剂物品及独立静态物品图标。
- Added procedural spawns to selected kitchen, grocery, canning, janitorial and garage containers.
- 新增厨房、杂货店、装罐用品、清洁用品及车库容器刷新。
- Added same-direct-container food preservation with a default 40% spoilage-speed reduction.
- 新增同一直接容器防腐效果，默认将食物腐坏速度降低 40%。
- Added a seven-active-day default bottle lifetime; multiple bottles do not stack.
- 新增默认七个有效游戏日的瓶子寿命，多瓶效果不叠加。
- Added freezer exclusion: bottles provide no extra effect and consume no lifetime in freezers.
- 新增冷冻柜排除规则：不提供额外效果，也不消耗防腐剂寿命。
- Added delayed lethal poisoning after consumption, configurable through sandbox settings.
- 新增食用后延迟致死效果，并可通过沙盒设置调整。
- Added right-click food inspection for type, age, stale/rotten thresholds and scripted poison risk.
- 新增右键食物查询：类型、年龄、变质/腐坏阈值及脚本毒性风险。
- Added right-click remaining-lifetime inspection for preservative bottles.
- 新增右键查看防腐剂剩余有效天数和小时数。
- Added English and Simplified Chinese translations.
- 新增英文及简体中文本地化。
- Added configurable shelf-life multiplier, preservation strength, bottle lifetime, player-inventory behavior, lethality and debug logging.
- 新增全局保质期、防腐强度、瓶子寿命、玩家物品栏生效、致死效果和调试日志设置。
- Added static Workshop artwork, two user-supplied showcase images and an eight-frame looping promotional GIF.
- 新增创意工坊静态素材、两张用户提供的展示图及八帧循环宣传 GIF。

### Packaging / 打包

- Targeted Project Zomboid Build 42.21 with `42` and `common` versioned directories.
- 面向 Project Zomboid Build 42.21，采用 `42` 与 `common` 版本目录结构。
- Marked the release as `0.1.0-alpha`; runtime testing remains in progress.
- 版本标记为 `0.1.0-alpha`，仍处于游戏内测试阶段。

### Known limitations / 已知限制

- Procedural loot frequency, multiplayer synchronization and compatibility with other food-aging mods still require in-game verification.
- 地图刷新概率、多人同步以及与其他食物老化模组的兼容性仍需游戏内验证。
- The animated GIF is promotional artwork; the in-game inventory texture remains a static PNG for compatibility.
- 动态 GIF 仅用作宣传素材；为保证兼容性，游戏内物品贴图仍为静态 PNG。
