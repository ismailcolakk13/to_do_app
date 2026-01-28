import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

class HelperUiFunctions {
  static Future<void> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          FlutterLocalNotificationsPlugin()
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
      final bool? exactAlarmGranted = await androidImplementation
          ?.requestExactAlarmsPermission();
      debugPrint('Exact alarm permission: $exactAlarmGranted');
    }
  }

  static String formatDateHeader(String dateKey) {
    DateTime date = DateTime.parse(dateKey);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime todoDate = DateTime(date.year, date.month, date.day);

    if (todoDate == today) {
      return "Bugün";
    } else if (todoDate == today.add(Duration(days: 1))) {
      return "Yarın";
    } else if (todoDate == today.subtract(Duration(days: 1))) {
      return "Dün";
    } else if (todoDate.year == today.year) {
      return DateFormat("d MMMM", "tr_TR").format(date);
    } else {
      return DateFormat("d MMMM yyyy", "tr_TR").format(date);
    }
  }
}
