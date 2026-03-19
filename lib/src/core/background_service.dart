import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Notification channel/plug-in initialization intentionally omitted
  // since background service plugins may manage notifications differently
  // across platform/API versions. Keep this minimal to avoid unused-symbol
  // analyzer warnings and version-specific API calls.
  // For Android, create a notification channel so the foreground service
  // can post persistent notifications. This is required for newer Android
  // API levels and provides a consistent cross-platform experience.
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'picoclaw_foreground',
        'PicoClaw Service',
        description: 'Keep the PicoClaw server running in the background.',
        importance: Importance.low,
      );

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  } catch (e) {
    // Don't fail service initialization for notification errors; log if possible.
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'picoclaw_foreground',
      initialNotificationTitle: 'PicoClaw UI',
      initialNotificationContent: 'PicoClaw service is running',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Logic to keep Go binary alive in separate thread/isolate if needed
  // For now we just keep the service active
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}
