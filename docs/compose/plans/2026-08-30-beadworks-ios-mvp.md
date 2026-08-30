# 拼豆工坊 iOS 原生 MVP 重构计划（2026-08-30）

> 源计划路径（本机 Hermes，未进 git）：`.hermes/plans/2026-08-30_204842-beadworks-ios-mvp.md`
> 仓库内无法读取该文件，本计划按游戏设计文档 + 现有 `BeadWorksNative` 轻量切片还原，并作为本次重构的实施记录。

## 目标

把扁平的 SwiftUI 原型收成可维护的原生 MVP：功能分层、补齐设计主线缺口（示例图纸、撤销、分享、作品库回编、草稿），保持无第三方依赖、iOS 17+、现有 UI 测试标识可用。

## 结构

```
BeadWorksNative/BeadWorks/
├── App/            # 入口、导航、启动参数
├── Domain/         # 棋盘、色板、图纸、作品、工具、成品类型
├── Features/       # Home / Editor / PhotoImport / Patterns / FinishedWork / Gallery / Splash
├── Services/       # 存档、转换、内置图纸、匹配、分享、相册
├── Rendering/      # Canvas 珠子与 pegboard
├── Support/        # 主题、修饰器、系统分享页
└── Views/          # 跨页组件
```

## 默认取舍（原计划未入库时的决定）

1. 不把 Unity 3D / 热量熨烫搬进原生版。
2. 成品类型只做 2D 标签与分享卡，不做 3D 旋转查看。
3. 内置五张图纸从 Unity `BuiltinPatternFactory` 移植。
4. 撤销按整段拖动画一笔回退。
5. 草稿只有一份，覆盖写入。
6. Unity 工程继续保留、不删除。

若这些和 Hermes 原文不一致，应在评审里改，而不是静默覆盖。
