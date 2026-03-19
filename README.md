# PicoClaw Flutter UI

A professional, modern, and high-performance cross-platform UI client for managing the `picoclaw` service. Designed for the 2026 technical aesthetic, focusing on clarity, accessibility, and high contrast.

## ✨ Key Features

- **2026 Minimalist Tech Aesthetic**: Glassmorphism dashboard with high-impact typography (`Inter` & `Fira Code`).
- **High-Impact Control Center**: Large, accessible action buttons optimized for TV, Desktop, and Mobile.
- **Multi-Theme System**: 6 professional color palettes (Carbon, Slate, Obsidian, Ebony, Nord, and the WCAG-compliant **SAKURA**).
- **Advanced Dashboard**: Real-time log monitoring with infinite scroll and QR code endpoint sharing.
- **Smart WebView Integration**: Embedded network management with "Not Started" guidance and easy navigation.
- **System Integration**: Native Windows tray support, single-instance enforcement, and port conflict resolution.

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

1. **Pre-requisites**: Ensure you have the `picoclaw` binary executable.
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

