import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  // تهيئة الإشعارات للأندرويد فقط
  static Future<void> initialize() async {
    // تهيئة التوقيت المحلي
    tz.initializeTimeZones();

    // إعدادات الأندرويد فقط
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // الإعدادات العامة للأندرويد
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    // تهيئة الإشعارات
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTap,
    );

    // طلب الصلاحيات
    await requestPermissions();
  }

  // طلب صلاحيات الإشعارات للأندرويد
  static Future<void> requestPermissions() async {
    // للأندرويد 13+
    await Permission.notification.request();
  }

  // التعامل مع النقر على الإشعار
  static void onNotificationTap(NotificationResponse notificationResponse) {
    print('تم النقر على الإشعار: ${notificationResponse.payload}');
    // هنا يمكنك إضافة المنطق الخاص بك
  }

  // إرسال إشعار فوري
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_channel',
        'الإشعارات الفورية',
        channelDescription: 'إشعارات فورية للتطبيق',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // جدولة إشعار لوقت محدد
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // تحويل الوقت إلى التوقيت المحلي
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'scheduled_channel',
        'الإشعارات المجدولة',
        channelDescription: 'إشعارات مجدولة للتطبيق',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // جدولة إشعار يومي
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel',
        'الإشعارات اليومية',
        channelDescription: 'إشعارات يومية للتطبيق',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // حساب الوقت التالي للإشعار اليومي
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // إلغاء إشعار محدد
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // إلغاء جميع الإشعارات
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // الحصول على الإشعارات المعلقة
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}

// مثال على الاستخدام
class NotificationExample extends StatefulWidget {
  @override
  _NotificationExampleState createState() => _NotificationExampleState();
}

class _NotificationExampleState extends State<NotificationExample> {
  @override
  void initState() {
    super.initState();
    // تهيئة الإشعارات عند بدء التطبيق
    NotificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مثال على الإشعارات المحلية'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                NotificationService.showInstantNotification(
                  id: 1,
                  title: 'إشعار فوري',
                  body: 'هذا إشعار فوري للاختبار',
                  payload: 'instant_notification',
                );
              },
              child: Text('إرسال إشعار فوري'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                NotificationService.scheduleNotification(
                  id: 2,
                  title: 'إشعار مجدول',
                  body: 'هذا إشعار مجدول بعد 5 ثواني',
                  scheduledTime: DateTime.now().add(Duration(seconds: 5)),
                  payload: 'scheduled_notification',
                );
              },
              child: Text('جدولة إشعار بعد 5 ثواني'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                NotificationService.scheduleDailyNotification(
                  id: 3,
                  title: 'إشعار يومي',
                  body: 'هذا إشعار يومي في الساعة 9:00 صباحاً',
                  hour: 9,
                  minute: 0,
                  payload: 'daily_notification',
                );
              },
              child: Text('جدولة إشعار يومي'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                NotificationService.cancelAllNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم إلغاء جميع الإشعارات')),
                );
              },
              child: Text('إلغاء جميع الإشعارات'),
            ),
          ],
        ),
      ),
    );
  }
}