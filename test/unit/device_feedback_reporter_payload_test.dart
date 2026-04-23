import 'package:flutter_test/flutter_test.dart';
import 'package:picoclaw_flutter_ui/src/core/device_feedback_models.dart';
import 'package:picoclaw_flutter_ui/src/core/firebase_device_reporter.dart';
import 'package:picoclaw_flutter_ui/src/core/umeng_device_reporter.dart';

void main() {
  final snapshot = DeviceTelemetrySnapshot(
    state: DeviceTelemetryState.active,
    previousState: DeviceTelemetryState.lowActive,
    derivedAt: DateTime.utc(2026, 4, 23, 12),
    stateReason: 'recent_foreground_activity',
    isInferred: false,
    isStale: false,
    platform: 'android',
    appVersion: '1.2.3',
    channel: 'official',
    region: 'zh',
    provider: 'firebase',
    trendWindowDays: 30,
    launchCount: 6,
    foregroundCount: 5,
    uploadFailureCount: 1,
    consecutiveUploadFailures: 0,
    reachabilityLost: false,
    lastSeenAt: DateTime.utc(2026, 4, 23, 11),
    lastActiveAt: DateTime.utc(2026, 4, 23, 11),
  );

  test('builds firebase analytics parameters with telemetry fields', () {
    final reporter = FirebaseDeviceReporter();
    final parameters = reporter.buildAnalyticsParameters(
      installId: 'install-123',
      deviceInfo: const {'osVersion': 'Android 15', 'appVersion': '1.2.3'},
      telemetrySnapshot: snapshot,
    );

    expect(parameters['install_id'], 'install-123');
    expect(parameters['telemetry_state'], 'active');
    expect(parameters['telemetry_cohort'], snapshot.cohortKey);
    expect(parameters['telemetry_window_d'], 30);
  });

  test('builds umeng payload with telemetry fields', () {
    final reporter = UmengDeviceReporter();
    final payload = reporter.buildPayload(
      installId: 'install-456',
      deviceInfo: const {
        'platform': 'android',
        'deviceModel': 'PicoClaw',
        'systemVersion': 'Android 15',
      },
      updatedAt: '2026-04-23T12:00:00.000Z',
      channel: 'official',
      telemetrySnapshot: snapshot,
    );

    expect(payload['installId'], 'install-456');
    expect(payload['telemetryState'], 'active');
    expect(payload['telemetryCohortKey'], snapshot.cohortKey);
    expect(payload['telemetryTrendWindowDays'], '30');
  });
}
