CI: Downloading core binaries
===============================

This project expects platform core binaries to be placed under `app/bin/` and referenced in `app/bin/version.txt` before packaging/releases. The repository contains a GitHub Actions workflow template to help automate this step.

Workflow: `.github/workflows/fetch_core_binaries.yml`

How it works
- The workflow can be triggered manually (`workflow_dispatch`) or on release publish.
- It downloads binaries from URLs stored in repository secrets, places them into `app/bin/`, computes `sha256` checksums, writes `app/bin/version.txt`, and commits the files back to the branch.

Required secrets (set these in repository Settings → Secrets):
- `CORE_WINDOWS_URL` — download URL for Windows binary
- `CORE_WINDOWS_NAME` — filename to save in `app/bin/` (e.g. `picoclaw.exe`)
- `CORE_LINUX_URL` — download URL for Linux binary
- `CORE_LINUX_NAME` — filename to save in `app/bin/` (e.g. `picoclaw`)
- `CORE_MACOS_URL` — download URL for macOS binary
- `CORE_MACOS_NAME` — filename to save in `app/bin/` (e.g. `picoclaw`)

Optional: provide precomputed SHA256 values as secrets named `CORE_<FILENAME_UPPER>_SHA256` (the workflow will use them if present). Example: `CORE_PICOCLAW_EXE_SHA256`.

Notes & recommendations
- Ensure the action runner has permission to push back to the branch. The default `GITHUB_TOKEN` usually works, but branch protection rules may prevent pushes — in that case create a release branch or perform a PR-based approach instead.
- Verify the resulting `app/bin/version.txt` lines and that executables have the execute bit set for Linux/macOS.
- If you prefer not to commit binaries to the repo, adapt the workflow to instead upload the `app/bin` directory as an artifact and consume it during packaging.

Local development
------------------

For local development you can fetch the same release artifacts the CI downloads and install a matching core into `app/bin/` for debugging and packaging tests.

Preferred cross-platform tool
----------------------------

We provide a Dart-based cross-platform tool `tools/fetch_core_local.dart` that replaces the platform-specific shell/PowerShell helpers. It uses the Dart runtime and the project's `pubspec.yaml` dependencies so it runs identically on Windows, macOS, and Linux.

Usage examples:

```bash
# Using Dart directly
dart run tools/fetch_core_local.dart --repo sipeed/picoclaw --tag latest

# Using Flutter's pub runner (recommended in CI)
flutter pub run tools/fetch_core_local.dart --repo sipeed/picoclaw --tag latest

# Override output directory or asset
flutter pub run tools/fetch_core_local.dart --repo owner/repo --tag v0.2.3 --out-dir app/bin --asset-name picoclaw_Linux_x86_64.tar.gz
```

CI integration
--------------

The repository includes a workflow `.github/workflows/fetch_core_binaries.yml` that runs on release publish and can be triggered manually. The workflow performs `flutter pub get` and executes the Dart tool to fetch the appropriate release asset and place it into `app/bin/`, then writes `app/bin/version.txt`.

Notes:
- The tool performs anonymous downloads by default; set `GITHUB_TOKEN` (CI provides this) to avoid API rate limits.
- `app/bin/version.txt` is intended to match the CI-produced file format (single line with the asset filename). Consider adding `app/bin/` to `.gitignore` while keeping an example `app/bin/version.txt.example` in the repo for onboarding.

