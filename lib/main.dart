import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'Screens/notifications.dart';
import 'myapp.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // تهيئة خدمة الإشعارات
    await NotificationService.initialize();

    // إعداد قناة التواصل مع النظام
    setupMethodChannel();

    // إعادة جدولة الإشعارات عند فتح التطبيق
    await NotificationService.rescheduleNotificationsFromStorage();

    // فحص حالة الإشعارات (للـ debugging)
    await NotificationService.debugNotifications();

    print('✅ App initialized successfully');
  } catch (e) {
    print('❌ Error initializing app: $e');
  }

  runApp(const MyApp());
}

const platform = MethodChannel("com.example.gnab_v2/notifications");

void setupMethodChannel() {
  platform.setMethodCallHandler((call) async {
    try {
      switch (call.method) {
        case "rescheduleNotifications":
          print('📱 Received reschedule request from native');
          await NotificationService.rescheduleNotificationsFromStorage();
          break;

        case "checkNotificationStatus":
          await NotificationService.debugNotifications();
          break;

        case "cancelAllNotifications":
          await NotificationService.cancelAllNotifications();
          break;

        default:
          print('⚠️ Unknown method: ${call.method}');
      }
    } catch (e) {
      print('❌ Error handling method channel call: $e');
    }
  });
}

// إضافة AppLifecycleListener للتعامل مع دورة حياة التطبيق
class MyAppWithLifecycle extends StatefulWidget {
  final Widget child;

  const MyAppWithLifecycle({Key? key, required this.child}) : super(key: key);

  @override
  _MyAppWithLifecycleState createState() => _MyAppWithLifecycleState();
}

class _MyAppWithLifecycleState extends State<MyAppWithLifecycle>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 App resumed - checking notifications');
        // إعادة جدولة الإشعارات عند العودة للتطبيق
        NotificationService.rescheduleNotificationsFromStorage();
        break;

      case AppLifecycleState.paused:
        print('📱 App paused');
        break;

      case AppLifecycleState.inactive:
        print('📱 App inactive');
        break;

      case AppLifecycleState.detached:
        print('📱 App detached');
        break;

      case AppLifecycleState.hidden:
        print('📱 App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}