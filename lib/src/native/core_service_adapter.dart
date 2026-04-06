import 'dart:async';

abstract class CoreServiceAdapter {
  Future<bool> startService({int? port, String? args});
  Future<bool> stopService();
  Future<Map<String, dynamic>> getServiceStatus();
  Future<Map<String, dynamic>> checkHealth();
  Future<bool> setAutoStart(bool enabled);
  Future<bool> getAutoStart();
  String? getLastErrorCode();

  /// Install a log handler callback which the adapter should call with
  /// each new log line (or combined message). Pass `null` to clear.
  void setLogHandler(void Function(String)? handler);
  /// Validate that the binary (optionally at [path]) is present and usable.
  /// Returns true if valid; adapters should set an internal last error code
  /// accessible via `getLastErrorCode()` on failure.
  Future<bool> validateBinary([String? path]);

  /// Read the current workspace path from the platform config.
  /// Returns an empty string if not set or not supported.
  Future<String> getWorkspacePath();

  /// Write the workspace path into the platform config.
  /// Returns true on success.
  Future<bool> setWorkspacePath(String path);
}
