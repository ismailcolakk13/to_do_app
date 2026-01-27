import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/screens/home.dart';
import "package:google_fonts/google_fonts.dart";
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:to_do_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  final prefs = await SharedPreferences.getInstance();
  final dailyEnabled = prefs.getBool('daily_notification_enabled') ?? true;
  if (dailyEnabled) {
    final hour = prefs.getInt('daily_notification_hour') ?? 8;
    final minute = prefs.getInt('daily_notification_minute') ?? 0;
    await NotificationService().scheduleDailyNotification(
      hour: hour,
      minute: minute,
    );
  }
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final List<String> tasks = [];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    return MaterialApp(
      title: "İşgüç",
      theme: ThemeData(fontFamily: "Nunito"),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('tr', 'TR')],
      locale: Locale("tr", "TR"),
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}
