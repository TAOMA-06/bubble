# BeadWorksNative（拼豆工坊 · 原生 iOS）

轻量原生 iOS 拼豆游戏，使用 **SwiftUI + Canvas + PhotosPicker**，无第三方依赖，`Cmd+R` 即可在模拟器运行。这是当前的**轻量交付主线**；Unity 版本（`../BeadWorksUnity/`）暂停投入但保留在仓库中。

权威设计：[`docs/compose/specs/2026-08-30-beadworks-ios-mvp.md`](../docs/compose/specs/2026-08-30-beadworks-ios-mvp.md)。

## 快速开始

```bash
open BeadWorks.xcodeproj
```

在 Xcode 中选择一个 iOS 模拟器，`Cmd+R` 运行。首屏即游戏主菜单，无需任何额外配置或导出步骤。

- 最低系统版本：iOS 17
- Bundle ID：`com.beadworks.native`
- 依赖：无第三方库（SwiftUI、PhotosUI、Photos、CoreGraphics/UIKit、XCTest）

### 重新生成工程文件

`BeadWorks.xcodeproj` 可由 [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`project.yml`）或仓库内脚本生成：

```bash
brew install xcodegen   # 如尚未安装
xcodegen generate

# 或
python3 scripts/generate_pbxproj.py
```

## 项目结构

```
BeadWorksNative/
├── project.yml
├── BeadWorks.xcodeproj/
├── scripts/generate_pbxproj.py
├── BeadWorks/
│   ├── BeadWorksApp.swift
│   ├── App/                 # 根视图、导航、UI 测试启动参数
│   ├── Domain/              # BeadBoard / BeadColor / BeadPattern / GalleryWork / 工具与成品类型
│   ├── Features/            # Home、Editor、PhotoImport、Patterns、FinishedWork、Gallery、Splash
│   ├── Services/            # 存档、图片转模板、内置图纸、匹配、分享、相册
│   ├── Rendering/           # Canvas 珠子与 pegboard
│   ├── Support/             # 主题、Hex、系统分享页
│   ├── Views/               # 跨页组件
│   └── Assets.xcassets/
├── BeadWorksTests/
└── BeadWorksUITests/
```

## 核心体验

- **自由创作**：默认 29×29，可选 16×16；摆豆 / 擦除 / 取色；撤销重做；双指缩放。
- **导入图片**：`PhotosPicker` → 后台 `PhotoTemplateService` 居中裁剪、按 16/24/32/48 降采样、就近取色 → 预览后进入编辑器，未摆放格子显示引导环，可开纠错提示。
- **示例图纸**：爱心、星星、国风云纹、奶茶杯、应援字牌（16×16 复刻，主菜单次级入口）。
- **熨烫**：轻熔 / 全熔离屏渲染（不做热量物理）。
- **成品**：命名、成品类型（冰箱贴 / 钥匙扣 / 挂件）、保存作品库、1080×1920 分享卡、写入系统相册。
- **作品库**：浏览、详情、重新编辑、删除。离开编辑器时自动保存一份草稿。

## 测试

```bash
xcodebuild -project BeadWorks.xcodeproj -scheme BeadWorks \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BeadWorksTests test

xcodebuild -project BeadWorks.xcodeproj -scheme BeadWorks \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BeadWorksUITests test
```

UI 测试启动参数：

- `-uiTestResetStorage`：清空作品库与草稿，并跳过启动闪屏。
- `-uiTestFixtureImage`：导入页显示「使用测试图片」，绕开系统相册选择器。

## 与 Unity 版本的关系

色板与图片转模板算法对齐 Unity 的 `bead_palette.json` / `PhotoToPatternConverter`；内置图纸对齐 `BuiltinPatternFactory`。原生版不实现 3D、热量熨烫或关卡。
