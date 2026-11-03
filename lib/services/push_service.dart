import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final token = ValueNotifier<String?>(null);

  Future<void> init() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.instance.onTokenRefresh.listen((t) => token.value = t);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      NotificationService.instance.showNow(
        title: notification.title ?? 'Akthlon',
        body: notification.body ?? '',
      );
    });

    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      token.value = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('No se pudo obtener el token FCM: $e');
    }
  }
}
