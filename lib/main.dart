import 'package:easy_notify/easy_notify.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'myapp.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyNotify.init();
  await EasyNotifyPermissions.requestAll();

  runApp(const MyApp());
}



