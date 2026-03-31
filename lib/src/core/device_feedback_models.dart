enum DeviceFeedbackProvider {
  none,
  firebase,
  umeng;

  static DeviceFeedbackProvider fromEnvironmentValue(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'firebase':
        return DeviceFeedbackProvider.firebase;
      case 'umeng':
        return DeviceFeedbackProvider.umeng;
      case 'none':
      case 'off':
      case 'disabled':
        return DeviceFeedbackProvider.none;
      default:
        return DeviceFeedbackProvider.firebase;
    }
  }
}

class DeviceFeedbackUploadResult {
  const DeviceFeedbackUploadResult({
    required this.success,
    required this.message,
    this.uploadedAt,
    this.deviceInfo,
  });

  final bool success;
  final String message;
  final String? uploadedAt;
  final Map<String, String>? deviceInfo;
}

typedef FirebaseUploadResult = DeviceFeedbackUploadResult;
