import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:everbloom/models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _notifications.initialize(initSettings);
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleHabitNotification(Habit habit) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      habit.scheduledTime.hour,
      habit.scheduledTime.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      habit.id.hashCode,
      'Time for ${habit.title}! 🎯',
      'Your ${habit.durationMinutes} min habit streak awaits',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_channel',
          'Habit Reminders',
          channelDescription: 'Notifications for habit reminders',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            const AndroidNotificationAction('complete', 'Complete ✓'),
            const AndroidNotificationAction('skip', 'Skip to Later'),
          ],
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleSkippedTaskReminder(Habit habit) async {
    final now = tz.TZDateTime.now(tz.local);
    final reminderTime = now.add(const Duration(hours: 2));

    await _notifications.zonedSchedule(
      habit.id.hashCode + 1000,
      'Don\'t forget ${habit.title}! ⏰',
      'You skipped it earlier. Complete it today to maintain your streak!',
      reminderTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminder_channel',
          'Skipped Task Reminders',
          channelDescription: 'Reminders for skipped tasks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    await _notifications.cancel(id + 1000);
  }

  Future<void> cancelAll() async => await _notifications.cancelAll();
}
