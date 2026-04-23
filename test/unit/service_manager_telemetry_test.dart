import 'package:flutter_test/flutter_test.dart';
import 'package:picoclaw_flutter_ui/src/core/device_feedback_models.dart';
import 'package:picoclaw_flutter_ui/src/core/service_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ServiceManager service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = ServiceManager();
    await service.clearTelemetryState();
  });

  test('records lifecycle markers and derives active state', () async {
    final launchAt = DateTime.utc(2026, 4, 23, 8);
    final foregroundAt = launchAt.add(const Duration(minutes: 1));

    await service.recordTelemetryLaunch(now: launchAt);
    await service.recordTelemetryForeground(now: foregroundAt);

    final snapshot = await service.getDeviceTelemetrySnapshot(
      now: launchAt.add(const Duration(hours: 2)),
    );

    expect(snapshot.state, DeviceTelemetryState.active);
    expect(snapshot.launchCount, 1);
    expect(snapshot.foregroundCount, 1);
    expect(snapshot.lastLaunchAt, launchAt);
    expect(snapshot.lastForegroundAt, foregroundAt);
    expect(snapshot.lastActiveAt, foregroundAt);
  });

  test(
    'promotes repeated failures to unreachable and recovers on foreground',
    () async {
      final launchAt = DateTime.utc(2026, 3, 10, 8);
      final now = DateTime.utc(2026, 4, 23, 12);

      await service.recordTelemetryLaunch(now: launchAt);
      await service.recordTelemetryUploadFailure(
        'timeout',
        now: launchAt.add(const Duration(days: 1)),
      );
      await service.recordTelemetryUploadFailure(
        'timeout',
        now: launchAt.add(const Duration(days: 2)),
      );
      await service.recordTelemetryUploadFailure(
        'timeout',
        now: launchAt.add(const Duration(days: 3)),
      );

      final unreachable = await service.getDeviceTelemetrySnapshot(now: now);
      expect(unreachable.state, DeviceTelemetryState.unreachable);
      expect(unreachable.reachabilityLost, isTrue);
      expect(unreachable.consecutiveUploadFailures, 3);

      await service.recordTelemetryForeground(now: now);
      final reinstalled = await service.getDeviceTelemetrySnapshot(
        now: now.add(const Duration(minutes: 1)),
      );

      expect(reinstalled.state, DeviceTelemetryState.reinstalled);

      await service.recordTelemetryUploadSuccess(
        reinstalled,
        now: now.add(const Duration(minutes: 2)),
      );
      final activeAgain = await service.getDeviceTelemetrySnapshot(
        now: now.add(const Duration(minutes: 3)),
      );

      expect(activeAgain.state, DeviceTelemetryState.active);
      expect(activeAgain.reachabilityLost, isFalse);
      expect(activeAgain.consecutiveUploadFailures, 0);
    },
  );

  test('marks stale snapshots when uploads stop refreshing', () async {
    final launchAt = DateTime.utc(2026, 4, 1, 8);

    await service.recordTelemetryLaunch(now: launchAt);
    await service.recordTelemetryForeground(now: launchAt);

    final stale = await service.getDeviceTelemetrySnapshot(
      now: launchAt.add(const Duration(days: 5)),
    );

    expect(stale.isStale, isTrue);
    expect(stale.state, DeviceTelemetryState.lowActive);
  });
}
