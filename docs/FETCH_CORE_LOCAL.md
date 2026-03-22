# fetch_core_local.dart — Usage

This document describes how to use `tools/fetch_core_local.dart` to (optionally) build your Flutter target, download platform core binaries from GitHub Releases, install them into the project `app/bin/` and into platform build outputs, and optionally run a packaging command.

Why use this tool
- Single cross-platform Dart tool to replace separate shell/Powershell helpers.
- Can run the exact `flutter build` command, then fetch the appropriate release asset and copy it into build outputs so packaging includes it.
- Works well both locally and in CI.

Basic local usage

- Download and install the selected release binary into `app/bin/` (no build):

```bash
flutter pub run tools/fetch_core_local.dart --repo sipeed/picoclaw --tag latest --out-dir app/bin
```

- Build target, then download and install into build output (Windows example):

```bash
flutter pub run tools/fetch_core_local.dart --repo sipeed/picoclaw --tag latest --out-dir app/bin --platform windows --install-to-build
```

Build command is automatic based on `--platform` and `--build-mode`.

Examples:

- Android release (AAB):

```bash
flutter pub run tools/fetch_core_local.dart \
  --repo sipeed/picoclaw --tag latest --out-dir app/bin \
  --platform android --arch arm64 --build-mode release --install-to-build
```

- Android debug (APK):

```bash
flutter pub run tools/fetch_core_local.dart \
  --repo sipeed/picoclaw --tag latest --out-dir app/bin \
  --platform android --arch x86_64 --build-mode debug --install-to-build
```

- Windows release:

```powershell
flutter pub run tools/fetch_core_local.dart --repo sipeed/picoclaw --tag latest --out-dir app/bin --platform windows --arch x86_64 --build-mode release --install-to-build
```

Options (selected)
- `--repo`: GitHub repo (owner/repo). Defaults to `sipeed/picoclaw`.
- `--tag`: release tag or `latest`.
- `--out-dir`: where to place downloaded binary (default `app/bin`).
- `--install-to-build`: copy the binary into the platform build output (detected common paths) in addition to `--out-dir`.
- `--dest`: explicit install destination (overrides detected build output path).
- `--build-cmd`: run an arbitrary build command (shell string). Useful to pass exact `flutter build appbundle` or other platform-specific build commands.
- `--platform`: logical target (windows|macos|linux) used for asset selection if different from the runner.
- `--arch`: override architecture selection (e.g., `x86_64`, `arm64`).
- `--pack-cmd`: command to run after copying (e.g., NSIS, codesign, DMG creation).
- `--dry-run`: print planned actions and exit.

CI integration example (GitHub Actions)

Replace explicit `flutter build` steps with a single call to this tool which runs the build and then downloads/installs the core binary. Example snippet (Android):

```yaml
- name: Build Android AAB, fetch/install core, and package
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    flutter pub run tools/fetch_core_local.dart \
      --repo sipeed/picoclaw --tag latest --out-dir app/bin --github-token $GITHUB_TOKEN \
      --build-cmd "flutter build appbundle --release --target-platform android-arm,android-arm64" \
      --install-to-build
```

Windows example (PowerShell runner):

```powershell
- name: Build Windows release (build + fetch/install core)
  shell: powershell
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    flutter pub run tools/fetch_core_local.dart --repo sipeed/picoclaw --tag latest --out-dir app/bin --github-token $env:GITHUB_TOKEN --build-cmd "flutter build windows --release" --install-to-build
```

Notes
- When placing binaries into a `.app` on macOS you may need to run codesign/notarize as a subsequent step.
- The tool writes `app/bin/version.txt` containing the chosen asset filename.
- Use `--dry-run` locally to confirm what will happen in CI before committing.

Contact
If you want, I can update `.github/workflows/release_full.yml` to use the exact commands you need for packaging flows beyond the examples above.