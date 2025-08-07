import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingHandler {
  final FlutterLocalNotificationsPlugin notifications;

  FirebaseMessagingHandler(this.notifications);

  Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission();
    
    // For handling notifications when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // For when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    
    // For when app is terminated
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
    
    // Get FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      // Send this token to your server to associate with this device
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _showNotification(
      message.notification?.title ?? 'Alert',
      message.notification?.body ?? 'New alert received',
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    _showNotification(
      message.notification?.title ?? 'Alert',
      message.notification?.body ?? 'New alert received',
    );
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'temperature_alerts',
      'Temperature Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await notifications.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
