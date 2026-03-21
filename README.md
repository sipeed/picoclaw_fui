# PicoClaw Flutter UI

A modern cross-platform UI client for managing the `picoclaw` service. Designed for clarity, accessibility, and high contrast.

## ✨ Key Features

- **Minimalist Dashboard**: Clean interface with high-impact typography.
- **Accessible Controls**: Large action buttons optimized for Desktop and Mobile/TV usage.
- **Multiple Color Themes**: Includes 6 professional palettes (Carbon, Slate, Obsidian, Ebony, Nord, and SAKURA).
- **Log Monitoring**: Real-time log display with history management.
- **WebView Integration**: Embedded web management interface with status-aware guidance.
- **Desktop Ready**: Windows tray support, single-instance enforcement, and port conflict resolution.

## 📸 Screenshots

### Dashboard
| Idle Status | Running with SAKURA Theme |
| :---: | :---: |
| ![Dashboard Idle](docs/screenshots/dashboard_idle.png) | ![Dashboard Running](docs/screenshots/dashboard_running_sakura.png) |

### Network & Management
| Service Not Started Guide | Embedded Web UI (Sakura) |
| :---: | :---: |
| ![Network Not Started](docs/screenshots/network_not_started.png) | ![Network Sakura](docs/screenshots/network_sakura.png) |

### Configuration & Themes
| Midnight (Carbon) Selection | Sakura Theme Selection |
| :---: | :---: |
| ![Settings Carbon](docs/screenshots/settings_dark.png) | ![Settings Sakura](docs/screenshots/settings_sakura.png) |

## 🚀 Getting Started

1. **Pre-requisites**:
   - macOS: `picoclaw` 会在构建时自动拉取并编译进 `.app`（需要本机已安装 `git` + `go`）。
   - 其他平台：请先准备 `picoclaw` 可执行文件。
2. **Download**: Get the latest release from the [Releases](https://github.com/sky5454/picoclaw_fultter_ui/releases) page.
3. **Configure**: Go to the **PRESETS** tab to set your binary path and port.
4. **Launch**: Press the **LAUNCH SERVICE** button on the dashboard.

## 🛠️ Development

Building the project requires Flutter SDK:

```bash
flutter pub get
flutter run -d windows
```

For more details, see [docs/BUILD_GUIDE.md](docs/BUILD_GUIDE.md).

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.

