import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../utils/settings_manager.dart';
import 'myapp.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة التوقيت
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

  // تهيئة الإشعارات
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  // طلب صلاحية الإشعارات (لأندرويد 13+)
  final androidImplementation =
  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await androidImplementation?.requestNotificationsPermission();

  // تهيئة الإشعارات
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // تحميل الإعدادات
  await SettingsManager.loadSettings();

  // تهيئة المنبهات
  await AndroidAlarmManager.initialize();

  runApp(const MyApp());
}
