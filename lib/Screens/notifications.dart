import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../utils/settings_manager.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidInit);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTap,
    );

    await requestAllPermissions();
    await createNotificationChannels();
  }

  static Future<void> requestAllPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();
      await Permission.ignoreBatteryOptimizations.request();
      await checkPermissionStatus();
    }
  }

  static Future<void> checkPermissionStatus() async {
    final notificationStatus = await Permission.notification.status;
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(
      'permissions_granted',
      notificationStatus.isGranted && alarmStatus.isGranted,
    );
  }

  static Future<void> createNotificationChannels() async {
    if (Platform.isAndroid) {
      const instantChannel = AndroidNotificationChannel(
        'instant_channel',
        'الإشعارات الفورية',
        description: 'إشعارات تظهر فورًا',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      const scheduledChannel = AndroidNotificationChannel(
        'scheduled_channel',
        'الإشعارات المجدولة',
        description: 'إشعارات يتم إرسالها في وقت محدد',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

      const dailyChannel = AndroidNotificationChannel(
        'daily_channel',
        'الإشعارات اليومية',
        description: 'إشعارات يومية في وقت معين',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final plugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (plugin != null) {
        await plugin.createNotificationChannel(instantChannel);
        await plugin.createNotificationChannel(scheduledChannel);
        await plugin.createNotificationChannel(dailyChannel);
      }
    }
  }

  static void onNotificationTap(NotificationResponse notificationResponse) {
    print('Notification Tapped: ${notificationResponse.payload}');
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_channel',
        'الإشعارات الفورية',
        channelDescription: 'إشعارات تظهر فورًا',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        autoCancel: true,
      ),
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      print('Cannot schedule notification in the past');
      return;
    }

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'scheduled_channel',
        'الإشعارات المجدولة',
        channelDescription: 'إشعارات يتم إرسالها في وقت محدد',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        enableLights: true,
        autoCancel: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      ),
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      await saveScheduledNotification(id, title, body, scheduledTime, payload);
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    final tzTime = _nextInstanceOfTime(hour, minute);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel',
        'الإشعارات اليومية',
        channelDescription: 'إشعارات يومية في وقت معين',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        autoCancel: true,
      ),
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('Error scheduling daily notification: $e');
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(Duration(days: 1));
    }

    return scheduled;
  }

  static Future<void> saveScheduledNotification(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
    String? payload,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('scheduled_notifications') ?? [];

    final notificationData = {
      'id': id,
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
      'payload': payload ?? '',
    };

    notifications.add(notificationData.toString());
    await prefs.setStringList('scheduled_notifications', notifications);
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scheduled_notifications');
  }

  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();

    for (var notification in pending) {
      print('   - ID: ${notification.id}, Title: ${notification.title}');
    }

    return pending;
  }

  static Future<void> rescheduleNotificationsFromStorage() async {
    try {
      final settings = await SettingsManager.loadSettings();
      final startDate = settings['startDate'];
      final workDays = settings['workDays'];
      final offDays = settings['offDays'];

      if (startDate != null && workDays != null && offDays != null) {
        await scheduleEndOfOffNotification(
          id: 100,
          startDate: startDate,
          workDays: workDays,
          offDays: offDays,
          title: "استعد",
          body: "بكرة شغل جهز دماغك من دلوقتي",
        );
      }
    } catch (e) {
      print('Error rescheduling notifications: $e');
    }
  }

  static Future<void> scheduleEndOfOffNotification({
    required int id,
    required DateTime startDate,
    required int workDays,
    required int offDays,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    int cycleLength = workDays + offDays;
    int daysSinceStart = now.difference(startDate).inDays;
    int completedCycles = (daysSinceStart / cycleLength).floor();

    DateTime currentCycleStart = startDate.add(
      Duration(days: completedCycles * cycleLength),
    );
    DateTime offStart = currentCycleStart.add(Duration(days: workDays));

    if (offStart.isBefore(now)) {
      offStart = offStart.add(Duration(days: cycleLength));
    }

    final reminders = [
      Duration(hours: 24),
      Duration(hours: 12),
      Duration(hours: 6),
    ];

    final titles = [
      "قربت الإجازة",
      "الإجازة على الأبواب",
      "يلا جهز نفسك خلاص فاضل ساعات",
    ];

    final bodies = [
      "باقي يوم واحد على الإجازة خطط لوقتك صح",
      "باقي 12 ساعة وتبدأ الإجازة",
      "فاضل 6 ساعات ويبدأ أجمل وقت في الأسبوع",
    ];

    for (int i = 0; i < reminders.length; i++) {
      final notifyTime = offStart.subtract(reminders[i]);

      if (notifyTime.isAfter(now)) {
        await scheduleNotification(
          id: id + i,
          title: titles[i],
          body: bodies[i],
          scheduledTime: notifyTime,
          payload: 'pre_off_alert_${i + 1}',
        );
      } else {
        print('Skipping past notification ${i + 1}');
      }
    }
  }

  static Future<void> debugNotifications() async {
    final pending = await getPendingNotifications();
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('scheduled_notifications') ?? [];

    if (Platform.isAndroid) {
      final notificationStatus = await Permission.notification.status;
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    }
  }
}

class NotificationExample extends StatefulWidget {
  @override
  _NotificationExampleState createState() => _NotificationExampleState();
}

class _NotificationExampleState extends State<NotificationExample> {
  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('اختبار الإشعارات')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
                onPressed: () async {
                  await NotificationService.scheduleNotification(
                    id: 999,
                    title: 'اختبار',
                    body: 'هيظهر بعد 10 ثواني',
                    scheduledTime: DateTime.now().add(Duration(seconds: 10)),
                  );
                },
                child: Text('اختبار إشعار بعد 10 ثواني'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
