// UI constants used across the app to centralize sizing and breakpoints.
// English identifiers and comments per project convention.

import 'dart:io';

/// Breakpoint (logical pixels) to switch between mobile and desktop layouts.
const double kAdaptiveBreakpoint = 600.0;

/// Standard action button size (tap target).
const double kActionButtonSize = 56.0;

/// Width reserved for vertical side action bar.
const double kSideBarWidth = 84.0;

/// Check if the current platform supports TV-style focus navigation
/// (keyboard/remote control navigation with visible focus indicators).
///
/// Returns true for:
/// - Android TV (Android with large screen)
/// - Desktop platforms (Windows, macOS, Linux) with keyboard navigation
///
/// Returns false for:
/// - Android phones/tablets (touch-based)
/// - iOS devices (touch-based)
bool get kIsTvFocusMode {
  // TV platforms and desktop platforms need visible focus indicators
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return true;
  }
  // For Android, we can't easily distinguish TV vs phone here
  // So we enable focus mode on all Android and let the UI handle it gracefully
  if (Platform.isAndroid) {
    return true;
  }
  // iOS doesn't have TV focus mode
  return false;
}

/// Check if the current platform uses touch-based interaction primarily.
/// Touch platforms typically don't need visible focus indicators.
bool get kIsTouchPlatform {
  return Platform.isIOS || (Platform.isAndroid);
}
