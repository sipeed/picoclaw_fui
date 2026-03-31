import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'device_feedback_models.dart';
import 'picoclaw_channel.dart';

class FirebaseDeviceReporter {
  static const _prefsInstallIdKey = 'firebase_install_id';
  static const _prefsLastSystemVersionKey = 'firebase_last_system_version';
  static const _prefsUploadAllowedKey = 'firebase_upload_allowed';
  static const _eventName = 'device_feedback_report';
  static const _parameterInstallId = 'install_id';
  static const _parameterOsVersion = 'os_version';
  static const _parameterAppVersion = 'app_version';

  final Uuid _uuid = const Uuid();
  FirebaseAnalytics? _analytics;

  Future<Map<String, String>> collectSafeDeviceInfo() async {
    final packageInfo = await _readPackageInfo();
    if (Platform.isAndroid) {
      try {
        final info = await PicoClawChannel.getSafeDeviceInfo();
        return {
          'deviceModel': info['deviceModel'] ?? 'unknown',
          'osVersion': info['osVersion'] ?? 'unknown',
          'deviceCategory': info['deviceCategory'] ?? 'Mobile',
          'appVersion': info['appVersion'] ?? packageInfo.version,
        };
      } catch (e) {
        debugPrint('Failed to read Android device info: $e');
      }
    }

    return {
      'deviceModel': Platform.isWindows || Platform.isLinux || Platform.isMacOS
          ? 'desktop'
          : 'unknown',
      'osVersion': Platform.operatingSystemVersion,
      'deviceCategory':
          Platform.isWindows || Platform.isLinux || Platform.isMacOS
          ? 'Desktop'
          : 'Mobile',
      'appVersion': packageInfo.version,
    };
  }

  Future<PackageInfo> _readPackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return PackageInfo(
        appName: 'unknown',
        packageName: 'unknown',
        version: 'unknown',
        buildNumber: 'unknown',
      );
    }
  }

  Future<String> getOrCreateInstallId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsInstallIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = _uuid.v4();
    await prefs.setString(_prefsInstallIdKey, generated);
    return generated;
  }

  Future<bool> isUploadAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsUploadAllowedKey) ?? true;
  }

  Future<bool> hasUploadConsentChoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_prefsUploadAllowedKey);
  }

  Future<void> setUploadAllowed(bool allowed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsUploadAllowedKey, allowed);

    final analytics = await _getAnalytics();
    if (analytics != null) {
      await analytics.setAnalyticsCollectionEnabled(allowed);
    }
  }

  Future<bool> shouldUpload() async {
    if (!await isUploadAllowed()) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final currentInfo = await collectSafeDeviceInfo();
    final currentVersion = currentInfo['osVersion'] ?? 'unknown';
    final lastVersion = prefs.getString(_prefsLastSystemVersionKey);

    return lastVersion == null || lastVersion != currentVersion;
  }

  Future<void> markUploaded() async {
    final prefs = await SharedPreferences.getInstance();
    final currentInfo = await collectSafeDeviceInfo();
    await prefs.setString(
      _prefsLastSystemVersionKey,
      currentInfo['osVersion'] ?? 'unknown',
    );
  }

  Future<FirebaseUploadResult> uploadDeviceReport({
    required String appId,
    required String apiKey,
    required String projectId,
    required String messagingSenderId,
    String? storageBucket,
  }) async {
    debugPrint('[Firebase] Starting device report upload...');
    debugPrint(
      '[Firebase] Input config - appId: ${appId.isEmpty ? "EMPTY" : "set"}, '
      'apiKey: ${apiKey.isEmpty ? "EMPTY" : "set"}, '
      'projectId: ${projectId.isEmpty ? "EMPTY" : "set"}, '
      'messagingSenderId: ${messagingSenderId.isEmpty ? "EMPTY" : "set"}, '
      'storageBucket: ${storageBucket?.isEmpty ?? true ? "EMPTY" : "set"}',
    );

    if (appId.trim().isEmpty) {
      debugPrint('[Firebase] Validation failed: appId is empty');
      return const FirebaseUploadResult(
        success: false,
        message: 'Firebase appId is empty.',
      );
    }
    if (apiKey.trim().isEmpty) {
      debugPrint('[Firebase] Validation failed: apiKey is empty');
      return const FirebaseUploadResult(
        success: false,
        message: 'Firebase apiKey is empty.',
      );
    }
    if (projectId.trim().isEmpty) {
      debugPrint('[Firebase] Validation failed: projectId is empty');
      return const FirebaseUploadResult(
        success: false,
        message: 'Firebase projectId is empty.',
      );
    }
    if (messagingSenderId.trim().isEmpty) {
      debugPrint('[Firebase] Validation failed: messagingSenderId is empty');
      return const FirebaseUploadResult(
        success: false,
        message: 'Firebase messagingSenderId is empty.',
      );
    }

    try {
      debugPrint(
        '[Firebase] Config validation passed, initializing analytics...',
      );
      final analytics = await _getAnalytics(
        appId: appId,
        apiKey: apiKey,
        projectId: projectId,
        messagingSenderId: messagingSenderId,
        storageBucket: storageBucket,
      );
      if (analytics == null) {
        debugPrint('[Firebase] ERROR: Analytics initialization returned null');
        return const FirebaseUploadResult(
          success: false,
          message: 'Firebase Analytics is not supported on this platform.',
        );
      }
      debugPrint('[Firebase] Analytics instance obtained successfully');

      // Ensure analytics collection is enabled based on user consent
      debugPrint('[Firebase] Checking user upload consent...');
      final isAllowed = await isUploadAllowed();
      debugPrint('[Firebase] User consent: isAllowed=$isAllowed');

      await analytics.setAnalyticsCollectionEnabled(isAllowed);
      debugPrint('[Firebase] Analytics collection enabled: $isAllowed');

      if (!isAllowed) {
        debugPrint('[Firebase] Upload cancelled: user disabled collection');
        return const FirebaseUploadResult(
          success: false,
          message: 'Analytics collection is disabled by user.',
        );
      }

      debugPrint('[Firebase] Getting install ID...');
      final installId = await getOrCreateInstallId();
      debugPrint('[Firebase] Install ID: $installId');

      debugPrint('[Firebase] Collecting device info...');
      final info = await collectSafeDeviceInfo();
      debugPrint('[Firebase] Device info collected: $info');

      final now = DateTime.now().toUtc().toIso8601String();

      debugPrint('[Firebase] Preparing to log event: $_eventName');
      debugPrint(
        '[Firebase] Event parameters: installId=$installId, osVersion=${info['osVersion']}, appVersion=${info['appVersion']}',
      );

      // 在发送事件前添加诊断信息
      debugPrint('[Firebase] Attempting to log event to Firebase servers...');
      debugPrint('[Firebase] Event name: $_eventName');
      debugPrint('[Firebase] Timestamp: $now');

      // 尝试设置用户属性以帮助识别
      try {
        await analytics.setUserProperty(name: 'install_id', value: installId);
        debugPrint('[Firebase] User property set successfully');
      } catch (e) {
        debugPrint('[Firebase] WARNING: Failed to set user property: $e');
      }

      await analytics.logEvent(
        name: _eventName,
        parameters: {
          _parameterInstallId: installId,
          _parameterOsVersion: info['osVersion'] ?? 'unknown',
          _parameterAppVersion: info['appVersion'] ?? 'unknown',
        },
      );

      debugPrint('[Firebase] Event logged to local queue successfully');
      debugPrint(
        '[Firebase] NOTE: Events are batched and sent periodically, not immediately',
      );
      debugPrint(
        '[Firebase] To see real-time events, ensure DebugView is enabled:',
      );
      debugPrint(
        '[Firebase]   adb shell setprop debug.firebase.analytics.app com.sipeed.picoclaw',
      );

      await markUploaded();
      debugPrint('[Firebase] Upload marked as completed');

      final result = FirebaseUploadResult(
        success: true,
        message: 'Analytics event synced successfully',
        uploadedAt: now,
        deviceInfo: info,
      );
      debugPrint('[Firebase] Upload completed successfully: $result');
      return result;
    } catch (e, stackTrace) {
      debugPrint('[Firebase] ERROR: Upload failed with exception: $e');
      debugPrint('[Firebase] Stack trace: $stackTrace');
      return FirebaseUploadResult(
        success: false,
        message: 'Analytics upload failed: $e',
      );
    }
  }

  Future<FirebaseAnalytics?> _getAnalytics({
    String? appId,
    String? apiKey,
    String? projectId,
    String? messagingSenderId,
    String? storageBucket,
  }) async {
    debugPrint('[Firebase] _getAnalytics called');
    debugPrint(
      '[Firebase] Platform check - isAndroid: ${Platform.isAndroid}, isIOS: ${Platform.isIOS}',
    );

    if (!(Platform.isAndroid || Platform.isIOS)) {
      debugPrint(
        '[Firebase] ERROR: Firebase Analytics not supported on this platform',
      );
      return null;
    }
    if (_analytics != null) {
      debugPrint('[Firebase] Returning cached analytics instance');
      return _analytics;
    }

    FirebaseApp app;
    debugPrint(
      '[Firebase] Checking existing Firebase apps: ${Firebase.apps.length} apps registered',
    );

    if (Firebase.apps.isNotEmpty) {
      app = Firebase.app();
      debugPrint('[Firebase] Using existing app: ${app.name}');
    } else {
      final resolvedAppId = appId?.trim() ?? '';
      final resolvedApiKey = apiKey?.trim() ?? '';
      final resolvedProjectId = projectId?.trim() ?? '';
      final resolvedMessagingSenderId = messagingSenderId?.trim() ?? '';
      final resolvedStorageBucket = storageBucket?.trim();
      debugPrint(
        '[Firebase] Config check - appId: ${resolvedAppId.isEmpty ? "EMPTY" : "set"}, '
        'apiKey: ${resolvedApiKey.isEmpty ? "EMPTY" : "set"}, '
        'projectId: ${resolvedProjectId.isEmpty ? "EMPTY" : "set"}, '
        'messagingSenderId: ${resolvedMessagingSenderId.isEmpty ? "EMPTY" : "set"}, '
        'storageBucket: ${resolvedStorageBucket?.isEmpty ?? true ? "EMPTY" : "set"}',
      );
      if (resolvedAppId.isEmpty ||
          resolvedApiKey.isEmpty ||
          resolvedProjectId.isEmpty ||
          resolvedMessagingSenderId.isEmpty) {
        debugPrint(
          '[Firebase] ERROR: Initialization skipped - missing configuration',
        );
        return null;
      }
      try {
        debugPrint('[Firebase] Calling Firebase.initializeApp...');
        final options = FirebaseOptions(
          appId: resolvedAppId,
          apiKey: resolvedApiKey,
          projectId: resolvedProjectId,
          messagingSenderId: resolvedMessagingSenderId,
        );
        debugPrint('[Firebase] FirebaseOptions created');
        app = await Firebase.initializeApp(options: options);
        debugPrint(
          '[Firebase] Firebase initialized successfully - app name: ${app.name}',
        );
        debugPrint('[Firebase] Firebase App options after init:');
        debugPrint('[Firebase]   - projectId: ${app.options.projectId}');
        debugPrint(
          '[Firebase]   - storageBucket: ${app.options.storageBucket ?? "not set"}',
        );
      } catch (e, stackTrace) {
        debugPrint('[Firebase] ERROR: Initialization failed: $e');
        debugPrint('[Firebase] Stack trace: $stackTrace');
        return null;
      }
    }

    try {
      debugPrint('[Firebase] Creating FirebaseAnalytics instance...');
      _analytics = FirebaseAnalytics.instanceFor(app: app);
      debugPrint('[Firebase] FirebaseAnalytics instance created successfully');

      // 打印 Firebase App 详细信息
      debugPrint('[Firebase] Firebase App details:');
      debugPrint('[Firebase]   - Name: ${app.name}');
      debugPrint(
        '[Firebase]   - Options.appId: ${app.options.appId.substring(0, app.options.appId.length > 10 ? 10 : app.options.appId.length)}...',
      );
      debugPrint('[Firebase]   - Options.projectId: ${app.options.projectId}');
      debugPrint(
        '[Firebase]   - Options.messagingSenderId: ${app.options.messagingSenderId}',
      );

      // 检查 Analytics 实例状态
      debugPrint('[Firebase] Checking Analytics instance status...');
    } catch (e, stackTrace) {
      debugPrint('[Firebase] ERROR: Failed to create analytics instance: $e');
      debugPrint('[Firebase] Stack trace: $stackTrace');
      return null;
    }

    return _analytics;
  }
}
