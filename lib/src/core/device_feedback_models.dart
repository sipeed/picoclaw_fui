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

enum DeviceTelemetryState {
  unknown,
  active,
  lowActive,
  silent,
  churnRisk,
  suspectedUninstalled,
  unreachable,
  reinstalled;

  String get wireValue => switch (this) {
    DeviceTelemetryState.unknown => 'unknown',
    DeviceTelemetryState.active => 'active',
    DeviceTelemetryState.lowActive => 'low_active',
    DeviceTelemetryState.silent => 'silent',
    DeviceTelemetryState.churnRisk => 'churn_risk',
    DeviceTelemetryState.suspectedUninstalled => 'suspected_uninstalled',
    DeviceTelemetryState.unreachable => 'unreachable',
    DeviceTelemetryState.reinstalled => 'reinstalled',
  };

  static DeviceTelemetryState fromWireValue(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'active':
        return DeviceTelemetryState.active;
      case 'low_active':
        return DeviceTelemetryState.lowActive;
      case 'silent':
        return DeviceTelemetryState.silent;
      case 'churn_risk':
        return DeviceTelemetryState.churnRisk;
      case 'suspected_uninstalled':
        return DeviceTelemetryState.suspectedUninstalled;
      case 'unreachable':
        return DeviceTelemetryState.unreachable;
      case 'reinstalled':
        return DeviceTelemetryState.reinstalled;
      case 'unknown':
      default:
        return DeviceTelemetryState.unknown;
    }
  }
}

class DeviceTelemetryThresholds {
  const DeviceTelemetryThresholds({
    this.activeWindow = const Duration(days: 2),
    this.lowActivityWindow = const Duration(days: 7),
    this.silentWindow = const Duration(days: 14),
    this.churnRiskWindow = const Duration(days: 30),
    this.uninstallWindow = const Duration(days: 45),
    this.staleWindow = const Duration(days: 3),
    this.reachabilityFailureThreshold = 3,
    this.trendWindowDays = 30,
  });

  final Duration activeWindow;
  final Duration lowActivityWindow;
  final Duration silentWindow;
  final Duration churnRiskWindow;
  final Duration uninstallWindow;
  final Duration staleWindow;
  final int reachabilityFailureThreshold;
  final int trendWindowDays;
}

class DeviceTelemetryRuntimeContext {
  const DeviceTelemetryRuntimeContext({
    required this.platform,
    required this.appVersion,
    required this.channel,
    required this.region,
    required this.provider,
  });

  final String platform;
  final String appVersion;
  final String channel;
  final String region;
  final String provider;
}

class DeviceTelemetryStore {
  const DeviceTelemetryStore({
    this.createdAt,
    this.lastSeenAt,
    this.lastLaunchAt,
    this.lastForegroundAt,
    this.lastBackgroundAt,
    this.lastActiveAt,
    this.lastUploadAttemptAt,
    this.lastUploadedAt,
    this.lastSyncFailureAt,
    this.lastReachabilityLossAt,
    this.lastReactivatedAt,
    this.lastStateChangedAt,
    this.lastUploadedSignature,
    this.lastFailureMessage,
    this.lastStateReason,
    this.lastDerivedState = DeviceTelemetryState.unknown,
    this.launchCount = 0,
    this.foregroundCount = 0,
    this.uploadFailureCount = 0,
    this.consecutiveUploadFailures = 0,
    this.reachabilityLost = false,
  });

  final DateTime? createdAt;
  final DateTime? lastSeenAt;
  final DateTime? lastLaunchAt;
  final DateTime? lastForegroundAt;
  final DateTime? lastBackgroundAt;
  final DateTime? lastActiveAt;
  final DateTime? lastUploadAttemptAt;
  final DateTime? lastUploadedAt;
  final DateTime? lastSyncFailureAt;
  final DateTime? lastReachabilityLossAt;
  final DateTime? lastReactivatedAt;
  final DateTime? lastStateChangedAt;
  final String? lastUploadedSignature;
  final String? lastFailureMessage;
  final String? lastStateReason;
  final DeviceTelemetryState lastDerivedState;
  final int launchCount;
  final int foregroundCount;
  final int uploadFailureCount;
  final int consecutiveUploadFailures;
  final bool reachabilityLost;

  DeviceTelemetryStore copyWith({
    DateTime? createdAt,
    DateTime? lastSeenAt,
    DateTime? lastLaunchAt,
    DateTime? lastForegroundAt,
    DateTime? lastBackgroundAt,
    DateTime? lastActiveAt,
    DateTime? lastUploadAttemptAt,
    DateTime? lastUploadedAt,
    DateTime? lastSyncFailureAt,
    DateTime? lastReachabilityLossAt,
    DateTime? lastReactivatedAt,
    DateTime? lastStateChangedAt,
    String? lastUploadedSignature,
    String? lastFailureMessage,
    String? lastStateReason,
    DeviceTelemetryState? lastDerivedState,
    int? launchCount,
    int? foregroundCount,
    int? uploadFailureCount,
    int? consecutiveUploadFailures,
    bool? reachabilityLost,
  }) {
    return DeviceTelemetryStore(
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      lastLaunchAt: lastLaunchAt ?? this.lastLaunchAt,
      lastForegroundAt: lastForegroundAt ?? this.lastForegroundAt,
      lastBackgroundAt: lastBackgroundAt ?? this.lastBackgroundAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      lastUploadAttemptAt: lastUploadAttemptAt ?? this.lastUploadAttemptAt,
      lastUploadedAt: lastUploadedAt ?? this.lastUploadedAt,
      lastSyncFailureAt: lastSyncFailureAt ?? this.lastSyncFailureAt,
      lastReachabilityLossAt:
          lastReachabilityLossAt ?? this.lastReachabilityLossAt,
      lastReactivatedAt: lastReactivatedAt ?? this.lastReactivatedAt,
      lastStateChangedAt: lastStateChangedAt ?? this.lastStateChangedAt,
      lastUploadedSignature:
          lastUploadedSignature ?? this.lastUploadedSignature,
      lastFailureMessage: lastFailureMessage ?? this.lastFailureMessage,
      lastStateReason: lastStateReason ?? this.lastStateReason,
      lastDerivedState: lastDerivedState ?? this.lastDerivedState,
      launchCount: launchCount ?? this.launchCount,
      foregroundCount: foregroundCount ?? this.foregroundCount,
      uploadFailureCount: uploadFailureCount ?? this.uploadFailureCount,
      consecutiveUploadFailures:
          consecutiveUploadFailures ?? this.consecutiveUploadFailures,
      reachabilityLost: reachabilityLost ?? this.reachabilityLost,
    );
  }
}

class DeviceTelemetrySnapshot {
  const DeviceTelemetrySnapshot({
    required this.state,
    required this.previousState,
    required this.derivedAt,
    required this.stateReason,
    required this.isInferred,
    required this.isStale,
    required this.platform,
    required this.appVersion,
    required this.channel,
    required this.region,
    required this.provider,
    required this.trendWindowDays,
    required this.launchCount,
    required this.foregroundCount,
    required this.uploadFailureCount,
    required this.consecutiveUploadFailures,
    required this.reachabilityLost,
    this.createdAt,
    this.lastSeenAt,
    this.lastLaunchAt,
    this.lastForegroundAt,
    this.lastBackgroundAt,
    this.lastActiveAt,
    this.lastUploadedAt,
    this.lastSyncFailureAt,
    this.lastReachabilityLossAt,
    this.lastReactivatedAt,
    this.lastStateChangedAt,
    this.lastFailureMessage,
    this.lastUploadedSignature,
  });

  final DeviceTelemetryState state;
  final DeviceTelemetryState previousState;
  final DateTime derivedAt;
  final String stateReason;
  final bool isInferred;
  final bool isStale;
  final String platform;
  final String appVersion;
  final String channel;
  final String region;
  final String provider;
  final int trendWindowDays;
  final int launchCount;
  final int foregroundCount;
  final int uploadFailureCount;
  final int consecutiveUploadFailures;
  final bool reachabilityLost;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;
  final DateTime? lastLaunchAt;
  final DateTime? lastForegroundAt;
  final DateTime? lastBackgroundAt;
  final DateTime? lastActiveAt;
  final DateTime? lastUploadedAt;
  final DateTime? lastSyncFailureAt;
  final DateTime? lastReachabilityLossAt;
  final DateTime? lastReactivatedAt;
  final DateTime? lastStateChangedAt;
  final String? lastFailureMessage;
  final String? lastUploadedSignature;

  String get stateValue => state.wireValue;
  String get previousStateValue => previousState.wireValue;

  String get cohortKey =>
      '$platform|$appVersion|$channel|$region|${state.wireValue}';

  String buildUploadSignature() {
    return [
      state.wireValue,
      previousState.wireValue,
      _toIso(lastSeenAt),
      _toIso(lastActiveAt),
      isInferred ? '1' : '0',
      isStale ? '1' : '0',
      launchCount.toString(),
      foregroundCount.toString(),
      uploadFailureCount.toString(),
      consecutiveUploadFailures.toString(),
      reachabilityLost ? '1' : '0',
      appVersion,
      channel,
      region,
      provider,
    ].join('|');
  }

  Map<String, Object> toFirebaseParameters() {
    return _withoutNullValues<Object>({
      'telemetry_state': state.wireValue,
      'telemetry_prev_state': previousState.wireValue,
      'telemetry_reason': stateReason,
      'telemetry_inferred': isInferred ? 1 : 0,
      'telemetry_stale': isStale ? 1 : 0,
      'telemetry_platform': platform,
      'telemetry_app_ver': appVersion,
      'telemetry_channel': channel,
      'telemetry_region': region,
      'telemetry_provider': provider,
      'telemetry_launches': launchCount,
      'telemetry_fg_count': foregroundCount,
      'telemetry_failures': uploadFailureCount,
      'telemetry_fail_streak': consecutiveUploadFailures,
      'telemetry_reachable': reachabilityLost ? 0 : 1,
      'telemetry_window_d': trendWindowDays,
      'telemetry_last_seen': _toIso(lastSeenAt),
      'telemetry_last_active': _toIso(lastActiveAt),
      'telemetry_last_sync': _toIso(lastUploadedAt),
      'telemetry_last_fail': _toIso(lastSyncFailureAt),
      'telemetry_cohort': cohortKey,
    });
  }

  Map<String, String> toUmengPayload() {
    return _withoutNullValues<String>({
      'telemetryState': state.wireValue,
      'telemetryPreviousState': previousState.wireValue,
      'telemetryStateReason': stateReason,
      'telemetryInferred': isInferred.toString(),
      'telemetryStale': isStale.toString(),
      'telemetryPlatform': platform,
      'telemetryAppVersion': appVersion,
      'telemetryChannel': channel,
      'telemetryRegion': region,
      'telemetryProvider': provider,
      'telemetryLaunchCount': launchCount.toString(),
      'telemetryForegroundCount': foregroundCount.toString(),
      'telemetryUploadFailures': uploadFailureCount.toString(),
      'telemetryFailureStreak': consecutiveUploadFailures.toString(),
      'telemetryReachabilityLost': reachabilityLost.toString(),
      'telemetryTrendWindowDays': trendWindowDays.toString(),
      'telemetryLastSeenAt': _toIso(lastSeenAt),
      'telemetryLastActiveAt': _toIso(lastActiveAt),
      'telemetryLastUploadedAt': _toIso(lastUploadedAt),
      'telemetryLastFailureAt': _toIso(lastSyncFailureAt),
      'telemetryCohortKey': cohortKey,
    });
  }

  static String? _toIso(DateTime? value) => value?.toUtc().toIso8601String();
}

class DeviceTelemetryDeriver {
  const DeviceTelemetryDeriver._();

  static DeviceTelemetrySnapshot derive({
    required DeviceTelemetryStore store,
    required DeviceTelemetryRuntimeContext context,
    DeviceTelemetryThresholds thresholds = const DeviceTelemetryThresholds(),
    DateTime? now,
  }) {
    final derivedAt = (now ?? DateTime.now()).toUtc();
    final lastActivity =
        store.lastActiveAt ??
        store.lastForegroundAt ??
        store.lastLaunchAt ??
        store.lastSeenAt;

    var state = DeviceTelemetryState.unknown;
    var isInferred = false;
    var reason = 'no_activity';

    if (lastActivity != null) {
      final inactivity = derivedAt.difference(lastActivity);
      final wasRecovered =
          store.lastReactivatedAt != null &&
          store.lastReactivatedAt!.isAfter(
            store.lastReachabilityLossAt ??
                DateTime.fromMillisecondsSinceEpoch(0),
          ) &&
          (store.lastDerivedState == DeviceTelemetryState.unreachable ||
              store.lastDerivedState ==
                  DeviceTelemetryState.suspectedUninstalled ||
              store.lastDerivedState == DeviceTelemetryState.reinstalled) &&
          (store.lastUploadedAt == null ||
              store.lastUploadedAt!.isBefore(store.lastReactivatedAt!));

      if (wasRecovered) {
        state = DeviceTelemetryState.reinstalled;
        isInferred = true;
        reason = 'reactivated_after_loss';
      } else if (_isReachabilityLost(store, thresholds) &&
          inactivity >= thresholds.uninstallWindow) {
        state = DeviceTelemetryState.suspectedUninstalled;
        isInferred = true;
        reason = 'long_inactive_with_reachability_loss';
      } else if (_isReachabilityLost(store, thresholds) &&
          inactivity >= thresholds.churnRiskWindow) {
        state = DeviceTelemetryState.unreachable;
        isInferred = true;
        reason = 'reachability_loss_detected';
      } else if (inactivity <= thresholds.activeWindow) {
        state = DeviceTelemetryState.active;
        reason = 'recent_foreground_activity';
      } else if (inactivity <= thresholds.lowActivityWindow) {
        state = DeviceTelemetryState.lowActive;
        reason = 'reduced_recent_activity';
      } else if (inactivity <= thresholds.silentWindow) {
        state = DeviceTelemetryState.silent;
        reason = 'inactive_but_within_silent_window';
      } else {
        state = DeviceTelemetryState.churnRisk;
        reason = 'inactive_beyond_silent_window';
      }
    }

    final freshnessAnchor =
        store.lastUploadedAt ?? store.lastSeenAt ?? lastActivity;
    final isStale =
        freshnessAnchor == null ||
        derivedAt.difference(freshnessAnchor) > thresholds.staleWindow;

    return DeviceTelemetrySnapshot(
      state: state,
      previousState: store.lastDerivedState,
      derivedAt: derivedAt,
      stateReason: reason,
      isInferred: isInferred,
      isStale: isStale,
      platform: context.platform,
      appVersion: context.appVersion,
      channel: context.channel,
      region: context.region,
      provider: context.provider,
      trendWindowDays: thresholds.trendWindowDays,
      launchCount: store.launchCount,
      foregroundCount: store.foregroundCount,
      uploadFailureCount: store.uploadFailureCount,
      consecutiveUploadFailures: store.consecutiveUploadFailures,
      reachabilityLost: _isReachabilityLost(store, thresholds),
      createdAt: store.createdAt,
      lastSeenAt: store.lastSeenAt,
      lastLaunchAt: store.lastLaunchAt,
      lastForegroundAt: store.lastForegroundAt,
      lastBackgroundAt: store.lastBackgroundAt,
      lastActiveAt: lastActivity,
      lastUploadedAt: store.lastUploadedAt,
      lastSyncFailureAt: store.lastSyncFailureAt,
      lastReachabilityLossAt: store.lastReachabilityLossAt,
      lastReactivatedAt: store.lastReactivatedAt,
      lastStateChangedAt: store.lastStateChangedAt,
      lastFailureMessage: store.lastFailureMessage,
      lastUploadedSignature: store.lastUploadedSignature,
    );
  }

  static bool _isReachabilityLost(
    DeviceTelemetryStore store,
    DeviceTelemetryThresholds thresholds,
  ) {
    return store.reachabilityLost ||
        store.consecutiveUploadFailures >=
            thresholds.reachabilityFailureThreshold;
  }
}

Map<String, T> _withoutNullValues<T>(Map<String, T?> values) {
  final filtered = <String, T>{};
  values.forEach((key, value) {
    if (value != null) {
      filtered[key] = value;
    }
  });
  return filtered;
}
