# BeadWorks（拼豆工坊）

拼豆手游，使用 **Unity（URP + C#）** 作为游戏内核。UI、工作台、存档与分享均在 Unity 工程内实现。

## 项目结构

```
bubble/
├── BeadWorksUnity/     # 游戏源码（Unity 工程，唯一运行时）
├── docs/               # 设计与计划文档（历史参考）
└── README.md
```

## 快速开始

### 编辑器内测试

1. 安装 [Unity Hub](https://unity.com/download) 与 **Unity 6000.5.2f1**（或 README 中标注的版本）
2. 用 Hub 打开 `BeadWorksUnity/`
3. 打开 `Assets/Scenes/WorkshopScene.unity`，点击 **Play**

详见 [BeadWorksUnity/README.md](BeadWorksUnity/README.md)。

### iOS 模拟器 / Xcode

```bash
cd BeadWorksUnity
./build-ios-simulator.sh
```

导出 `Builds/iOSSimulator/Unity-iPhone.xcodeproj`，可在 Xcode 中选择模拟器运行。

详见 [BeadWorksUnity/README-iOS-Simulator.md](BeadWorksUnity/README-iOS-Simulator.md)。

## 架构说明

| 层级 | 实现 |
|------|------|
| 游戏内核 | Unity（`WorkshopController`、网格、工具、熨烫） |
| 前端 UI | Unity UGUI / TextMeshPro（`Assets/Scripts/UI/`） |
| 数据 | `bead_palette.json`、本地作品库 JSON + PNG |
| iOS 壳 | Unity 导出 `Unity-iPhone.xcodeproj`（无需单独 SwiftUI 壳） |

## 历史说明

早期曾用 SwiftUI 实现一版 MVP，已移除。当前以 `BeadWorksUnity/` 为唯一游戏代码来源。
