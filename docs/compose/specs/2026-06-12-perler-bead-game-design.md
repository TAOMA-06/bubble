# 拼豆工坊 iOS 游戏设计文档（Unity 版本）

> **重要更新（2026-07-06）**  
> 项目已从早期 SwiftUI 原型完整迁移至 **Unity（URP + C#）** 实现。  
> 本文档已更新为**当前实际交付的 Unity 垂直切片设计描述**。  
> 原始 SwiftUI 设计保留在文末「历史 SwiftUI 设计参考」部分，仅供追溯。  
> 当前主 README 和 BeadWorksUnity/README 也已明确说明 SwiftUI 版本已废弃。

## [S1] 背景与目标

做一款 iOS 拼豆（Perler Beads / Fuse Beads）休闲小游戏，核心体验是：

1. **自由创作**：在网格上自由选色、绘制自己的图案（默认 16×16）。
2. **图纸复刻**：选择内置图纸，在半透明引导下精确摆放拼豆。
3. **熨烫成品**：完成摆放后进行熨烫模拟，生成可展示的成品。
4. **作品库与分享**：保存作品到本地图库，生成高清分享图。

最终完成品支持多种展示类型（冰箱贴、钥匙扣、挂件），可拖动旋转查看，并导出分享图。

## [S2] 方案概述（当前 Unity 实现）

| 模块         | 方案                                      |
|--------------|-------------------------------------------|
| 技术栈       | Unity 6000.5.2f1 + URP + C# + UGUI/TextMeshPro |
| 场景         | 单场景 `WorkshopScene.unity`，UI 叠层导航 |
| 视觉         | 3D 珠子模型 + URP 材质，支持轻微凸起、高光、熨烫压平效果 |
| 珠粒尺寸     | Standard (5mm，默认)、Mini (2.6mm)        |
| 图纸复刻     | 内置 5 个原创图纸 + 半透明 Pegboard 引导 + 错误格提示（颜色错误/缺失） |
| 填色交互     | Tweezers（夹取/拖拽/吸附放置）、Eraser（擦除）、Iron（熨烫） |
| 熨烫系统     | 真实热量模拟：热量扩散、熔化、粘连、烧焦、风险提示 |
| 完成展示     | 3 种成品类型（冰箱贴 / 钥匙扣 / 挂件），支持 3D 旋转查看 |
| 存档与分享   | 本地 JSON + PNG 作品库；1080×1920 分享图（含水印、元数据） |

## [S3] 视觉与交互风格（当前实现）

- **工作台**：16×16 标准网格（可配置），使用 3D 珠子 + Pegboard 表面。
- **工具**：
  - **Tweezers**：拾取珠子、拖拽、吸附到网格、弹跳放置效果。
  - **Eraser**：擦除已放置珠子。
  - **Iron**：拖拽熨斗进行热量模拟。
- **图纸引导**：半透明底图，可开关；可开启「错误格提示」（错色或缺失）。
- **熨烫动画**：基于热量的渐进压平、边缘融合、烧焦风险。提供 IroningStats（平均熔化、粘连、峰值热量、烧焦程度）。
- **成品查看**：作品脱离 pegboard，干净背景 + 3D 拖拽旋转。
- **调试**：内置 DebugOverlay（F1 显示 FPS，反引号打开测试面板）。

## [S4] 核心流程（Vertical Slice）

```
主菜单
├── 自由创作 → 空白 16×16 工作台 → 摆豆 → 熨烫 → 成品查看 → 保存/分享
├── 图纸复刻 → 选择图纸 → 带引导摆豆 → 熨烫 → 成品 → 保存/分享
└── 作品库   → 浏览本地作品 → 重新打开编辑或查看
```

**内置图纸**（5 个）：
- heart（爱心）
- star（星星）
- guofeng_cloud（国风云纹）
- milk_tea_cup（奶茶杯）
- support_sign（应援字牌）

**熨烫结果**：UnderIroned / Good / OverIroned / Burned 等，通过 IroningResult 表示。

## [S5] 数据与存储（当前）

- 色板：`bead_palette.json` + BeadPaletteRepository
- 图纸：BuiltinPatternFactory + PatternRepository（BeadPatternData）
- 作品存档：FinishedWorkRecord + GalleryRepository（JSON 索引 + PNG 缩略图）
  - 路径：`Application.persistentDataPath/gallery/`
- 分享图：ShareCaptureService 生成 1080×1920 图片，保存到 `persistentDataPath/shares/`

## [S6] MVP 范围（当前已交付）

已完整实现：
- 主菜单 + 自由创作 + 图纸复刻 + 作品库
- 两种珠粒尺寸 + 16×16 网格
- 三种工具 + 高级熨烫模拟 + 视觉反馈
- 3 种成品类型 + 3D 查看 + 保存 + 高清分享图（带水印）
- iOS 模拟器导出支持（Editor 工具 + build-ios-simulator.sh）
- 本地持久化

**首版明确不做**（见 BeadWorksUnity/README）：
- 照片转拼豆（下一轮）
- 关卡模式、每日挑战、成就、广告、内购、云端
- Biggie 尺寸（10mm）
- 复杂 3D 结构

## [S7] 后续待确认（当前状态）

1. 是否在后续版本加入照片导入与颜色量化？
2. 是否扩展到三种以上珠子尺寸？
3. 分享图水印和元数据是否需要更多品牌元素？
4. 是否需要云端同步或多人共创？

---

## 历史 SwiftUI 设计参考（已废弃）

以下为 2026-06-12 原始设计（Swift + SwiftUI 版本），仅供历史参考，已不再维护。

（原内容摘要：技术栈 Swift + SwiftUI、本地 Core Data、轻度拟物圆角珠子、图片转拼豆 k-means 量化、数字填色 + 自由模式、CanvasState 结构体等。完整历史内容见 git 历史或备份。）

**原 [S2] 方案概述（历史）** 技术栈曾规划为 Swift + SwiftUI，已于 2026-07 迁移至 Unity。

**原 MVP 范围（历史）** 包含图片转拼豆、数字填色编号等功能，当前 Unity 垂直切片已调整优先级，图片转拼豆标记为下一轮。

---

**本设计文档现在与实际代码（BeadWorksUnity/）保持一致。** 后续审查（/review）应以此为 Spec 来源。