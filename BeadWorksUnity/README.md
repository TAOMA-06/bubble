# BeadWorksUnity

拼豆手游 vertical slice 的 Unity 基础工程（URP + C#），与同级目录 `BeadWorks/` SwiftUI 项目独立共存。

## 要求

- Unity **2022.3 LTS**（或兼容的 2022.3.x）
- 首次打开会自动拉取 URP、TextMeshPro 等包

## 快速开始

1. 用 Unity Hub 打开本目录：`BeadWorksUnity/`
2. 等待 Package Manager 完成依赖解析
3. 打开场景：`Assets/Scenes/WorkshopScene.unity`
4. 点击 Play

若场景引用异常，可在菜单执行 **BeadWorks → Setup Workshop Scene** 重新生成场景。

## 完整闭环（Vertical Slice）

```
主菜单 → 自由创作 / 图纸复刻 → 工作台摆豆 → 熨烫 → 成品查看 → 保存 / 分享
                ↓
            作品库（本地存档，可重新打开）
```

### 主菜单 (MainMenu)

- **自由创作** — 空白 16×16 工作台
- **图纸复刻** — 进入图纸选择
- **作品库** — 浏览本地保存的成品

### 图纸选择 (PatternSelect)

内置 5 个原创图纸：

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
    Workshop/       WorkshopController, PegboardGrid, PatternMatcher
    Data/           色板、图纸、作品存档
    Services/       ShareCaptureService
    UI/             MainMenu, PatternSelect, Gallery, FinishedViewer, Debug
    Tools/          Tweezers, Eraser, Iron
    Ironing/        IroningSystem
    Presentation/   BeadFactory, PatternGuide, FinishedWorkPresenter
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

- 未授权 IP、广告、内购、云端共创、照片转拼豆（下一轮）

## 移动端

- 默认竖屏（1080×1920 参考分辨率）
- iOS / Android 包名：`com.beadworks.unity`
- Quality 使用 Mobile 配置 + URP
