import 'package:flutter/material.dart';
import 'package:easy_notify/easy_notify.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../utils/settings_manager.dart';

class NotificationService {
  static Future<void> initialize() async {
    try {
      // Initialize EasyNotify
      await EasyNotify.init();

      // Request permissions
      await requestAllPermissions();

      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  static Future<void> requestAllPermissions() async {
    if (Platform.isAndroid) {
      try {
        await Permission.notification.request();
        await Permission.scheduleExactAlarm.request();
        await Permission.ignoreBatteryOptimizations.request();

        await checkPermissionStatus();
      } catch (e) {
        print('Error requesting permissions: $e');
      }
    }
  }

  static Future<void> checkPermissionStatus() async {
    try {
      final notificationStatus = await Permission.notification.status;
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

      print('Notification permission: ${notificationStatus.name}');
      print('Alarm permission: ${alarmStatus.name}');
      print('Battery optimization: ${batteryStatus.name}');

      final prefs = await SharedPreferences.getInstance();
      prefs.setBool(
        'permissions_granted',
        notificationStatus.isGranted && alarmStatus.isGranted,
      );
    } catch (e) {
      print('Error checking permission status: $e');
    }
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? imagePath,
  }) async {
    try {
      await EasyNotify.showBasicNotification(
        id: id,
        title: title,
        body: body,
        imagePath: imagePath,
      );
      print('Instant notification sent: $title');
    } catch (e) {
      print('Error showing instant notification: $e');
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String? imagePath,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      print('Cannot schedule notification in the past: $scheduledTime');
      return;
    }

    try {
      final duration = scheduledTime.difference(DateTime.now());

      print('Scheduling notification:');
      print('ID: $id');
      print('Title: $title');
      print('Body: $body');
      print('Scheduled for: $scheduledTime');
      print('Duration: ${duration.inHours} hours, ${duration.inMinutes % 60} minutes');

      await EasyNotify.showScheduledNotification(
        id: id,
        title: title,
        body: body,
        duration: duration,
        imagePath: imagePath,
      );

      await saveScheduledNotification(id, title, body, scheduledTime, payload);
      print('Notification scheduled successfully');
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
    try {
      await EasyNotify.showRepeatedNotification(
        id: id,
        title: title,
        body: body,
        interval: RepeatInterval.daily,
      );
      print('Daily notification scheduled: $title');
    } catch (e) {
      print('Error scheduling daily notification: $e');
    }
  }

  static Future<void> saveScheduledNotification(
      int id,
      String title,
      String body,
      DateTime scheduledTime,
      String? payload,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('scheduled_notifications') ?? [];

      final notificationData = {
        'id': id.toString(),
        'title': title,
        'body': body,
        'scheduledTime': scheduledTime.millisecondsSinceEpoch.toString(),
        'payload': payload ?? '',
      };

      notifications.add(notificationData.toString());
      await prefs.setStringList('scheduled_notifications', notifications);
      print('Notification data saved');
    } catch (e) {
      print('Error saving notification data: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await EasyNotify.cancel(id);
      print('Notification $id cancelled');
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await EasyNotify.cancelAll();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('scheduled_notifications');

      print('All notifications cancelled and storage cleared');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
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
        print('Notifications rescheduled from storage');
      } else {
        print('Missing settings data for rescheduling');
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
    try {
      final now = DateTime.now();
      print('Current time: $now');
      print('Start date: $startDate');
      print('Work days: $workDays, Off days: $offDays');

      int cycleLength = workDays + offDays;
      int daysSinceStart = now.difference(startDate).inDays;

      print('Days since start: $daysSinceStart');
      print('Cycle length: $cycleLength');

      // حساب الدورة الحالية
      int currentCycleNumber = (daysSinceStart / cycleLength).floor();
      int dayInCurrentCycle = daysSinceStart % cycleLength;

      print('Current cycle number: $currentCycleNumber');
      print('Day in current cycle: $dayInCurrentCycle');

      // تحديد بداية الدورة الحالية
      DateTime currentCycleStart = startDate.add(Duration(days: currentCycleNumber * cycleLength));

      // تحديد بداية الإجازة في الدورة الحالية
      DateTime currentOffStart = currentCycleStart.add(Duration(days: workDays));

      // إذا كانت بداية الإجازة في الماضي، انتقل للدورة التالية
      DateTime nextOffStart;
      if (currentOffStart.isBefore(now) || currentOffStart.isAtSameMomentAs(now)) {
        nextOffStart = currentOffStart.add(Duration(days: cycleLength));
        print('Current off period has passed, moving to next cycle');
      } else {
        nextOffStart = currentOffStart;
        print('Using current cycle off start');
      }

      print('Next off start: $nextOffStart');

      // جدولة الإشعارات
      final reminders = [
        {'duration': Duration(hours: 24), 'title': 'قربت الإجازة', 'body': 'باقي يوم واحد على الإجازة خطط لوقتك صح'},
        {'duration': Duration(hours: 12), 'title': 'الإجازة على الأبواب', 'body': 'باقي 12 ساعة وتبدأ الإجازة'},
        {'duration': Duration(hours: 6), 'title': 'يلا جهز نفسك', 'body': 'فاضل 6 ساعات ويبدأ أجمل وقت في الأسبوع'},
        {'duration': Duration(hours: 1), 'title': 'ساعة واحدة!', 'body': 'فاضل ساعة واحدة على الإجازة 🎉'},
      ];

      int scheduledCount = 0;
      for (int i = 0; i < reminders.length; i++) {
        final reminder = reminders[i];
        final notifyTime = nextOffStart.subtract(reminder['duration'] as Duration);

        if (notifyTime.isAfter(now)) {
          await scheduleNotification(
            id: id + i,
            title: reminder['title'] as String,
            body: reminder['body'] as String,
            scheduledTime: notifyTime,
            payload: 'pre_off_alert_${i + 1}',
          );
          scheduledCount++;
        } else {
          print('Skipping past notification ${i + 1}: $notifyTime');
        }
      }

      // جدولة إشعار بداية الإجازة
      if (nextOffStart.isAfter(now)) {
        await scheduleNotification(
          id: id + 10,
          title: 'بدأت الإجازة! 🎉',
          body: 'استمتع بوقتك واسترح كويس',
          scheduledTime: nextOffStart,
          payload: 'off_started',
        );
        scheduledCount++;
      }

      // جدولة إشعار نهاية الإجازة (العودة للعمل)
      final backToWorkTime = nextOffStart.add(Duration(days: offDays));
      if (backToWorkTime.isAfter(now)) {
        await scheduleNotification(
          id: id + 20,
          title: 'استعد للعودة',
          body: 'بكرة شغل! جهز دماغك من دلوقتي 💼',
          scheduledTime: backToWorkTime.subtract(Duration(hours: 1)),
          payload: 'back_to_work',
        );
        scheduledCount++;
      }

      print('Successfully scheduled $scheduledCount notifications');

    } catch (e) {
      print('Error in scheduleEndOfOffNotification: $e');
      throw e;
    }
  }

  static Future<void> debugNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('scheduled_notifications') ?? [];

      print('=== Notification Debug Info ===');
      print('Saved notifications: ${saved.length}');

      for (int i = 0; i < saved.length; i++) {
        print('Notification $i: ${saved[i]}');
      }

      if (Platform.isAndroid) {
        final notificationStatus = await Permission.notification.status;
        final alarmStatus = await Permission.scheduleExactAlarm.status;
        final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

        print('Notification permission: ${notificationStatus.name}');
        print('Alarm permission: ${alarmStatus.name}');
        print('Battery optimization: ${batteryStatus.name}');
      }

      // عرض معلومات الإعدادات
      final settings = await SettingsManager.loadSettings();
      print('Current settings:');
      print('Start date: ${settings['startDate']}');
      print('Work days: ${settings['workDays']}');
      print('Off days: ${settings['offDays']}');
      print('End date: ${settings['endDate']}');

      print('=== End Debug Info ===');

    } catch (e) {
      print('Error in debug: $e');
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
      appBar: AppBar(
        title: Text('اختبار الإشعارات'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'اختبار الإشعارات باستخدام EasyNotify',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: () async {
                  await NotificationService.showInstantNotification(
                    id: 1,
                    title: 'إشعار فوري',
                    body: 'هذا إشعار فوري للاختبار 🔔',
                    payload: 'instant_notification',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم إرسال إشعار فوري')),
                  );
                },
                icon: Icon(Icons.notifications),
                label: Text('إرسال إشعار فوري'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              SizedBox(height: 15),

              ElevatedButton.icon(
                onPressed: () async {
                  await NotificationService.scheduleNotification(
                    id: 999,
                    title: 'اختبار مجدول',
                    body: 'هيظهر بعد 10 ثواني ⏰',
                    scheduledTime: DateTime.now().add(Duration(seconds: 10)),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم جدولة الإشعار لبعد 10 ثواني'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                icon: Icon(Icons.schedule),
                label: Text('اختبار إشعار بعد 10 ثواني'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              SizedBox(height: 15),

              ElevatedButton.icon(
                onPressed: () async {
                  await NotificationService.scheduleNotification(
                    id: 888,
                    title: 'اختبار بعد دقيقة',
                    body: 'هيظهر بعد دقيقة واحدة 📅',
                    scheduledTime: DateTime.now().add(Duration(minutes: 1)),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم جدولة الإشعار لبعد دقيقة'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                },
                icon: Icon(Icons.timer),
                label: Text('اختبار إشعار بعد دقيقة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              SizedBox(height: 15),

              ElevatedButton.icon(
                onPressed: () async {
                  await NotificationService.debugNotifications();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تحقق من console للمعلومات التفصيلية'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                icon: Icon(Icons.info),
                label: Text('عرض معلومات الإشعارات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              SizedBox(height: 20),

              Divider(thickness: 2),

              Text(
                'إدارة الإشعارات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 15),

              ElevatedButton.icon(
                onPressed: () async {
                  await NotificationService.requestAllPermissions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم طلب الأذونات'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                },
                icon: Icon(Icons.security),
                label: Text('طلب أذونات الإشعارات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              SizedBox(height: 15),

              ElevatedButton.icon(
                onPressed: () async {
                  await NotificationService.rescheduleNotificationsFromStorage();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم إعادة جدولة إشعارات الإجازة'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                },
                icon: Icon(Icons.refresh),
                label: Text('إعادة جدولة إشعارات الإجازة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              SizedBox(height: 15),

              ElevatedButton.icon(
                onPressed: () async {
                  await NotificationService.cancelAllNotifications();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم إلغاء جميع الإشعارات'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                icon: Icon(Icons.clear_all),
                label: Text('إلغاء جميع الإشعارات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              SizedBox(height: 30),

              Card(
                color: Colors.yellow[50],
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(height: 8),
                      Text(
                        'نصائح للإشعارات:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• تأكد من تفعيل الأذونات\n• تحقق من إعدادات البطارية\n• اختبر الإشعارات قبل الاعتماد عليها',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}