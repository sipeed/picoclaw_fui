import 'package:flutter_test/flutter_test.dart';
import 'package:picoclaw_flutter_ui/src/core/device_feedback_models.dart';

void main() {
  const context = DeviceTelemetryRuntimeContext(
    platform: 'android',
    appVersion: '1.2.3',
    channel: 'official',
    region: 'zh',
    provider: 'firebase',
  );

  group('DeviceTelemetryDeriver', () {
    test('classifies recent activity bands', () {
      final now = DateTime.utc(2026, 4, 23, 12);

      final active = DeviceTelemetryDeriver.derive(
        store: DeviceTelemetryStore(
          lastActiveAt: now.subtract(const Duration(hours: 6)),
        ),
        context: context,
        now: now,
      );
      final lowActive = DeviceTelemetryDeriver.derive(
        store: DeviceTelemetryStore(
          lastActiveAt: now.subtract(const Duration(days: 5)),
        ),
        context: context,
        now: now,
      );
      final silent = DeviceTelemetryDeriver.derive(
        store: DeviceTelemetryStore(
          lastActiveAt: now.subtract(const Duration(days: 10)),
        ),
        context: context,
        now: now,
      );
      final churnRisk = DeviceTelemetryDeriver.derive(
        store: DeviceTelemetryStore(
          lastActiveAt: now.subtract(const Duration(days: 20)),
        ),
        context: context,
        now: now,
      );

      expect(active.state, DeviceTelemetryState.active);
      expect(lowActive.state, DeviceTelemetryState.lowActive);
      expect(silent.state, DeviceTelemetryState.silent);
      expect(churnRisk.state, DeviceTelemetryState.churnRisk);
    });

    test('marks reachability loss as unreachable and suspected uninstall', () {
      final now = DateTime.utc(2026, 4, 23, 12);

      final unreachable = DeviceTelemetryDeriver.derive(
        store: DeviceTelemetryStore(
          lastActiveAt: now.subtract(const Duration(days: 35)),
          consecutiveUploadFailures: 3,
          reachabilityLost: true,
        ),
        context: context,
        now: now,
      );

      final suspectedUninstalled = DeviceTelemetryDeriver.derive(
        store: DeviceTelemetryStore(
          lastActiveAt: now.subtract(const Duration(days: 50)),
          consecutiveUploadFailures: 4,
          reachabilityLost: true,
        ),
        context: context,
        now: now,
      );

      expect(unreachable.state, DeviceTelemetryState.unreachable);
      expect(unreachable.isInferred, isTrue);
      expect(
        suspectedUninstalled.state,
        DeviceTelemetryState.suspectedUninstalled,
      );
      expect(suspectedUninstalled.isInferred, isTrue);
    });

    test('marks recovered installs as reinstalled', () {
      final now = DateTime.utc(2026, 4, 23, 12);
      final snapshot = DeviceTelemetryDeriver.derive(
        store: DeviceTelemetryStore(
          lastActiveAt: now.subtract(const Duration(minutes: 5)),
          lastReactivatedAt: now.subtract(const Duration(minutes: 5)),
          lastReachabilityLossAt: now.subtract(const Duration(days: 10)),
          lastDerivedState: DeviceTelemetryState.suspectedUninstalled,
          reachabilityLost: true,
        ),
        context: context,
        now: now,
      );

      expect(snapshot.state, DeviceTelemetryState.reinstalled);
      expect(snapshot.stateReason, 'reactivated_after_loss');
      expect(snapshot.isInferred, isTrue);
    });

    test('serializes cohort and trend fields for providers', () {
      final now = DateTime.utc(2026, 4, 23, 12);
      final snapshot = DeviceTelemetryDeriver.derive(
        store: DeviceTelemetryStore(
          createdAt: now.subtract(const Duration(days: 60)),
          lastSeenAt: now.subtract(const Duration(hours: 2)),
          lastActiveAt: now.subtract(const Duration(hours: 2)),
          launchCount: 10,
          foregroundCount: 8,
        ),
        context: context,
        now: now,
      );

      final firebase = snapshot.toFirebaseParameters();
      final umeng = snapshot.toUmengPayload();

      expect(firebase['telemetry_state'], 'active');
      expect(firebase['telemetry_cohort'], snapshot.cohortKey);
      expect(firebase['telemetry_window_d'], 30);
      expect(umeng['telemetryState'], 'active');
      expect(umeng['telemetryCohortKey'], snapshot.cohortKey);
      expect(umeng['telemetryTrendWindowDays'], '30');
    });
  });
}
