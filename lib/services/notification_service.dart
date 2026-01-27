import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize notifications (call in main())
  Future<void> init() async {
    // Initialize timezone database
    tz_data.initializeTimeZones();

    if (Platform.isIOS) tz.setLocalLocation(tz.getLocation("Europe/Istanbul"));

    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Must match drawable filename

    // iOS settings (cannot be const due to callback)
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(settings: initializationSettings);

    if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        "daily_channel_id",
        "Daily Notifications",
        channelDescription: "Daily Notification Channel",
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: "default",
      ),
    );
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    return _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
    );
  }

  // // For iOS < 10 (legacy)
  // @pragma('vm:entry-point')
  // static void onDidReceiveLocalNotification(
  //   int id,
  //   String? title,
  //   String? body,
  //   String? payload,
  // ) {
  //   debugPrint('Legacy notification received: $title | $body');
  // }

  // // For iOS >= 10 & Android
  // @pragma('vm:entry-point')
  // static void onDidReceiveNotificationResponse(NotificationResponse response) {
  //   if (response.notificationResponseType == NotificationResponseType.selected) {
  //     debugPrint('Notification tapped! Payload: ${response.payload}');
  //   }
  // }

  // /// Show an immediate notification
  // static Future<void> showNotification({
  //   required int id,
  //   required String title,
  //   required String body,
  //   String? payload,
  // }) async {
  //   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  //     'todo_reminder_channel', // ← consistent, valid ID
  //     'Görev Hatırlatıcısı',
  //     channelDescription: 'Yapılacaklar listesi hatırlatıcıları',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //     ticker: 'Yeni görev!',
  //   );

  //   final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
  //     presentAlert: true,
  //     presentBadge: true,
  //     presentSound: true,
  //   );

  //   final NotificationDetails platformDetails = NotificationDetails(
  //     android: androidDetails,
  //     iOS: iosDetails,
  //   );

  //   await _notificationsPlugin.show(
  //     id,
  //     title,
  //     body,
  //     platformDetails,
  //     payload: payload,
  //   );
  // }

  // /// Schedule a future notification
  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final remainderHour = prefs.getInt("reminder_hour") ?? 2;
    final remainderMinute = prefs.getInt("reminder_minute") ?? 0;
    final DateTime reminderTime = scheduledDate.subtract(
      Duration(hours: remainderHour, minutes: remainderMinute),
    );

    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('Reminder time is in the past, not scheduling');
      return;
    }
    // Convert to timezone-aware datetime
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      reminderTime,
      tz.local,
    );

    debugPrint("scheduled to ${tzScheduledDate.toIso8601String()}");

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: "Son $remainderHour saat $remainderMinute dakika!",
      scheduledDate: tzScheduledDate,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
  }) async {
    await _notificationsPlugin.cancel(id: 999999);

    final now = tz.TZDateTime.now(tz.local);

    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: 999999,
      scheduledDate: scheduledTime,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: "daily_notification",
      title: "Bugün yapacakların var",
      body: "Var yani...:)",
    );
  }

  Future<void> cancelDailyNotification() async {
    await _notificationsPlugin.cancel(id: 999999);
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
