import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'akthlon_general';
  static const _channelName = 'Notificaciones Akthlon';
  static const _logoAsset = 'img/logo_akthlon.jpeg';

  final _plugin = FlutterLocalNotificationsPlugin();
  String timeZoneName = 'UTC';
  String? _logoPath;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const android = AndroidInitializationSettings('ic_notification');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.high,
          ),
        );
    _logoPath = await _copyLogoToDisk();
  }

  Future<String> _copyLogoToDisk() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/logo_akthlon.jpeg');
    if (!await file.exists()) {
      final data = await rootBundle.load(_logoAsset);
      await file.writeAsBytes(data.buffer.asUint8List());
    }
    return file.path;
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ??
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
    return granted;
  }

  NotificationDetails _details() => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          largeIcon:
              _logoPath == null ? null : FilePathAndroidBitmap(_logoPath!),
        ),
        iOS: const DarwinNotificationDetails(),
      );

  Future<void> showNow({required String title, required String body}) {
    return _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: _details(),
    );
  }

  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> cancelAll() => _plugin.cancelAll();
}
