# BeadWorks（拼豆工坊）

拼豆手游。当前的**轻量交付主线**是原生 iOS（**SwiftUI + Canvas + PhotosPicker**，`BeadWorksNative/`），核心玩法围绕两条主线——**自由创作**与**导入图片生成拼豆模板**——展开，辅以拼豆编辑、熨烫、成品与作品库的完整闭环。此前的 Unity（URP + C#）工程（`BeadWorksUnity/`）暂停投入，保留在仓库中不删除。

## 项目结构

```
bubble/
├── BeadWorksNative/    # 游戏源码（原生 iOS SwiftUI 工程，当前主线）
├── BeadWorksUnity/     # 游戏源码（Unity 工程，暂停投入，保留）
├── docs/               # 设计与计划文档
└── README.md
```

## 快速开始

### 原生 iOS（当前主线）

```bash
open BeadWorksNative/BeadWorks.xcodeproj
```

选择模拟器，`Cmd+R` 直接运行——无需导出、无第三方依赖、无 Development Console。详见 [BeadWorksNative/README.md](BeadWorksNative/README.md)。

### Unity（暂停投入，仍可运行）

1. 安装 [Unity Hub](https://unity.com/download) 与 **Unity 6000.5.2f1**（或 README 中标注的版本）
2. 用 Hub 打开 `BeadWorksUnity/`
3. 打开 `Assets/Scenes/WorkshopScene.unity`，点击 **Play**

详见 [BeadWorksUnity/README.md](BeadWorksUnity/README.md)。iOS 模拟器/真机导出见 [BeadWorksUnity/README-iOS-Simulator.md](BeadWorksUnity/README-iOS-Simulator.md) 与 [BeadWorksUnity/README-iOS-Device.md](BeadWorksUnity/README-iOS-Device.md)。

## 架构说明

| 层级 | 原生 iOS（主线） | Unity（暂停） |
|------|------|------|
| 游戏内核 | SwiftUI + Canvas（`BoardEditorView` 等） | `WorkshopController`、网格、工具、熨烫 |
| 数据 | `BeadColor` 固定色板、本地作品库 JSON + PNG | `bead_palette.json`、本地作品库 JSON + PNG |
| 图片转模板 | `PhotoTemplateService`（纯 Swift，可单测） | `PhotoToPatternConverter` |
| iOS 壳 | 原生 Xcode 工程，`Cmd+R` 直接运行 | Unity 导出 `Unity-iPhone.xcodeproj` |

## 历史说明

早期曾用 SwiftUI 实现一版 MVP 后转向 Unity；现已回到原生 SwiftUI 作为轻量交付主线，Unity 版本保留供参考、暂停继续投入。

设计文档 `docs/compose/specs/2026-06-12-perler-bead-game-design.md` 仍以 Unity 实现描述较完整的游戏愿景；原生 iOS 版本是同一自由创作/导入图片主线的轻量首版实现。
