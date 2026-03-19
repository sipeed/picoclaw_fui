# PicoClaw UI 编译与运行指南

本指南面向通过 Flutter 编译运行 PicoClaw 控制界面的开发者。

## 1. 跨平台依赖要求

由于本项目使用了系统托盘和窗口管理器，不同平台需要以下编译环境：

### Windows
- **开发者模式**: 必须在 Windows 设置中启用“开发人员模式”，否则插件编译可能会失败 (无法创建 Symlinks)。
- **Visual Studio 2022**: 安装时需勾选“使用 C++ 的桌面开发”。

### Linux (Ubuntu/Debian 为例)
在编译前必须安装以下系统库：
```bash
sudo apt update
sudo apt install libayatana-appindicator3-dev libgtk-3-dev pkg-config
```

### macOS
- 需要在 `macos/Runner/DebugProfile.entitlements` 和 `Release.entitlements` 中添加网络权限，以便前端可以访问本地 Go 服务。

---

## 2. 托盘与后台保活逻辑

### 桌面端 (Windows, macOS, Linux)
- **关闭隐藏**: 点击窗口右上角的关闭按钮 `X` 不会退出程序，而是隐藏到系统托盘。
- **托盘菜单**: 右键点击托盘图标可弹出菜单（显示窗口 / 彻底退出）。
- **左键响应**: 直接左键点击托盘图标可恢复窗口显示。

### 安卓端 (Android)
- **前台服务**: 程序启动后会开启一个前台服务并显示常驻通知。
- **防止被杀**: 只要通知栏显示服务，系统一般不会杀掉后台逻辑。
- **Go 二进制**: 安卓端运行 Go 程序需要特殊编译为 `so` 库或在后台 Isolate 中通过 `Process.run` 调用特定的原生实现，当前作为 Skeleton 框架实现。

---

## 3. i18n 多语言
项目使用标准 ARB 文件管理。若新增语言：
1. 在 `lib/l10n/` 下创建 `app_xx.arb`。
2. 运行 `flutter gen-l10n`。
3. 引用路径：`import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';`
