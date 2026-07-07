# iOS Device Build（真机）

导出可在 **实体 iPhone** 上运行的 Xcode 工程（Device SDK）。

```bash
cd BeadWorksUnity
./build-ios-device.sh
```

输出：`Builds/iOSDevice/Unity-iPhone.xcodeproj`

## 在 Xcode 里安装到手机

1. 用数据线连接 iPhone
2. 打开 `Builds/iOSDevice/Unity-iPhone.xcodeproj`
3. Scheme 选 **Unity-iPhone**，顶部设备选你的 **iPhone**（不是 Simulator）
4. 选中 **Unity-iPhone** target → **Signing & Capabilities**
   - 勾选 **Automatically manage signing**
   - **Team** 选你的 Apple ID（免费账号也可用于自测）
5. **Cmd+R** 编译并安装到手机

首次在手机上运行可能需在 iPhone：**设置 → 通用 → VPN 与设备管理** 中信任开发者。

## 相册权限提示

首次使用「导入图片生成模板」或「保存作品」到相册时，系统会弹出照片授权提示（读取 / 写入分别对应
`NSPhotoLibraryUsageDescription` / `NSPhotoLibraryAddUsageDescription`）。这两条描述文案由
`IOSNativePostProcessor` 在每次导出时自动写入 `Info.plist`；若用户拒绝授权，需要到 **设置 → BeadWorks →
照片** 中手动开启。

## Unity 菜单

**BeadWorks → Build → iOS Device Xcode Project**

## 环境要求

- Unity `6000.5.2f1` + iOS Build Support
- Xcode + Apple 开发者账号（免费或付费均可自测）

自定义 Unity 路径：

```bash
UNITY_PATH="/path/to/Unity.app/Contents/MacOS/Unity" ./build-ios-device.sh
```

日志：`Logs/ios-device-export.log`
