# BeadWorksUnity

拼豆手游 **Unity 工程**（URP + C#）。核心玩法是两条主线——**自由创作**与**导入图片生成模板**，辅以工作台、熨烫、成品、作品库与分享的完整闭环；内置图纸复刻保留作为示例/调试内容。

## 要求

- Unity **6000.5.2f1**（或 Hub 中与本仓库 `ProjectSettings/ProjectVersion.txt` 一致的版本）
- 首次打开会自动拉取 URP、TextMeshPro 等包
- iOS 导出需安装 **iOS Build Support** 模块

## 快速开始

1. 用 Unity Hub 打开本目录：`BeadWorksUnity/`
2. 等待 Package Manager 完成依赖解析
3. 打开场景：`Assets/Scenes/WorkshopScene.unity`
4. 点击 Play

若场景引用异常，可在菜单执行 **BeadWorks → Setup Workshop Scene** 重新生成场景。

## iOS 模拟器 / Xcode

```bash
./build-ios-simulator.sh
```

直接在模拟器中安装并启动查看效果：

```bash
./run-ios-simulator.sh
```

或 Unity 菜单：**BeadWorks → Build → iOS Simulator Xcode Project**

详见 [README-iOS-Simulator.md](README-iOS-Simulator.md)。

## 完整闭环（Vertical Slice）

```
主菜单 → 自由创作 / 导入图片生成模板 / 图纸复刻(示例) → 工作台摆豆 → 熨烫 → 成品查看 → 保存 / 分享
                ↓
            作品库（本地存档，可重新打开）
```

### 主菜单 (MainMenu)

- **自由创作** — 主入口，内联尺寸选择：`16×16`（简易）/ `29×29`（标准，默认）
- **导入图片生成模板** — 第二主入口，进入图片导入流程
- **作品库** — 浏览本地保存的成品
- **示例图纸**（次级链接）— 内置原创图纸，保留作为示例/调试内容，不再作为主流程

### 图片导入 (ImageImport)

1. 点击「选择照片」——iOS 真机/模拟器上会弹出系统 `PHPickerViewController`（首次使用需要用户授权相册访问）；Unity Editor 内用本地文件选择框代替，便于无设备快速联调。
2. 自动生成预览：居中裁剪为正方形 → 按所选尺寸盒式降采样 → 按现有色板（8 色）就近取色，透明区域留空。
3. 可切换模板尺寸（`16` / `24` / `32`(默认) / `48`），预览会即时刷新。
4. 确认后直接进入工作台，可继续手动摆放/调整。

### 图纸选择 (PatternSelect，示例/调试)

内置 5 个原创图纸，作为示例内容通过主菜单「示例图纸」进入：

| ID | 名称 |
|----|------|
| heart | 爱心 |
| star | 星星 |
| guofeng_cloud | 国风云纹 |
| milk_tea_cup | 奶茶杯 |
| support_sign | 应援字牌 |

### 图纸引导 (PatternGuide)

- Pegboard 半透明底图提示
- 可切换显示/隐藏底图
- 可开启错误格提示（颜色错误 / 缺失）

### 成品查看 (FinishedWorkViewer)

- 熨烫完成后作品脱离 pegboard，展示在干净背景上
- 支持拖动旋转查看
- 三种成品类型：冰箱贴 / 钥匙扣 / 挂件
- 可保存到作品库、生成分享图

### 作品库 (Gallery)

- 本地 JSON + PNG 缩略图，路径：`Application.persistentDataPath/gallery/`

### 分享图 (ShareCapture)

- 1080×1920 高清分享图
- 包含作品、标题、用豆数、完成时间、BeadWorks 水印
- 保存到 `persistentDataPath/shares/`

## 目录结构

```
Assets/
  Scenes/           WorkshopScene（单场景，UI 叠层导航）
  Scripts/
    Core/           GameBootstrap, AppFlowController, WorkshopSession
    Workshop/       WorkshopController, PegboardGrid, PatternMatcher, CameraController
    Data/           色板、图纸、作品存档、PhotoToPatternConverter
    Services/       ShareCaptureService, PhotoImportService
    UI/             MainMenu, ImageImport, PatternSelect, Gallery, FinishedViewer, Debug,
                     BeadWorksUiTheme（统一配色 / 圆角 UI 生成）
    Tools/          Tweezers, Eraser, Iron
    Ironing/        IroningSystem
    Presentation/   BeadFactory, WorkbenchBackground, PegboardPresenter, PatternGuide, FinishedWorkPresenter
    Editor/         场景搭建、iOS 导出、IOSNativePostProcessor（相册权限 + 框架链接）
  Plugins/iOS/      BeadWorksPhotoPicker（PHPickerViewController 原生桥接）
  Data/             bead_palette.json
  Prefabs/          UI 按钮
  Materials/        URP 材质
```

## 调试工具

按 **`**（反引号）** 打开调试面板，**F1** 切换 FPS 显示：

| 按钮 | 功能 |
|------|------|
| Grid坐标 | 验证网格坐标 ↔ 世界坐标往返 |
| 重复放置 | 验证同格不可重复放置 |
| 熨烫结果 | 快速模拟熨烫完成 |
| 64×64压力 | 填充 64×64 网格压力测试 |
| FPS开关 | 切换帧率显示 |

## 工具模式

| ToolMode | 说明 |
|----------|------|
| Tweezers | 夹取、拖拽、吸附、弹跳放置 |
| Eraser   | 擦除拼豆 |
| Iron     | 熨烫融合 |
| Inspect  | 预留 |

## 首版不做

- 未授权 IP、广告、内购、云端共创

## 移动端

- 默认竖屏（1080×1920 参考分辨率）
- iOS Bundle ID：`com.beadworks.unity`
- Quality 使用 Mobile 配置 + URP
- 相册权限：首次「选择照片」/「保存到相册」会触发系统权限弹窗（`NSPhotoLibraryUsageDescription` /
  `NSPhotoLibraryAddUsageDescription`，由 `IOSNativePostProcessor` 自动写入导出的 Xcode 工程 Info.plist）
