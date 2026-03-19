import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:picoclaw_flutter_ui/src/core/service_manager.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'picoclaw_foreground', 
    'PicoClaw Service',
    description: 'Keep the PicoClaw server running in the background.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // In newer versions of flutter_local_notifications (21+), 
  // we access the platform-specific implementation via specific getters or plugins.
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
       // Using dynamic or broad try-catch as the API has changed significantly in v21
       // or we skip channel creation here as background_service usually handles it
    }
  } catch (_) {}

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
