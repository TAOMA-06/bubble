# BeadWorksNative（拼豆工坊 · 原生 iOS）

轻量原生 iOS 拼豆游戏，使用 **SwiftUI + Canvas + PhotosPicker**，无第三方依赖，`Cmd+R` 即可在模拟器运行。这是当前的**轻量交付主线**；Unity 版本（`../BeadWorksUnity/`）暂停投入但保留在仓库中。

## 快速开始

```bash
open BeadWorks.xcodeproj
```

在 Xcode 中选择一个 iOS 模拟器，`Cmd+R` 运行。首屏即游戏主菜单，无需任何额外配置或导出步骤。

- 最低系统版本：iOS 17
- Bundle ID：`com.beadworks.native`
- 依赖：无第三方库（SwiftUI、PhotosUI、CoreGraphics/UIKit、XCTest）

### 重新生成工程文件

`BeadWorks.xcodeproj` 由 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 根据 `project.yml` 生成并已提交到仓库，正常情况下无需重新生成。如果修改了 `project.yml`（例如新增文件、调整 target 设置），重新生成：

```bash
brew install xcodegen   # 如尚未安装
xcodegen generate
```

## 项目结构

```
BeadWorksNative/
├── project.yml                 # XcodeGen 工程描述
├── BeadWorks.xcodeproj/         # 生成的 Xcode 工程（已提交）
├── BeadWorks/                   # App target 源码
│   ├── BeadWorksApp.swift       # App 入口
│   ├── Models/                  # BeadColor / BeadBoard / BeadPattern / GalleryWork / ToolMode
│   ├── Services/                # BoardStore（本地存档）/ PhotoTemplateService（图片转模板）
│   ├── Views/                   # HomeView / BoardEditorView / PhotoImportView / FinishedWorkView / GalleryView
│   ├── Support/                 # 主题色、Hex 颜色解析
│   └── Assets.xcassets/
├── BeadWorksTests/              # 单元测试（模型 + 服务）
└── BeadWorksUITests/            # UI 测试（主菜单、拼豆、导入、熨烫、作品库）
```

## 核心体验

- **自由创作**：默认 29×29，可选 16×16 的空白拼豆板，直接摆豆。
- **导入图片**：`PhotosPicker` 选图 → `PhotoTemplateService` 居中裁剪、按 16/24/32/48 网格降采样、按固定色板就近取色 → 预览确认后进入编辑器，模板以浅色引导环显示在尚未摆放的格子上。
- **拼豆编辑**：`Canvas` 绘制 pegboard 网格、珠子、模板引导环；支持放置/橡皮擦工具、清空、拖动连续摆放。
- **熨烫**：把当前拼豆板渲染为"融合"效果图（`ImageRenderer` 离屏渲染），不做物理模拟。
- **作品库**：本地保存的成品（JSON 元数据 + PNG 预览图），支持查看与删除。

## 测试

```bash
# 单元测试
xcodebuild -project BeadWorks.xcodeproj -scheme BeadWorks \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BeadWorksTests test

# UI 测试
xcodebuild -project BeadWorks.xcodeproj -scheme BeadWorks \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BeadWorksUITests test
```

UI 测试通过两个启动参数保证可重复、无需人工干预：

- `-uiTestResetStorage`：启动时清空本地作品库目录，测试不受历史数据影响。
- `-uiTestFixtureImage`：在导入图片页显示一个"使用测试图片"按钮，绕开系统 Photos 选择器（其运行在独立进程中，UI 测试很难稳定驱动），在进程内生成一张小型合成图片用于走通导入 → 转换 → 编辑流程。

## 与 Unity 版本的关系

- 拼豆色板（`BeadColor.palette`）与 `PhotoTemplateService` 的裁剪/降采样/取色算法参考并对齐了 Unity 工程中的 `bead_palette.json` 与 `PhotoToPatternConverter.cs`，便于两侧后续对比或迁移数据。
- 原生版本不实现 Unity 版本的 3D 视觉、热量模拟熨烫、关卡等；定位是"轻量、可直接测试"的验收产品。
