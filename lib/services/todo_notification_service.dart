import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:spendwise/models/todo_task.dart';

class TodoNotificationService {
  static final TodoNotificationService _instance =
      TodoNotificationService._internal();
  factory TodoNotificationService() => _instance;
  TodoNotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'todo_reminders';
  static const _channelName = 'Rappels Tâches';
  static const _defaultTimeZone = 'Africa/Dakar';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_defaultTimeZone));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Create notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );
    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> scheduleReminder(
    TodoTask task, {
    bool requestPermissions = true,
  }) async {
    if (task.id == null) return;
    if (task.dueDate.isBefore(DateTime.now())) return;
    if (requestPermissions) {
      await _requestReminderPermissions();
    }

    final scheduledDate = tz.TZDateTime(
      tz.local,
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
      task.dueDate.hour,
      task.dueDate.minute,
    );

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const notifDetails = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      _notificationId(task.id!),
      task.title,
      '${task.isDeposit ? "+" : "-"} ${task.amount.toStringAsFixed(0)}',
      scheduledDate,
      notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );
  }

  Future<void> cancelReminder(String todoId) async {
    await _plugin.cancel(_notificationId(todoId));
  }

  Future<void> rescheduleAll(List<TodoTask> todos) async {
    await _plugin.cancelAll();
    for (final todo in todos) {
      if (!todo.isCompleted) {
        await scheduleReminder(todo, requestPermissions: false);
      }
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> _requestReminderPermissions() async {
    await _androidPlugin?.requestNotificationsPermission();
    try {
      await _androidPlugin?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('TodoNotificationService exactAlarms: $e');
    }
  }

  int _notificationId(String id) {
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
