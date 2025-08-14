import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;
import '../utils/settings_manager.dart';
import 'dart:math';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// تهيئة الإشعارات + القنوات + المناطق الزمنية + طلب الصلاحيات
Future<void> initNotifications() async {
// 1) تايم زون
  tzData.initializeTimeZones();

// اختياري: خليه ياخد تايم زون الجهاز
// tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

// 2) إنشاء قناة أندرويد (مطلوب من أندرويد 8 وفوق)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'work_off_channel',
    'Work/Off Notifications',
    description: 'إشعارات التبديل بين العمل والإجازة',
    importance: Importance.max,
  );

  final androidImpl = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await androidImpl?.createNotificationChannel(channel);

// 3) تهيئة البلجن
  const AndroidInitializationSettings initAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initIOS = DarwinInitializationSettings();

  const InitializationSettings initSettings =
  InitializationSettings(android: initAndroid, iOS: initIOS);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
// onDidReceiveNotificationResponse: (resp) { ... } // لو محتاج تتعامل مع الضغط على الإشعار
  );

// 4) طلب الصلاحيات
  await _ensureNotificationPermissions();
}

/// طلب صلاحيات الإشعارات (Android 13+ و iOS)
Future<void> _ensureNotificationPermissions() async {
  try {
    if (Platform.isAndroid) {
// Android 13+ POST_NOTIFICATIONS
      await Permission.notification.request();

// exact alarm ماينفعش طلبها بواجهة موحدة، بس وجود الـ <uses-permission>
// في الـ Manifest + نوع الجدولة بيخلي النظام يسمح بأكبر دقة ممكنة.
// لو حابب توجه المستخدم لإعدادات البطارية:
      await openAppSettings();
    } else if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  } catch (e) {
    if (kDebugMode) {
      print('Permission request error: $e');
    }
  }
}

/// إلغاء كل الإشعارات المجدولة/الظاهرة
Future<void> cancelAllNotifications() async {
  await flutterLocalNotificationsPlugin.cancelAll();
}

/// جدولة إشعارات التبديل قبلها بيوم في الأوقات: 00:00 و12:00 و15:00 و18:00
/// - startDate: تاريخ بداية أول دورة (أول يوم شغل)
/// - workDays: عدد أيام الشغل
/// - offDays: عدد أيام الإجازة
/// - endDate: تاريخ انتهاء الخدمة (اختياري). لو null هنجدد سنة قدّام.
Future<void> scheduleSwitchNotifications({
  required DateTime startDate,
  required int workDays,
  required int offDays,
}) async {
// safety
  if (workDays <= 0 || offDays <= 0) return;

// نلغي أي إشعارات قديمة قبل ما نعيد الجدولة
  await cancelAllNotifications();

  final cycleLength = workDays + offDays;
  final now = DateTime.now();

// تشتغل لمدة سنة قدام
final bound = now.add(const Duration(days: 365));

// هنمشي بالدورات من startDate لحد bound
// كل دورة: [workDays شغل] + [offDays إجازة]
  DateTime cycleStart = startDate;

// نرمي الدورات اللي قبل النهارده
  if (cycleStart.isBefore(now)) {
    final diffDays = now
        .difference(cycleStart)
        .inDays;
    final passedCycles = diffDays ~/ cycleLength;
    cycleStart = cycleStart.add(Duration(days: passedCycles * cycleLength));
  }

  while  (cycleStart.isBefore(bound)) {
    final offStart = cycleStart.add(Duration(days: workDays)); // بداية الإجازة
    final nextWorkStart =
    offStart.add(Duration(days: offDays)); // بداية الشغل للدورة التالية

// 1) قبل الإجازة بيوم (غدًا تبدأ الإجازة)
    await _scheduleDayBeforeWithTimes(
      targetDay: offStart,
      title: 'تبديل قريب ⏰',
      body: 'غدًا تبدأ الإجازة',
      kind: 1,
    );

// 2) قبل الشغل بيوم (غدًا تبدأ الشغل)
    await _scheduleDayBeforeWithTimes(
      targetDay: nextWorkStart,
      title: 'تبديل قريب ⏰',
      body: 'غدًا يبدأ الشغل',
      kind: 2,
    );

// روح للدورة اللي بعدها
    cycleStart = cycleStart.add(Duration(days: cycleLength));
  }
}

/// جدولة 4 إشعارات في اليوم السابق لـ targetDay عند الساعات: 00, 12, 15, 18
/// kind: رقم للتمييز في الـ ID (1: إلى إجازة، 2: إلى شغل)
Future<void> _scheduleDayBeforeWithTimes({
  required DateTime targetDay,
  required String title,
  required String body,
  required int kind,
}) async {
  final notifyDay = targetDay.subtract(const Duration(days: 1));

  if (kind == 1) {
    body = 'غدًا تبدأ الإجازة ⛱ ';
  } else if (kind == 2) {
    body = 'غدًا يبدأ الشغل 💼 ';
  }


  final hours = [0, 12, 15, 18];

  for (final h in hours) {
    final scheduledLocal = DateTime(
      notifyDay.year,
      notifyDay.month,
      notifyDay.day,
      h,
      0,
      0,
    );

    if (scheduledLocal.isAfter(DateTime.now())) {
// استخدام millisecond لضمان الدقة + رقم عشوائي لزيادة الأمان
      final random = Random();
      final uniqueId = DateTime
          .now()
          .millisecond + random.nextInt(1000);

      await _zonedScheduleExact(
        id: uniqueId,
        whenLocal: scheduledLocal,
        title: title,
        body: body,
      );

      if (kDebugMode) {
        print('⏰ Scheduled [$uniqueId] $title - $body @ $scheduledLocal');
      }
    }
  }
}

/// جدولة فعلية باستخدام zonedSchedule
Future<void> _zonedScheduleExact({
  required int id,
  required DateTime whenLocal,
  required String title,
  required String body,
}) async {
  final tzTime = tz.TZDateTime.from(whenLocal, tz.local);

  const AndroidNotificationDetails androidDetails =
  AndroidNotificationDetails(
    'work_off_channel',
    'Work/Off Notifications',
    channelDescription: 'إشعارات التبديل بين العمل والإجازة',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

  const NotificationDetails details =
  NotificationDetails(android: androidDetails, iOS: iosDetails);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    tzTime,
    details,
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
    UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.dateAndTime,
  );
}

/// حمّل الإعدادات من SettingsManager وجَدْوِل على طول
Future<void> scheduleFromSettingsManager() async {
  final settings = await SettingsManager.loadSettings();
  final DateTime startDate = settings['startDate'];
  final int workDays = settings['workDays'];
  final int offDays = settings['offDays'];
  final DateTime? endDate = settings['endDate'];

  await scheduleSwitchNotifications(
    startDate: startDate,
    workDays: workDays,
    offDays: offDays,
  );
}
