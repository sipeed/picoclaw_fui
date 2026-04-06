import 'dart:convert';

/// Utilities for reading and patching fields in the picoclaw config JSON.
class ConfigJsonUtils {
  /// Extract the workspace path from a raw config JSON string.
  /// Returns empty string if not found or on any parse error.
  static String readWorkspacePath(String rawJson) {
    if (rawJson.trim().isEmpty) return '';
    try {
      final parsed = json.decode(rawJson);
      if (parsed is! Map) return '';
      final agents = parsed['agents'];
      if (agents is! Map) return '';
      final defaults = agents['defaults'];
      if (defaults is! Map) return '';
      final workspace = defaults['workspace'];
      return workspace is String ? workspace : '';
    } catch (_) {
      return '';
    }
  }

  /// Patch the workspace path in a raw config JSON string.
  /// Returns the updated JSON string.
  static String patchWorkspacePath(String rawJson, String workspacePath) {
    Map<String, dynamic> root;
    if (rawJson.trim().isEmpty) {
      root = <String, dynamic>{};
    } else {
      try {
        final parsed = json.decode(rawJson);
        if (parsed is! Map) {
          root = <String, dynamic>{};
        } else {
          root = Map<String, dynamic>.from(parsed);
        }
      } catch (_) {
        root = <String, dynamic>{};
      }
    }

    final agents = root['agents'];
    final agentsMap =
        agents is Map ? Map<String, dynamic>.from(agents) : <String, dynamic>{};
    final defaults = agentsMap['defaults'];
    final defaultsMap = defaults is Map
        ? Map<String, dynamic>.from(defaults)
        : <String, dynamic>{};
    defaultsMap['workspace'] = workspacePath;
    agentsMap['defaults'] = defaultsMap;
    root['agents'] = agentsMap;

    return json.encode(root);
  }
}
